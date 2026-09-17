#!/usr/bin/env python3
# machine_probe.py - recon BEFORE the peptide ML task: what conda envs and ML
# packages does THIS machine actually have?
#
# Runs on the user's machine as a recipe local step (stdlib only - it must run
# under ANY python3, even one without numpy). It never fails the round for a
# missing package: its job is discovery, not assertion. The verdict file it
# writes is what the agent reads to design the real task round.
#
# Cron caveat: cron jobs run with a minimal PATH, so `conda` is often NOT on
# PATH even when miniconda exists. Every lookup below therefore also tries the
# well-known install locations explicitly and uses absolute paths.
#
# Writes (all committed + pushed by the watcher, git add -A):
#   results/status/machine_probe.json  full report (for the agent)
#   results/status/machine_probe.txt   human-readable summary (for the user)
#   results/status/probe_receipt.txt   probe=done envs=N ml_ready=yes|no best=<env|none>
# Exit 0 = the probe ran (even if it found nothing). Non-zero = the probe crashed.
import json
import os
import platform
import shutil
import socket
import subprocess
import sys

STATUS_DIR = os.path.join('results', 'status')
JSON_OUT = os.path.join(STATUS_DIR, 'machine_probe.json')
TXT_OUT = os.path.join(STATUS_DIR, 'machine_probe.txt')
RECEIPT_OUT = os.path.join(STATUS_DIR, 'probe_receipt.txt')

WANT_IMPORTS = ['numpy', 'pandas', 'sklearn', 'scipy', 'torch', 'xgboost', 'lightgbm']
ML_READY_NEED = ['numpy', 'pandas', 'sklearn']  # what the peptide task needs


def run(cmd, timeout=30):
    try:
        proc = subprocess.run(cmd, capture_output=True, timeout=timeout)
        return proc.returncode, (proc.stdout or b'').decode('utf-8', 'replace')
    except FileNotFoundError:
        return 127, ''
    except subprocess.TimeoutExpired:
        return 124, ''


def conda_candidates():
    cands = []
    for exe in ('conda', 'mamba', 'micromamba'):
        hit = shutil.which(exe)
        if hit:
            cands.append(hit)
    if os.environ.get('CONDA_EXE') and os.path.isfile(os.environ['CONDA_EXE']):
        cands.append(os.environ['CONDA_EXE'])
    home = os.path.expanduser('~')
    if os.name == 'nt':
        roots = [os.path.join(home, d) for d in
                 ('miniconda3', 'anaconda3', 'miniforge3', 'mambaforge')]
        roots += [r'C:\\miniconda3', r'C:\\anaconda3', r'C:\\tools\\miniconda3']
        subs = ['condabin\\conda.bat', 'Scripts\\conda.exe', 'condabin\\conda.exe']
    else:
        roots = [os.path.join(home, d) for d in
                 ('miniconda3', 'anaconda3', 'miniforge3', 'mambaforge')]
        roots += ['/opt/conda', '/opt/miniconda3', '/opt/mambaforge']
        subs = ['bin/conda', 'condabin/conda', 'bin/mamba']
    for root in roots:
        for sub in subs:
            full = os.path.join(root, sub)
            if os.path.isfile(full):
                cands.append(full)
    seen, uniq = set(), []
    for cand in cands:
        if cand not in seen:
            seen.add(cand)
            uniq.append(cand)
    return uniq


def find_conda_base(conda_exe):
    code, out = run([conda_exe, 'info', '--base'], timeout=30)
    if code == 0 and out.strip():
        return out.strip().splitlines()[0].strip()
    # derive from the exe path: <base>/bin/conda or <base>/condabin/conda
    exe = os.path.abspath(conda_exe)
    parent = os.path.basename(os.path.dirname(exe))
    if parent in ('bin', 'condabin', 'Scripts'):
        return os.path.dirname(os.path.dirname(exe))
    return os.path.dirname(exe)


def list_envs(conda_exe):
    code, out = run([conda_exe, 'env', 'list', '--json'], timeout=60)
    if code == 0:
        try:
            envs = json.loads(out).get('envs') or []
            return [e for e in envs if os.path.isdir(e)]
        except Exception:
            pass
    code, out = run([conda_exe, 'env', 'list'], timeout=60)
    envs = []
    if code == 0:
        for line in out.splitlines():
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            path = parts[-1]
            if os.path.isdir(path):
                envs.append(path)
    return envs


def env_python(env_dir):
    if os.name == 'nt':
        cand = os.path.join(env_dir, 'python.exe')
    else:
        cand = os.path.join(env_dir, 'bin', 'python')
    return cand if os.path.isfile(cand) else None


def probe_python(py):
    """Version + ML import table for one interpreter. Never raises."""
    info = {'python': None, 'error': None}
    code, out = run([py, '--version'], timeout=15)
    ver = (out.strip().split()[-1] if out.strip() else '')
    if code != 0 or not ver:
        info['error'] = 'no --version (exit %d)' % code
        return info
    info['python'] = ver
    snippet = (
        'import json; out={}; mods=%r\n'
        'for m in mods:\n'
        '  try:\n'
        '    mod=__import__(m); out[m]=str(getattr(mod,"__version__","?"))\n'
        '  except Exception as e:\n'
        '    out[m]=None\n'
        'print(json.dumps(out))\n' % (WANT_IMPORTS,)
    )
    code, out = run([py, '-c', snippet], timeout=60)
    if code != 0:
        info['error'] = 'import probe failed (exit %d)' % code
        return info
    try:
        info.update(json.loads(out.strip().splitlines()[-1]))
    except Exception as exc:
        info['error'] = 'unparsable probe output: %s' % exc
    return info


def main():
    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
    os.chdir(repo)
    os.makedirs(STATUS_DIR, exist_ok=True)

    report = {
        'schema': 'machine-probe.v1',
        'host': platform.node(),
        'platform': sys.platform,
        'runner_python': sys.executable,
        'conda_exe': None,
        'conda_base': None,
        'envs': [],
        'pypi_reachable': None,
        'cpu_count': os.cpu_count(),
        'disk_free_gb': None,
    }
    try:
        du = shutil.disk_usage(os.path.dirname(repo))
        report['disk_free_gb'] = round(du.free / 1e9, 1)
    except Exception:
        pass
    try:
        sock = socket.create_connection(('pypi.org', 443), timeout=5)
        sock.close()
        report['pypi_reachable'] = True
    except Exception:
        report['pypi_reachable'] = False

    cands = conda_candidates()
    if cands:
        report['conda_exe'] = cands[0]
        try:
            report['conda_base'] = find_conda_base(cands[0])
        except Exception:
            pass
        try:
            env_dirs = list_envs(cands[0])
        except Exception:
            env_dirs = []
        if report['conda_base'] and os.path.isdir(report['conda_base']):
            if report['conda_base'] not in env_dirs:
                env_dirs = [report['conda_base']] + env_dirs
        for env_dir in env_dirs:
            py = env_python(env_dir)
            entry = {'name': os.path.basename(env_dir.rstrip(os.sep))
                     if env_dir != report['conda_base'] else 'base',
                     'prefix': env_dir, 'python_exe': py}
            entry.update(probe_python(py) if py else
                         {'python': None, 'error': 'no python in prefix'})
            report['envs'].append(entry)

    # the interpreter running this probe is always usable for *something*
    report['runner'] = probe_python(sys.executable)

    best, ml_ready = 'none', False
    for entry in report['envs']:
        if all(entry.get(m) for m in ML_READY_NEED):
            best, ml_ready = entry['name'], True
            break

    with open(JSON_OUT, 'w', encoding='utf-8') as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
        fh.write('\n')
    # per-OS copy: this laptop has TWO loops (WSL + Windows) on ONE branch, and
    # machine_probe.json is latest-wins - without this the Windows round would
    # bury the WSL report (round 39 Ubuntu data survived only via git history).
    tag = {'win32': 'windows', 'cygwin': 'windows', 'darwin': 'macos'}.get(
        sys.platform, 'linux')
    per_os_json = os.path.join(STATUS_DIR, 'machine_probe_%s.json' % tag)
    with open(per_os_json, 'w', encoding='utf-8') as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
        fh.write('\n')

    lines = ['machine probe on %s (%s)' % (report['host'], sys.platform),
             'conda: %s' % (report['conda_exe'] or 'NOT FOUND'),
             'base : %s' % (report['conda_base'] or '-'),
             'envs : %d, pypi: %s, cpu: %s, disk free: %s GB'
             % (len(report['envs']), report['pypi_reachable'],
                report['cpu_count'], report['disk_free_gb'])]
    for entry in report['envs']:
        mods = ' '.join('%s=%s' % (m, entry.get(m) or '-')
                        for m in WANT_IMPORTS)
        lines.append('  - %s (py %s): %s%s'
                     % (entry['name'], entry.get('python') or '?', mods,
                        '  BEST' if entry['name'] == best else ''))
    lines.append('ml_ready=%s best=%s  (needs: %s)'
                 % ('yes' if ml_ready else 'no', best,
                    ','.join(ML_READY_NEED)))
    with open(TXT_OUT, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines) + '\n')

    with open(RECEIPT_OUT, 'w', encoding='utf-8') as fh:
        fh.write('probe=done envs=%d ml_ready=%s best=%s\n'
                 % (len(report['envs']), 'yes' if ml_ready else 'no', best))

    print('\n'.join(lines))
    print('wrote %s, %s, %s' % (JSON_OUT, TXT_OUT, RECEIPT_OUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
