#!/usr/bin/env python3
# run_peptide_ml.py - peptide-ML interpreter discovery WITHOUT bash, so the
# Windows recipe step can call [{python}, code/run_peptide_ml.py] through the
# plain local_loop.py placeholder (Git-bash exists on the machine but is not
# on PATH, so {bash} cannot be trusted there). Twin of run_peptide_ml.sh:
# same order, same rules, stdlib only.
#
#   1. candidates from results/status/machine_probe.json (probe order),
#   2. fresh scan of conda roots, BOTH layouts (bin/python and python.exe),
#   3. PATH (python3, python).
# First candidate that imports numpy+pandas+sklearn runs code/peptide_ml.py.
# Exit 1 with an honest message when nothing qualifies (missing sklearn must
# FAIL the round, never silently pass).
import glob as globmod
import json
import os
import shutil
import subprocess
import sys

NEED_TEST = 'import numpy, pandas, sklearn; print("ml-ok")'


def candidates(repo):
    cands = []

    def add(p):
        if p and os.path.isfile(p) and p not in cands:
            cands.append(p)

    try:
        path = os.path.join(repo, 'results', 'status', 'machine_probe.json')
        with open(path, encoding='utf-8') as fh:
            data = json.load(fh)
        for env in data.get('envs') or []:
            add(env.get('python_exe') or '')
    except Exception:
        pass
    home = os.path.expanduser('~')
    roots = [os.path.join(home, d) for d in
             ('miniconda3', 'anaconda3', 'miniforge3', 'mambaforge')]
    roots += ['/opt/conda', '/opt/miniconda3', '/usr/local/miniconda3',
              'C:\\miniconda3', 'C:\\anaconda3', 'C:\\tools\\miniconda3']
    layouts = ('bin/python', 'bin/python3', 'python.exe',
               os.path.join('envs', '*', 'bin', 'python'),
               os.path.join('envs', '*', 'python.exe'))
    for root in roots:
        if not os.path.isdir(root):
            continue
        for pat in layouts:
            for hit in sorted(globmod.glob(os.path.join(root, pat))):
                add(hit)
    for cmd in ('python3', 'python'):
        add(shutil.which(cmd) or '')
    return cands


def has_ml(py):
    try:
        proc = subprocess.run([py, '-c', NEED_TEST],
                              capture_output=True, timeout=60)
        return proc.returncode == 0 and b'ml-ok' in (proc.stdout or b'')
    except Exception:
        return False


def main(argv):
    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
    if len(argv) == 3 and argv[1] == '--check':
        ok = has_ml(argv[2])
        print('ml-ok' if ok else 'ml-missing')
        return 0 if ok else 1
    if len(argv) != 1:
        print('usage: run_peptide_ml.py [--check <python>]')
        return 1
    chosen = ''
    seen = 0
    for py in candidates(repo):
        seen += 1
        if has_ml(py):
            chosen = py
            break
        print('   .. %s has no numpy/pandas/sklearn - skipped' % py)
    if not chosen:
        print('[FAIL] no python on this machine imports numpy+pandas+sklearn '
              '(%d candidate(s) tried).' % seen)
        print('       install them into any conda env (conda install -c conda-forge '
              'scikit-learn pandas) and re-request the round.')
        return 1
    print('== peptide ML interpreter: %s' % chosen)
    sys.stdout.flush()
    proc = subprocess.run([chosen, os.path.join(repo, 'code', 'peptide_ml.py')],
                          cwd=repo)
    return proc.returncode


if __name__ == '__main__':
    sys.exit(main(sys.argv))
