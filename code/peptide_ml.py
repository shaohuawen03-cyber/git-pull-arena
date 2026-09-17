#!/usr/bin/env python3
# peptide_ml.py - umami-peptide ML prediction task. Runs on the USER'S machine
# with the USER'S conda env (picked by code/run_peptide_ml.sh), NOT in the sandbox.
#
#   SYNTHETIC DEMO DATA - functional test only, not science.
#   The 400 training peptides below are generated from a seeded RNG with a KNOWN
#   rule (short + Glu/Asp-rich => umami, which mimics real umami chemistry).
#   The point of this task is to prove the loop can run a real ML job on the
#   machine (features -> train/test split -> RandomForest -> metrics), not to
#   discover biology. Swap DEMO_N/SEED or replace build_dataset() with a real
#   CSV reader when real data arrives; the pipeline stays the same.
#
# Pipeline: amino-acid composition (20) + length + net charge + mean Kyte-Doolittle
# hydrophobicity + (E+D) fraction  ->  stratified 300/100 split  ->  RandomForest
# (200 trees)  ->  accuracy/precision/recall/f1 + predictions CSV.
#
# Honest exit code: the script asserts its own sanity (accuracy >= 0.80,
# 100 test rows written). If the ML did not really work, it exits 1 and the
# round fails instead of faking a pass.
#
# Writes (committed + pushed by the watcher):
#   results/peptide_ml/predictions.csv   sequence,length,true_label,pred_label,proba_umami
#   results/peptide_ml/metrics.json      accuracy/precision/recall/f1/confusion + env info
#   results/peptide_ml/run_report.txt    human-readable summary
#   results/peptide_ml/peptide_receipt.txt  predictions=written model=rf_aac ...
# Usage: <conda-env-python> code/peptide_ml.py   (argv[0]-relative repo root)
import csv
import datetime
import json
import os
import platform
import random
import sys
import time

DEMO_N = 400
DEMO_SEED = 7
TEST_N = 100
MIN_ACCURACY = 0.80
OUT_DIR = os.path.join('results', 'peptide_ml')

AA = list('ACDEFGHIKLMNPQRSTVWY')
KD = {'I': 4.5, 'V': 4.2, 'L': 3.8, 'F': 2.8, 'C': 2.5, 'M': 1.9, 'A': 1.8,
      'G': -0.4, 'T': -0.7, 'S': -0.8, 'W': -0.9, 'Y': -1.3, 'P': -1.6,
      'H': -3.2, 'E': -3.5, 'Q': -3.5, 'D': -3.5, 'N': -3.5, 'K': -3.9, 'R': -4.5}
CHARGE = {'K': 1.0, 'R': 1.0, 'H': 0.5, 'D': -1.0, 'E': -1.0}


def build_dataset(n, seed):
    """SYNTHETIC DEMO DATA (see header): deterministic, known rule."""
    rng = random.Random(seed)
    rows = []
    for _ in range(n):
        ln = rng.randint(2, 12)
        seq = ''.join(rng.choice(AA) for _ in range(ln))
        ed = sum(1 for a in seq if a in ('E', 'D')) / ln
        hyd = sum(1 for a in seq if a in ('I', 'V', 'L', 'F', 'C', 'M')) / ln
        label = 1 if (ed >= 0.40 and ln <= 8) or (ed - 0.5 * hyd >= 0.45) else 0
        if rng.random() < 0.05:
            label = 1 - label
        rows.append((seq, label))
    return rows


def featurize(seq):
    ln = len(seq)
    aac = [seq.count(a) / ln for a in AA]
    net = sum(CHARGE.get(a, 0.0) for a in seq)
    kd = sum(KD[a] for a in seq) / ln
    ed = sum(1 for a in seq if a in ('E', 'D')) / ln
    return aac + [float(ln), net, kd, ed]


def main():
    t0 = time.time()
    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
    os.chdir(repo)
    os.makedirs(OUT_DIR, exist_ok=True)

    import numpy  # noqa: E402  (ML env only - the wrapper guarantees it)
    from sklearn.ensemble import RandomForestClassifier  # noqa: E402
    from sklearn.metrics import confusion_matrix  # noqa: E402
    from sklearn.model_selection import train_test_split  # noqa: E402
    import sklearn  # noqa: E402
    import pandas  # noqa: E402

    data = build_dataset(DEMO_N, DEMO_SEED)
    X = numpy.array([featurize(s) for s, _ in data])
    y = numpy.array([lab for _, lab in data])
    seqs = [s for s, _ in data]
    Xtr, Xte, ytr, yte, seq_tr, seq_te = train_test_split(
        X, y, seqs, test_size=TEST_N, random_state=DEMO_SEED, stratify=y)
    clf = RandomForestClassifier(n_estimators=200, random_state=DEMO_SEED,
                                 n_jobs=-1)
    clf.fit(Xtr, ytr)
    pred = clf.predict(Xte)
    proba = clf.predict_proba(Xte)[:, 1]
    acc = float((pred == yte).mean())
    tp = int(((pred == 1) & (yte == 1)).sum())
    fp = int(((pred == 1) & (yte == 0)).sum())
    fn = int(((pred == 0) & (yte == 1)).sum())
    prec = tp / (tp + fp) if (tp + fp) else 0.0
    rec = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * prec * rec / (prec + rec) if (prec + rec) else 0.0
    cm = confusion_matrix(yte, pred).tolist()

    pred_path = os.path.join(OUT_DIR, 'predictions.csv')
    with open(pred_path, 'w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh)
        w.writerow(['sequence', 'length', 'true_label', 'pred_label', 'proba_umami'])
        for s, t, p, pr in zip(seq_te, yte, pred, proba):
            w.writerow([s, len(s), int(t), int(p), '%.4f' % pr])

    metrics = {
        'schema': 'peptide-ml.metrics.v1',
        'demo_data': True,
        'demo_note': 'SYNTHETIC DEMO DATA - functional test only, not scientific',
        'model': 'rf_aac',
        'model_detail': 'RandomForest(n_estimators=200) on AAC(20)+len+charge+KD+EDfrac',
        'n_total': DEMO_N, 'n_train': DEMO_N - TEST_N, 'n_test': TEST_N,
        'accuracy': round(acc, 4), 'precision': round(prec, 4),
        'recall': round(rec, 4), 'f1': round(f1, 4),
        'confusion': {'tn': cm[0][0], 'fp': cm[0][1], 'fn': cm[1][0], 'tp': cm[1][1]},
        'host': platform.node(), 'python': sys.executable,
        'python_version': '%d.%d.%d' % sys.version_info[:3],
        'numpy': numpy.__version__, 'pandas': pandas.__version__,
        'sklearn': sklearn.__version__,
        'elapsed_s': round(time.time() - t0, 1),
        'at': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    }
    with open(os.path.join(OUT_DIR, 'metrics.json'), 'w', encoding='utf-8') as fh:
        json.dump(metrics, fh, ensure_ascii=False, indent=2)
        fh.write('\n')

    report = [
        'peptide ML prediction on %s (%s) (SYNTHETIC DEMO DATA - functional test)'
        % (platform.node(), sys.platform),
        'env python : %s (py %s, numpy %s, pandas %s, sklearn %s)'
        % (sys.executable, metrics['python_version'], metrics['numpy'],
           metrics['pandas'], metrics['sklearn']),
        'model      : %s' % metrics['model_detail'],
        'split      : %d train / %d test (stratified, seed %d)'
        % (metrics['n_train'], TEST_N, DEMO_SEED),
        'accuracy   : %.4f   precision: %.4f   recall: %.4f   f1: %.4f'
        % (acc, prec, rec, f1),
        'confusion  : TN=%d FP=%d FN=%d TP=%d' % (cm[0][0], cm[0][1], cm[1][0], cm[1][1]),
        'outputs    : %s (100 rows), metrics.json, run_report.txt' % pred_path,
        'elapsed    : %.1fs' % metrics['elapsed_s'],
    ]
    with open(os.path.join(OUT_DIR, 'run_report.txt'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(report) + '\n')
    print('\n'.join(report))

    env_name = os.path.basename(os.path.dirname(os.path.dirname(sys.executable)))
    with open(os.path.join(OUT_DIR, 'peptide_receipt.txt'), 'w', encoding='utf-8') as fh:
        fh.write('predictions=written model=rf_aac accuracy=%.4f n_test=%d env=%s\n'
                 % (acc, TEST_N, env_name))

    # --- honest exit: prove the ML really worked, or fail the round ---
    problems = []
    if acc < MIN_ACCURACY:
        problems.append('accuracy %.4f < %.2f' % (acc, MIN_ACCURACY))
    with open(pred_path, encoding='utf-8') as fh:
        rows = sum(1 for _ in fh) - 1
    if rows != TEST_N:
        problems.append('predictions.csv has %d rows, want %d' % (rows, TEST_N))
    if problems:
        print('SELF-CHECK FAILED: ' + '; '.join(problems))
        return 1
    print('SELF-CHECK OK: accuracy %.4f >= %.2f, %d prediction rows'
          % (acc, MIN_ACCURACY, TEST_N))
    return 0


if __name__ == '__main__':
    sys.exit(main())
