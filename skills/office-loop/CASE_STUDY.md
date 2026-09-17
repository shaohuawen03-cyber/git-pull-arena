# 成功案例：从"打通本机"到"本机自己出稿并判定"

**对象**：`mqgg5630-cyber/git-pull-arena`，分支 `arena/01a0aa00-git-pull-arena`
**用户机器**：`LAPTOP-R77M5D6M`（Windows 11，`[spyder]` conda base，PowerShell，仓库父目录 `E:\0github\git-sync`）
**结果**：round 20–32 全部在真机判定；round 31/32 `passed`，验收标准 97/97，
成品 PPT 由本机 venv 生成 + 真 PowerPoint 开档确认。

## 1. 两轮对话（原样可复制）

**第一轮 —— 装技能 + 打通本机**

```
安装 <你的会话链接> 的skills，与本机 [spyder](base) PS E:\0github\git-sync 打通
```

装的是 **git-sync**（`skills/git-sync/`）：交出会打印一个一次性"粘贴块"，
用户在自己的 PowerShell 里执行 → 机器上注册定时值守任务（`git-sync-watch-<folder>`）、
克隆仓库、之后每轮自动 pull / 检查 / push。

**第二轮 —— 自循环**

```
先清理掉其他任务并开始自循环：生成 docx 和 pptx，推到本会话分支，本机检查后把状态 push 回来，一直循环到你觉得没问题为止。
```

从这里开始装 **本技能（office-loop）**：docx/pptx 的生成 + 真机 3a–3h/4a–4c 判定。

**后续轮（本次实际又追加的）**

```
你能直接装进我的本地吗，你写代码自循环验证装成功没有，自循环验证生成好ppt了没有
E:\0github\git-sync\ppt-master\out\DECK_local_20260916.pptx
这个不是之前就有的，那你再生成一份，不要覆盖
自循环任务，同时主题换位机器学习筛选鲜味肽，用我电脑的安装好的venv环境生成
```

## 2. 这条链路长什么样

```
Arena 会话（沙箱）                  用户 Windows 机器
├─ 写页源 / 生成器                  ├─ 定时值守任务（每 ~2 分钟 poll）
├─ 沙箱自检：                        │   ├─ git pull
│   deck_layout_selftest.py          │   ├─ code/local_check.ps1
│   （机器 round-28 状态 + 极端值）   │   │   3a–3h 交付物 + 真 Word/PowerPoint
├─ git push 会话分支     ──────────► │   │   4a    pptmaster_local.ps1
│                                    │   │         （克隆 ppt-master → venv → pip
│                                    │   │          → 写页 → checker → svg_to_pptx
│                                    │   │          → 拆包复检 → 真 PowerPoint 开档）
└─ 读 check_r<round>_*.txt  ◄────────┤   └─ git push（回执 + 日志 + 成品 + 质检报告 + 页源）
   不合格就改，合格就 accept          │
```

沙箱里**没有** PowerPoint、没有 Word、也没有 ppt-master 的全部依赖 ——
"装成功没有 / 生成好 ppt 没有"这两个问题，答案只可能来自机器 push 回来的那几个文件。

## 3. 真机证据（每次都能照着核）

| 证据 | 路径 | 案例里的值 |
|---|---|---|
| 本轮日志 | `results/status/check_r32_20260916-205603.txt` | `check round 32 … passed (exit 0)`，elapsed 55s |
| 回执（由机器写、值守推回） | `results/status/pptmaster_local.txt` | `pptmaster-ok environment=windows host=LAPTOP-R77M5D6M` / `deck_slides=12 checker_blocking=0 markers=ok powerpoint=yes` |
| 质检报告 | `results/umami/pptmaster_local_quality.json` | `total=12 passed=12 warnings=0 errors=0`，blocking 0 |
| 成品 pptx（机器产） | `results/umami/DECK_umami_01a0aa00_v1.pptx` | 47 390 B / 12 slides / 40 parts / 标记词全中 |
| 机器上那 12 页原文 | `results/umami/svg/*.svg` | 与 `ppt-master\projects\umami-01a0aa00_20260916\svg_output\` 同源 |
| 不覆盖旧成品 | round 32 日志 `out before/after` | `DECK_local_20260916.pptx 47224 B 20:43` 前后完全一致，新文件 20:56 |

## 4. 踩过的坑（技能已经把修法带上了）

| 轮次 | 症状 | 根因 | 现在的修法 |
|---|---|---|---|
| 25 | 4a 起不来，`%1 is not a valid Win32 application` | `Start-Process powershell` 命中了 Store 的 app-execution alias | 解析出 `C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe` 并用它 |
| 26–28 | `[FAIL] no python 3.10+ found; tried 47 candidate(s)`，明明有 `E:\spider\python.exe 3.11.9` | PowerShell 5.1 把 `-c "import sys; …"` 引号参数交给原生 exe 时被打散，**任何候选都过不了探测** | 改成 `--version` 优先 + 探针写成**文件**（放在 ASCII 路径里，`%TEMP%` 的用户名是中文会再挂一次） |
| 28 | checker `blocking=2` 但看不到哪一页；进程还崩了 | ① `08_numbers.svg` 的柱子按固定斜率长，机器自己的数据让它长进 KPI 行（沙箱里日志多一轮、数据不同，复现不出来）② GBK 控制台打印 checker 提示里的 `©` → `UnicodeEncodeError`，**整个失败清单一起丢了** | ① 柱子按最慢一轮等比缩放 + 封顶；生成器写页后立刻自检 XML 与模块框重叠；`deck_layout_selftest.py` 用"round-28 机器状态"回归 ② `log()` 永不抛异常，并把 checker 报告/页源/日志回存仓库 |
| 29 | 全部通过却被判 `failed (exit )` | `Start-Process -PassThru` + `-RedirectStandardOutput` 返回的对象 `ExitCode` 是 `$null` | 改用 .NET `Process` 启动子进程，异步抽干两条管道，读 `ExitCode`；读不到就 WARN，让 4b/4c 以回执判定 |
| 30 | 机器写的 `environment=windows` 回执被沙箱版本覆盖 | `agent-check.sh --accept` 在沙箱 `git add -A`，把工作区里**旧的** `results/**` 一起提交了 | accept 前先 `git checkout <origin> -- results`：`results/` 归机器所有，沙箱只提交握手文件 |
| 32 | 新 deck 差点和旧的撞名/覆盖 | 成品名写死 `DECK_local_<date>.pptx`、项目目录共用 | deck 主题抽到 `code/pptmaster_deck.json`；新 deck 用自己的项目目录与成品名；日志打印 `out before/after` 作为"没覆盖"的证据 |

## 5. 复现步骤（另一个会话照做）

1. 第 1 轮：装 git-sync，让用户粘贴执行那块脚本，确认值守任务在跑（`git-sync-watch-*`）。
2. 第 2 轮：`git checkout FETCH_HEAD -- skills/office-loop` → `bash skills/office-loop/agent-install.sh`
   → `bash code/check_all.sh` → commit/push。
3. 开一轮自循环（`agent-handsfree.sh --sync "…" --request "…"`），等机器 verdict。
4. 读 `results/status/check_r<N>_*.txt`：4a/4b/4c 全 OK 且验收标准过 → 收尾 `--accept`。
5. 之后每轮只做第 3–4 步：改页源 → push → 真机判定 → 收尾。

## 5b. 装好之后新加的门禁（round 33 之后）

| 门禁 | 抓什么 | 为什么加 |
|---|---|---|
| `skills/office-loop/tools/check_payload.py` | 技能自带 payload 与仓库 `code/` 不再逐字节一致 | 技能装出去的会是旧循环 |
| `code/check_criteria_needles.py` | `success_criteria.json` 里写了**文件里并不存在**的字符串 | round 33 真机 4a/4b/4c 全绿，却因为 `'round 28'`（文件里是 `round-28`）整轮 verdict=failed；这个门禁一秒内就能在沙箱里抓到 |
| `code/deck_layout_selftest.py` | 换数据后 12 页出现模块框重叠 / XML 不良构 | round 28 唯一一次真机翻车 |
| installer 的结构自检 | 插入 `local_check.ps1` 后花括号/圆括号不平衡 | PowerShell 是先整文件解析再执行，一处不平衡会让之后每一轮静默死掉 |

## 6. 优化清单（本次实现之后仍然值得做的）

* 机器上多套 deck 并行：现在 `pptmaster_local.ps1` 每轮只跑 `code/pptmaster_deck.json` 指的那一套；
  想要"一次推送出多套 deck"，把配置改成列表即可（pipeline 已经是配置驱动的）。
* 4c（真 PowerPoint 开档）目前只验证能打开且页数对；可以加"读回每页标题与 manifest 比对"。
* 3h/4c 在没装 Office 的机器上会降级为 SKIP —— 若目标机器常年没 Office，建议把
  `pptx_delivery_check` 的权重提高（已经是 errors=0 硬要求）。
* 交付物 docx 的生成器 `code/make_bridge_report.py` 是案例内容定制的；
  新会话应照它的结构写自己的内容，**不要**直接复制里面的文字。

## 7. 第二季：01a0ad15 肽探针 → 肽 ML（rounds 39–47，WSL＋Windows 双链路）

**对象**：`shaohuawen03-cyber/git-pull-arena`，分支 `arena/01a0ad15-git-pull-arena`，
同一台 `LAPTOP-R77M5D6M`。用户要"用本地 conda 环境测一个肽的 ML 预测"。
**结果**：round 39–40（WSL：13 环境，best=`AMPidentifier`，RF acc=0.97）；
round 46–47（Windows 原生：22 环境，best=`NTxPred2`，RF acc=0.97），标准 172/172。

配方链：`peptide-probe`（`code/machine_probe.py`，conda 清单＋ML 达标表，
Windows 版落 `machine_probe_windows.json`）→ `peptide-ml`
（`code/run_peptide_ml.py` 按探针顺序自发现解释器，零安装零硬编码 →
`code/peptide_ml.py` 跑 RandomForest，300/100 分层，断言 acc≥0.80）。
Windows 能跑是因为 `local_check.ps1` §4 加了 runner 分流
（recipe≠office-deck → `local_loop.py local --os windows`），
以及 Windows 步骤禁 bash（`{bash}` 不在 PATH 上）。

三条经验：① 先跑便宜的 probe 轮验证分流＋发现链，再跑干活轮；
② 种子固定的模型跨 OS 输出字节一致——verdict 里没有 `predictions.csv`
是正常的，归属信息看 `metrics.json`（host/解释器/版本/时间戳）；
③ 活目录 `results/peptide_ml/` 给 verdict 覆盖，上个 OS 的版进
`results/peptide_ml_linux/` 归档，WSL/Windows 证据永不互埋。
连接层（双账号共存、找 python 四连败、引号吞噬）的完整故事见
`skills/git-sync/CASE_STUDY.md`。
