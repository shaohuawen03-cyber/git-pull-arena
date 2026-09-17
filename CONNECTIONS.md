# 连接台账 —— Arena 仓库 × 分支 × 本机路径（防忘专用）

> 更新：2026-09-16（**本会话（`arena/01a0aa00`）HQ = 新克隆 `git-pull-arena-01a0aa00` / `arena/01a0aa00-git-pull-arena`，技能 **v2.8.1**（用户链接的 `arena/01a0a9f0` → 技能出处 `arena/01a0a98d`）；**不要覆盖旧目录**。四个禁止覆盖的目录：`git-pull-arena`（旧 v2.6.7）、`git-pull-arena-v268`、`git-pull-arena-s2`、`git-pull-arena-01a0a9f0`。上一个会话 HQ = `git-pull-arena-01a0a9f0` / `arena/01a0a9f0`（v2.8.1，值守可能已被本会话 park，可 `.\\watch.ps1 -Focus` 切回））｜ 技能版本：v2.8.1（开发分支）/ v2.6.7（`main`）｜ 开发分支 `arena/01a0aa00-git-pull-arena`（本会话）｜ 技能出处 `arena/01a0a98d-git-pull-arena` ｜ 退路 `arena/01a0a4f5-git-pull-arena`（v2.6.7）/ `arena/01a09fc1-git-pull-arena`（v2.4.7）｜ 本文件在 `E:\\0github\\git-sync\\git-pull-arena-01a0aa00\\CONNECTIONS.md`
> 忘了的时候：`cd E:\\0github\\git-sync\\git-pull-arena-01a0aa00` 然后 `notepad CONNECTIONS.md`

## 一、当前所有连接

| 用途 | GitHub 仓库 | 工作分支 | 本机路径 | 值守任务名 | 状态 |
|---|---|---|---|---|---|
| **git-sync 技能总部（本会话，WSL）** | [shaohuawen03-cyber/git-pull-arena](https://github.com/shaohuawen03-cyber/git-pull-arena) | **`arena/01a0ad15-git-pull-arena`**（git-sync v2.8.1 + office-loop v2.0.0，出处 `arena/01a0aa00`） | `~/projects/git-pull-arena-01a0ad15`（WSL，新目录，不覆盖已有） | `local-loop-git-pull-arena-01a0ad15`（systemd --user / cron / nohup，`bootstrap-linux.sh` 定） | ⏳ 待用户粘贴交接块：`bootstrap-linux.sh` 注册值守后即打通（与 Windows 侧值守并存，互不干扰） |
| git-sync 上一会话克隆（Windows，冻结当出处） | [mqgg5630-cyber/git-pull-arena](https://github.com/mqgg5630-cyber/git-pull-arena) | `arena/01a0aa00-git-pull-arena`（技能 v2.8.1 + office-loop v2.0.0） | `E:\0github\git-sync\git-pull-arena-01a0aa00` | `git-sync-watch-git-pull-arena-01a0aa00` | ✅ round 20–23 真机 **passed**（round 23 = PPT Master 12 页 DECK）（3a–3h 全 OK，真 Word/真 PowerPoint 开档；2a 免点击推送 PROVEN；handshake 收尾 accepted）；产物 `deliverable/BRIDGE_01a0aa00_v2.8.1.docx/.pptx`、`GUIDE_01a0aa00_v2.8.1.docx/.pptx`、`DELIVERY_01a0aa00_v2.8.1.docx/.pptx`、`DECK_01a0aa00_v2.8.1.pptx`（PPT Master v6.4.0 生成，源 `code/deck_svg/*.svg` + `code/make_deck_pptmaster.py`）+ `OFFICE_HASHES.json`（7 份产物）；日志 `results/status/check_r20_20260916-194327.txt` / `check_r21_20260916-194812.txt`；**不要覆盖旧目录** |
| git-sync 上一会话克隆（v2.8.1，值守可能已被本会话 park） | 同上 | `arena/01a0a9f0-git-pull-arena`（技能 v2.8.1） | `E:\0github\git-sync\git-pull-arena-01a0a9f0` | `git-sync-watch-git-pull-arena-01a0a9f0` | ⏸ 切回：`cd git-pull-arena-01a0a9f0 ; .\watch.ps1 -Focus`（不要覆盖这个目录） |
| git-sync 上一会话克隆（v2.7.4，值守已被本会话 park） | 同上 | `arena/01a0a821-git-pull-arena`（v2.7.4） | `E:\0github\git-sync\git-pull-arena-s2` | `git-sync-watch-git-pull-arena-s2` | ⏸ 切回：`cd git-pull-arena-s2 ; .\watch.ps1 -Focus`（不要覆盖这个目录） |
| git-sync 上一会话克隆（v2.6.8 静态/收尾行已验，冻结） | 同上 | `arena/01a0a7de-git-pull-arena`（v2.6.8；PR #3 已关） | `E:\0github\git-sync\git-pull-arena-v268` | `git-sync-watch-git-pull-arena-v268` | ⏸ **不要覆盖、不要在这里跑本会话的 `.\sync.ps1`** |
| git-sync 旧安装（v2.6.7，冻结当退路） | 同上 | `arena/01a0a4f5-git-pull-arena`（v2.6.7） | `E:\0github\git-sync\git-pull-arena` | `git-sync-watch-git-pull-arena`（2026-09-16 已 `-Pause`） | ⏸ 不要在这里跑 `.\sync.ps1`，会停在 v2.6.7 |
| **图片→可编辑PPT 项目**（fig3 交付物在那边） | [mqgg5630-cyber/image-to-editable-pptx](https://github.com/mqgg5630-cyber/image-to-editable-pptx) | `arena/01a04caf-image-to-editable-pptx` | `E:\0github\git-sync\image-to-editable-pptx` | `git-sync-watch-image-to-editable-pptx` | ✅ 在线（[该会话](https://arena.ai/agent/01a04caf-77d4-7672-92a2-59223763a988)；v2.3.4 @ `14c1f5f`，5/5 验收通过，值守 2 分钟） |
| **中期报告/PPT**（git-sync 技能发源地） | [mqgg5630-cyber/zhongqi](https://github.com/mqgg5630-cyber/zhongqi) | `arena/01a09d79-zhongqi` | `E:\0zhongqi\zhongqi`（你原有的克隆） | 未注册 | ✅ 可拉取（会话已结束；本会话对它只读） |
| **AgentArena**（基准测试工具 + 本机 runner 整合） | [mqgg5630-cyber/AgentArena](https://github.com/mqgg5630-cyber/AgentArena)（fork） | 多会话并行（见下表） | 见下表 | 按文件夹注册 | ✅ 模式 C 试点中 |

**（已搁置）AgentArena 多会话布局** —— 2026-09-15 用户决定：**多会话协作成本高于收益，暂时不弄**。
下表作为历史与"随时重启"的说明书保留；今后默认"一会话一仓库"（模式 A）。
重启方法、命名规则与合并纪律见 `skills\git-sync\README.md` 第七节。

**先做一件事：把搁置会话的本机值守摘掉**（3~4 个任务每 2 分钟各闪一次窗，就是"老是弹窗"的主因）：

```powershell
cd E:\0github\git-sync\agentarena-w1  ; .\watch.ps1 -Unregister
cd E:\0github\git-sync\agentarena-w2  ; .\watch.ps1 -Unregister
cd E:\0github\git-sync\agentarena-int ; .\watch.ps1 -Unregister
Get-ScheduledTask git-sync-watch-* | Select-Object TaskName, State   # 应只剩 git-sync-watch-git-pull-arena
```

| 角色 | 分支（均已在远端，技能 v2.4.6；总部 v2.4.7 已发，非紧急） | 本机路径 | 值守任务名 |
|---|---|---|---|
| 工作会话 1 | `arena/01a0a3ee-agentarena` | `E:\0github\git-sync\agentarena-w1` | `git-sync-watch-agentarena-w1` |
| 工作会话 2（已自发写工作报告） | `arena/01a0a3d6-agentarena` | `E:\0github\git-sync\agentarena-w2` | `git-sync-watch-agentarena-w2` |
| 汇总会话（release manager） | `arena/01a0a3f1-agentarena` | `E:\0github\git-sync\agentarena-int` | `git-sync-watch-agentarena-int` |
| 汇总状态文件 | 工作方 `results/status/work-report.md`；汇中方 `results/status/integration.md` | — | — |
| （旧，已清理 2026-09-15） | `arena/01a0a356-agentarena`（由 3f1 并入零丢失后删）、`arena/01a0a3d5-agentarena`（无独有交付物，删） | `E:\0github\git-sync\agentarena`（旧克隆，可删可留） | 已 Unregister |

## 二、日常命令速查（在任何已连接仓库的本机路径里）

> 多个 Arena 会话分任务 / 同仓库多分支 / 汇总会话的协作模式：见 `skills\git-sync\README.md` 第七节。

```powershell
.\sync.ps1                # 取：拉最新
.\push.ps1 "说明"          # 传：提交并推送（默认静默：不弹窗、不等确认）
.\doctor.ps1              # 体检（技能版本 + 值守/心跳/凭据三行）
.\download.ps1 -Set final # 交付物镜像到 ..\<仓库名>_out\
.\auth.ps1                # 凭据体检：现在推送能不能不点确认
.\auth.ps1 -Setup -Verify # 一次性修好并当场证明（gh > GCM+dpapi）
.\watch.ps1 -Status        # 值守活着吗：模式 / 上次运行 / 心跳 / 最近一轮 / other tasks
.\watch.ps1 -Focus         # 只留这一会话（暂停其他 git-sync-watch-*，不删任务）
.\watch.ps1 -RestoreParked # 恢复被暂停的其他会话值守
.\watch.ps1 -Test          # 立刻跑一次值守，验证"真的会跑"
```

值守（自动验证循环，本机侧）：

```powershell
.\watch.ps1 -Register -Interval 2   # 注册值守（每 2 分钟轮询；v2.3.4 起默认就是 2）
.\watch.ps1 -Register -Interval 10  # 降频：闪窗减 5 倍（代价：请求最多等 10 分钟才被消化）
.\watch.ps1 -Register -Headless     # 零窗口（S4U）——必须"以管理员身份运行"的 PowerShell；push 停摆就回退重注册
.\watch.ps1                         # 手动跑一轮（立即处理 pending 的请求）
.\watch.ps1 -Unregister             # 摘除值守
.\watch.ps1 -Focus                  # 本克隆为当前会话：暂停其他值守（任务保留）
.\watch.ps1 -RestoreParked          # 恢复 parked.json 里的值守
Get-ScheduledTask git-sync-watch-*  # 看本机注册了哪些值守
```

## 二·五、本机升级步骤（v2.4.7 → v2.5.0，每台机器一次）

v2.5.0 的脚本在新分支上，所以本机克隆要**切一次分支**（旧分支 `arena/01a09fc1-git-pull-arena`
冻结在 v2.4.7，仍然可读）：

```powershell
# 本会话：新文件夹克隆，不要 checkout 进旧目录
cd E:\0github\git-sync
git clone -b arena/01a0a821-git-pull-arena https://github.com/mqgg5630-cyber/git-pull-arena.git git-pull-arena-s2
cd git-pull-arena-s2
.\auth.ps1 -Setup -Verify                      # 免点击推送：配好 + 实跑证明（不弹窗）
.\watch.ps1 -Register                          # 新值守：零窗口 + 注册后自检（任务名带 -s2，不碰旧任务）
.\doctor.ps1                                   # 四行都要好看：sync / watcher / heartbeat / auth
```

> **round 7 已排好**（2026-09-15）：新分支上的 handshake 是 `awaiting_check/pending`，
> 本机升级 + 重注册值守后，第一次轮询就会自动跑这轮验收并推回结论；检查项 2a/2b
> 分别断言"免点击推送"与"零窗口启动器"，所以这一轮就是两条硬要求的机器证明。

验收（两条硬要求）：

* **无弹窗**：`.\watch.ps1 -Status` 的 `mode` 是 `zero-window (launcher exe)`，
  且每 2 分钟轮询时屏幕上**没有任何窗口**（heartbeat 里的 `last_run` 在推进）。
* **免点击**：`auth.ps1 -Verify` 退出码 0；值守轮询 `last_push=ok`，全程没有人点过任何东西。

其它仓库（image-to-editable-pptx / zhongqi 等）升级：让该仓库的 Arena 会话重新跑一次
`agent-install.sh`（配置不丢），本机再跑 `auth.ps1 -Setup -Verify`（凭据是**每台机器**级别，不用每仓库重配）。

## 三、技能升级命令（任何仓库同一条，已有配置不丢）

给那个仓库的 Arena 会话说"升级 git-sync"，或手动：

```bash
git clone --quiet --depth 1 -b arena/01a0a821-git-pull-arena \
     https://github.com/mqgg5630-cyber/git-pull-arena.git /tmp/src \
  && bash /tmp/src/skills/git-sync/scripts/agent-install.sh
```

当前版本看 `skills\git-sync\VERSION` 或 `.\doctor.ps1` 的 skill 行。

## 四、故障速查（本台账相关的）

| 现象 | 处理 |
|---|---|
| 在 main 上提交时把未跟踪文件误扫进去（main 没有 .gitignore） | 修正：`git checkout <工作分支> -- .gitignore` 随下一次 main 提交带上；skills/ 模板只在工作分支上，跨分支取文件用 `git checkout <工作分支> -- <路径>`，不要 copy；清残留目录用 `git rm -r -f`（暂存改动会挡住不带 -f 的 rm，然后被 add -A 又提交回去） |
| 新会话装完旧会话值守停了 | 默认行为：`-Register` 暂停其他任务。回原会话 `cd <原克隆> ; .\watch.ps1 -Focus`；全恢复 `.\watch.ps1 -RestoreParked` |
| 值守 12 分钟没响应（那边第 5 轮遇到过） | 本机手动 `.\watch.ps1` 跑一轮；`del $env:TEMP\git-sync-watch-*.lock`；`Get-ScheduledTaskInfo <任务名>` 看上次运行 |
| `-Setup` 之后反而开始要登录（v2.5.0 的坑） | v2.5.1 已修：`-Setup` 先探测再动手；若已受影响，跑 `.\auth.ps1 -MigrateStore` 或 `.\auth.ps1 -Unset`，原凭据立刻可见 |
| 值守注册/运行时报 ParserError（`InvalidVariableReferenceWithDrive`） | `"$var:"` 写法会让**整份 .ps1 解析失败**（一行都不跑）：改成 `"${var}:"`；gate 已内置 `code/scan_ps_var_colon.py` |
| 值守推送卡住等同意 / 要手动点确认 | v2.5.0 起推送默认静默：`.\auth.ps1 -Setup -Verify` 一次配好免点击凭据（gh helper 或 GCM+`credentialStore=dpapi`）；心跳里出现 `auth: no silent credential` 就是这个没配 |
| 值守每 2 分钟闪一下黑窗（无弹窗要求） | v2.5.0 默认零窗口（编译 GUI 子系统启动器）：`.\watch.ps1 -Unregister` → `.\watch.ps1 -Register`；`-Status` 的 mode 应显示 `zero-window`（`-Flash` 才是旧的闪窗模式） |
| 值守"注册了但没在跑" | `.\watch.ps1 -Test`（立刻跑一次并等心跳）；别信 `LastTaskResult`（v2.4.4 的 VBScript 启动器就是 0 但没跑），要看 `%LOCALAPPDATA%\git-sync\watch-*.log` 与心跳 json |
| S4U/-Headless 报"拒绝访问 0x80070005" | 改任务 Principal 必须管理员权限：用"以管理员身份运行"的 PowerShell 重跑同一条命令；回退 Interactive 同样要在管理员窗口做 |
| 检查日志只有头部几行、exit 0 疑似空转 | v2.4.7 起日志带 `elapsed:` 行 + 空输出显式标记；elapsed≈0 且本该有产出 → check_cmd 链没真跑（w1 实战：powershell -File 链空转，改 `bash code/local_check.sh` 原生链修复） |
| agent 说读不到你的检查结果 | 大概率是 BOM/编码，v2.3.2 已修——确认那边技能 ≥ v2.3.2 |
| 本地改动"消失" | 在 stash 里：`git stash list` → `git stash pop` |

## 五、历史里程碑

- 2026-09-17：**本会话（`arena/01a0ad15`）WSL 桥验证 round 38 passed + accepted**：用户「LibreOffice不装，测试通了就行，不一定要生成docx/pptx」。动作：新增 `code/recipes/bridge-check.json`（`local.skip`，只验 1+3：门禁 + 交付物完整性），临时把 `code/loop.json`（+ payload 镜像）切到它，`agent-handsfree.sh --timeout auto` 一次过 —— 真机 `LAPTOP-R77M5D6M`（WSL，cron 值守）2 分钟内应答：gates 5/5、7 份 Office 3a–3g 全 OK、4b `loop-ok`、4c `opened=unknown`（预期内 WARN），成功标准 147/147，`b33e648 accepted`。验完把 `loop.json` 切回 `office-deck`（`bridge-check.json` 留仓当诊断配方）。
- 2026-09-17：**本会话（`arena/01a0ad15`）装用户链接会话（`arena/01a0aa00`）的 skills + 与 WSL 本机打通**：用户短句＝「安装 https://arena.ai/agent/01a0aa00-… 的skills」+「本机是 Windows 笔记本里的 WSL（`~/projects`），不要覆盖已有目录」。动作：`agent-install.sh --source <01a0aa00 分支本地检出>` 装 git-sync **v2.8.1**（与 main 已有版本一致，只动配置分支 → `arena/01a0ad15-git-pull-arena`）；office-loop **v2.0.0** 用 `--check` 验证在位；`success_criteria.json` 只改分支指针（01a0aa00→01a0ad15）+ 描述前缀，其余 120 条断言原样继承（门禁 `criteria-needles` 34/34 通过）；交接块改用 `code/handoff_linux.sh`（Bash 版，`~/projects` 新目录 + `bootstrap-linux.sh` 注册值守，与 Windows 侧值守并存）。
- 2026-09-16：**上一会话（`arena/01a0aa00`）装用户链接会话（`arena/01a0a9f0`）的技能 + 与本地打通**：用户短句＝「安装 https://arena.ai/agent/01a0a9f0-… 的skills」+「与本机（spyder / conda base，`E:\0github\git-sync`）打通」。动作：`agent-install.sh --source <01a0a9f0 分支本地检出>` 把 `skills/git-sync` 从 v2.7.4 升到 **v2.8.1** 并把配置分支改成本会话分支 `arena/01a0aa00-git-pull-arena`；仓库级 `code/check_all.sh`（含 2b「配置分支 == HEAD」）、`code/local_check.ps1`（3a–3h + 成功标准）、`.gitattributes`（文本统一 LF）、`.gitignore` 一并对齐；新增 `code/make_bridge_report.py` + `deliverable/BRIDGE_01a0aa00_v2.8.1.docx/.pptx` + `OFFICE_HASHES.json`（沙箱内先用 Python 跑同一套 3a–3g 镜像自检，再交本机真 Word/PowerPoint 判定）。本机侧只需粘一次 `agent-handoff.sh` 生成的交接块（新文件夹 `git-pull-arena-01a0aa00`）。
- 2026-09-17：**技能包收尾 + 两条新门禁（round 34–35）**：round 33 真机 4a/4b/4c 全绿却被我自己的验收标准判 failed（标准里写 `'round 28'`，文件里是 `round-28`）→ 新增 `code/check_criteria_needles.py`（每条 require_contains / require_regex 是否真能在工作区满足）并进 `check_all.sh`；round 34 的 accept 又把 `results/**` 全量还原，连验收标准里的新条目一起还原掉了 → `agent-check.sh --accept` 与新的 `code/pull_machine_evidence.sh` 改为**只还原机器拥有的路径白名单**（`results/status/check_r*.txt`、`pptmaster_local*`、`svg/*`、`results/*/DECK_*.pptx`），标准与文档归助手。另外技能新增 `--refresh-sections`（升级已装技能只替换那两段，先备份，结果不平衡就拒绝）。round 34/35 真机 passed + accepted（120 条标准全过，含 11 个 office-loop 文件），两份 deck 在机器 `out\` 里前后不变。
- 2026-09-16：**把本案做成可安装技能 `skills/office-loop` v1.0.0（round 33）**：用户要求「把你这个作为成功案例，让别的对话直接安装你的skills」，并给定了两轮提示词。动作：把本案的循环抽成自带 payload 的技能包 —— `SKILL.md`（安装/一轮循环/故障排查/边界）、`CASE_STUDY.md`（两轮提示词 + 真机证据表 + 链路图 + 6 个坑与修法 + 复现步骤 + 后续优化清单）、`prompts.md`（可直接粘贴的提示词，含「不要打开 arena.ai 链接，映射到 GitHub 分支」）、`agent-install.sh` + `tools/install.py`（幂等安装：复制 7 个循环文件、按 sentinel 插入 `code/local_check.ps1` 的交付物段与 ppt-master 段、合并 success_criteria、跑 `deck_layout_selftest.py`、写安装回执）、`templates/`（deck 配置 + 机器已验证的两段 PowerShell 原文）、`tools/check_payload.py`（payload 与仓库 code 的逐字节漂移门禁，已进 `check_all.sh`）。沙箱验证：干净仓库（只有技能目录）里安装成功、二次运行幂等、插入后 `local_check.ps1` 结构平衡且锚点唯一、安装后的页源生成器在自检里跑出 12 页且无模块框重叠。
- 2026-09-16：**换主题：机器学习筛选鲜味肽（round 32 起）**：用户要求「主题换位机器学习筛选鲜味肽，用我电脑的安装好的 venv 环境生成」，并且**不要覆盖**之前那份 `DECK_local_20260916.pptx`。动作：把 deck 主题抽成 `code/pptmaster_deck.json`（generator / project / deck_name / evidence_dir / markers），新增 `code/make_deck_umami.py`（12 页：问题 → 数据 → 特征 → 模型 → 评估 → 漏斗 → 湿实验 → 复现；所有数字标注「示例」），公共框架抽到 `code/deck_kit.py`（原 git-sync deck 重构成同一框架，逐字节比对一致）；新 deck 用独立项目目录 `umami-01a0aa00_<date>`、独立成品名 `DECK_umami_01a0aa00_v1.pptx`，成品 + 质检报告 + 页源回传到 `results/umami/`。沙箱实测：`svg_quality_checker` 12/12 passed、0 warning、blocking 0，`svg_to_pptx` 导出 12 页、40 部件、标记词全中、`pptx_delivery_check` errors=0 advisories=0；之后交本机（venv + 真 PowerPoint）判定。
- 2026-09-16：**新任务测试：用 PPT Master 重新生成好看的 pptx（round 23）**：用户要求「用 ppt master 重新生成好看的 pptx」并再跑一次自循环。动作：沙箱克隆 `hugohe3/ppt-master` v6.4.0（MIT），按它的 Quick Generate 路由建项目 `projects/arena-loop-01a0aa00_20260916`，用 `code/make_deck_pptmaster.py` 写 12 页 canonical SVG（dark-tech 风格），过 `compact_svg_styles.py` + `svg_quality_checker.py`（blocking 0；两轮修掉「根级 <g> 缺 data-pptx-bounds」与「文本超出分组 bounds」共 7 条 blocking），再由 `svg_to_pptx.py` 编译成 **原生 DrawingML 形状**的 `deliverable/DECK_01a0aa00_v2.8.1.pptx`（12 页、0 图片、postflight passed）。清单扩到 7 份产物，交本机 3a–3h 判定。
- 2026-09-16：**本会话（`arena/01a0aa00`）自循环闭环（round 20 → 22）**：用户「先清理掉其他任务并开始自循环：生成 docx 和 pptx，推到本会话分支，本机检查后把状态 push 回来」。动作：本机值守（`bootstrap -Auto` 已经 park 其它 `git-sync-watch-*`）→ round 20 沙箱生成 `BRIDGE_01a0aa00_v2.8.1.docx/.pptx` → 本机 27 秒 passed（3a–3h + 真 Word/PowerPoint 开档）；round 21 新增 `GUIDE_01a0aa00_v2.8.1.docx/.pptx`（安装/日常/值守/故障/边界）→ 本机 34 秒 passed（4 份产物、54 条成功标准全过、0 WARN/SKIP）；round 22 出 `DELIVERY_01a0aa00_v2.8.1.docx/.pptx`（交付清单 + 本机回执）并同样交本机判定。每轮 `agent-handsfree.sh --timeout auto` 一回传即判定并 `--accept`，全程无人点过任何东西。
- 2026-09-16：**上一会话（`arena/01a0a9f0`）装 v2.8.1 + 与本地打通**：用户短句＝「安装 `arena.ai/agent/01a0a98d` 的 skills，与本机（spyder/conda base，`E:\0github\git-sync`）打通」。动作：`agent-install.sh`（`--source` = 分支 `arena/01a0a98d`）把 `skills/git-sync` 从 v2.7.4 升到 **v2.8.1** 并把配置分支改成本会话分支；仓库级 `code/check_all.sh`、`code/local_check.ps1`（3a–3h）、`.gitattributes`（LF 统一）、`.gitignore` 一并对齐；新增 `code/make_link_proof.py` + `deliverable/LINK_PROOF_v2.8.1.docx/.pptx` + `OFFICE_HASHES.json`（沙箱内先用 Python 跑同一套 3a–3g 镜像自检，再交本机真 Word/PowerPoint 判定）。本机侧只需粘一次 `agent-handoff.sh` 生成的交接块。

- 2026-09-14：git-sync v1（zhongqi 沉淀）→ 本仓库安装 → 双向打通（`1d4d62f`）
- 2026-09-14：v2（agent-install / 回执 / doctor -Fix / 增量下载 / PR / profile）
- 2026-09-14：v2.1（新会话提示词模板）→ 首次跨会话复用成功（image-to-editable-pptx）
- 2026-09-15：v2.2（回执归档 + 硬件上报：GTX 1650 / 22 conda 环境）
- 2026-09-15：v2.3（自动验证循环）→ 真机 4 轮闭环（BOM / .gitignore .log 两个真 bug 修复）
- 2026-09-15：image-to-editable-pptx 项目级验收 5 轮全过（fig3 PPTX：227 形状 / 0 贴图 / 1139 可编辑字符）
- 2026-09-15：v2.3.4（移植 add -A 假删除守卫 / 值守默认 2 分钟 / 模板日志可捕获）；CONNECTIONS.md 台账建立
- 2026-09-15：AgentArena fork 建立（mqgg5630-cyber/AgentArena，只含 main，与上游同步——权限障碍解除）
- 2026-09-15：v2.3.5（值守锁 30 分钟过期自愈——进程硬崩后锁残留会让值守永久停摆）
- 2026-09-15：AgentArena 会话开工即验收通过（round 1 accepted `2bcc53b`：文档在位 + npm 冒烟；local-runner 设计文档落仓）
- 2026-09-15：v2.4.0（`agent-wait --auto-accept` / 本机即 Runner 配方 / health.yml 每日体检 / 安装器保留根目录配置）
- 2026-09-15：v2.4.4→v2.4.6（wscript+vbs 隐形启动器实战判死：Win11 弃用 VBScript，值守全线静默停摆、LastTaskResult 0 假象 → 回退 `powershell -WindowStyle Hidden` + `-Headless` S4U 实验项）；恢复命令执行后**值守首次全自动闭环**——w2 round 3 请求 30 秒自动判定回推（`f6c74bf`）、w1 round 2 39 秒、3f1 回归 92 秒，全程无人碰机器
- 2026-09-16：**v2.7.4**（用户坚持短句 `安装 arena.ai/agent/01a0a821 的skills，与本地打通`：助手必须自己映射到 GitHub clone，禁止打开 arena.ai、禁止向用户要长提示词。入口 `01a0a821.md` + SKILL description TRIGGER。zhongqi `01a0a954` 再次没先打通本机）
- 2026-09-16：**v2.7.3**（根因：新会话只贴 arena.ai 链接 → 沙箱打不开 → 对方自制 python/.venv 冒充本机。用户应粘 `templates/USER_PROMPT.md` 整段，内含 GitHub clone。test-auto-arena `01a0a948` 再次踩坑）
- 2026-09-16：**v2.7.2**（铁律：与本地打通 = Windows `watch.ps1`，禁止沙箱 `local/inbox` / 自制 python skills；第一条回复必须是填好的 PowerShell；`agent-install.sh` 补拷 `install.ps1`。test-auto-arena 那次就是踩了假本机）
- 2026-09-16：**v2.7.1**（新会话一句话触发装技能+自循环；`agent-wait`/`agent-handsfree` 默认 `--timeout auto`：值守一回传就停，上限=check_timeout_min*60+180，不再死等 600s。协议 `templates/one-sentence.md` / `task-loop.md`。Arena 链接 `arena.ai/agent/01a0a821-...` 等同本技能总部）
- 2026-09-16：**v2.7.0**（解放双手：值守 auto_pull/auto_push + Agent `agent-handsfree.sh`/`agent-criteria.sh`；先例 `new`/`arena/01a0a90b-new` round 1 `6fe3dc7` accepted。HQ 必须重注册。说明 `deliverable/HANDS_FREE_v2.7.0.md`）
- 2026-09-16：**v2.6.9**（新会话自动暂停其他 `git-sync-watch-*`：Stop+Disable+杀循环，不删任务；台账 `%LOCALAPPDATA%\git-sync\parked.json`。继续原对话：HQ `cd git-pull-arena-s2 ; .\watch.ps1 -Focus`。一次全恢复：`.\watch.ps1 -RestoreParked`。`-Register -KeepOthers` 跳过。`-Status` last-check 与日志轮转均 UTF-8。说明 `deliverable/FIX_v2.6.9.md`）
- 2026-09-16：**v2.6.8**（收尾行闸门已在上一会话真机 PS 跑过；本会话 `arena/01a0a821` + 新克隆 `git-pull-arena-s2` 做推送闭环。① 值守每个出口都必须留收尾行：`Invoke-PollRound` 6 个出口 + `Invoke-PollOnce` 2 个出口各自设置 `$script:PollSummary`，循环与手动单轮都打印它，手动单轮再以 `== finished at ...` 收尾（不再静默退回提示符）；新增 `code/check_loop_summary.py`（闸门 §3c）+ `code/check_loop_summary.ps1`（accept 2c）**静态**盯住这条规则，删掉任意一条赋值闸门就 exit 1 ② `Get-PowerShellExe` 优先 64 位（32 位进程走 `SysNative`）③ `-Status` 的 host log 尾部按 UTF-8 读（修中文乱码）+ 任务结果码人话注释（0/267009/267011/267014/2147946720=0x800710E0 都是正常码）+ 代理提示改成可照抄的 `setx HTTPS_PROXY "..."` ④ `doctor.ps1` 同步把这些码当正常 ⑤ 新增 `templates/install-one-liner.md` 与 README「零」节的四行安装块/三命令升级块 ⑥ 删掉 `f0d5d1c` 带进来的 0 字节 `code/accept_test.ps1`）
- 2026-09-16：**v2.6.7**（值守循环拿到可见控制台时打印"这个窗口就是值守"的说明 + 每轮打印 `== idle - next poll at HH:MM:SS`，消除"卡在 verdict pushed back"的误解；round 15 已验证：单轮不再重跑）
- 2026-09-16：**v2.6.6**（修我自己的两个真 bug：① agent-sync.sh 用过期握手覆盖本地已推回的 passed→pending，害值守重跑同一轮；改为提交前比对、本地侧已答则取远端 ② 旧版本循环无 pid 文件、-Unregister 停不掉 → 循环启动时清理同仓库旧循环，-Status 列出 other loops，-Pause/-Unregister 一并清理（"窗口卡住/刷屏"的根因））
- 2026-09-16：**v2.6.5**（round 13 **通过**：2a 免点击推送 PROVEN、2b 分级通过，结论自动推回=闭环；"卡住"=值守常驻循环被挂到用户控制台 → 循环自我脱离（隐藏重启）+ 单实例 pid 闸 + -Pause/-Unregister 真停循环；退出码改用 `/v:on` + `!ERRORLEVEL!`（修"闸门失败却报 passed"）；防坑扫描器在 python 不可用时 SKIP）
- 2026-09-16：**v2.6.4**（round 12 结果：**2a 免点击推送 PROVEN、2b 分级通过**；唯一失败是我 gate 的 python 假失败 → 改为自检解释器 + sed 回退；push.ps1 全走 cmd/c（最后的 poll crash）；退出码写入标记文件（修 `failed (exit )`）；每轮自愈补推未推送的结论提交；启动器改 ASCII 目录 + MZ 校验）
- 2026-09-16：**v2.6.3**（2a 已成立：push --dry-run PASSED；修值守跑不完的三坑：① sync.ps1 的 git stderr 在 EAP=Stop 下变成终止性错误（poll crashed: Already on ...）→ 全部走 cmd /c；② check_cmd 用裸 `powershell` 启动失败（%1 不是有效的 Win32 应用程序/exit 193）→ 解析绝对路径 + cmd /d /c + 杀进程树 + ANSI 读回；③ 产物提交 amend 化（313 个堆积）；keeper 10 分钟；bash 优先 git 自带）
- 2026-09-15：**v2.6.2**（gh 已登录、凭据探针 OK；修掉我自己的误报：dry-run 推本地 HEAD，非快进被拒被当认证失败 → 改推远端跟踪引用到一次性探针分支，拒绝也计入 READY；push.ps1 遇"只领先结论提交"自动对齐远端后重试（修值守 exit 3 死循环）；local_check 2b 改分级；-Headless 提示管理员窗口；启动器失败打印 host 日志）
- 2026-09-15：**v2.6.1**（实测定位真因：`gh auth login` 超时=网络路径，git 经代理可通而 gh 只认 HTTPS_PROXY → auth.ps1 自动套用 git 的 http.proxy + `-HttpProxy`；PAT 改为离线优先入库（无需 API）；sync.ps1 不再把 results/status 产物堆成 stash（本地提交 + 分叉自动对齐）；值守记录 push 失败原因 last_push_detail；-Status/-Register 提醒代理不一致）
- 2026-09-15：**v2.6.0**（实测定位：本机 GCM 从未存过凭据=推送必然要人点，必须登录一次（`auth.ps1 -GhLogin` 一条命令，gh 令牌放自己配置里，session 0 也能读）；值守改为**常驻循环**——flash 模式也只每次登录闪一次，替代每 2 分钟闪一次；注册前对启动器做冒烟测试并在失败时打印任务结果+host 日志；keeper 触发器每 30 分钟保活；`-Status` 报告循环存活/心跳年龄；`push.ps1 -Prompt` 显式开交互；`auth.ps1` 说明"公开仓库 ls-remote 不代表鉴权"）
- 2026-09-15：**v2.5.1**（实测修复：`auth.ps1` 改为"先探测、只在必要时改"，并会 unset 误设的 `credentialStore`；新增 `-MigrateStore`；`watch.ps1` 的 `$var:` 盘符陷阱根治 + 注册环境预检（git/bash/powershell 路径入心跳）；`local_check.ps1` 禁止 gate 空转通过；gate 新增 `code/scan_ps_var_colon.py`）
- 2026-09-15：**v2.5.0**（零弹窗值守 + 免点击推送：`auth.ps1`（gh/GCM-dpapi + 关闭提示的实跑验证）；`watch.ps1` 默认 GUI 子系统启动器（CreateNoWindow，无管理员、不碰 VBScript）+ 注册自检 + `-Status`/`-Test` + 心跳/日志落 `%LOCALAPPDATA%\git-sync\`+ 检查硬超时；`push.ps1` 默认静默、认证失败 exit 4；gate 增加"每个 .ps1 可解析"；多会话协作搁置）
- 2026-09-15：v2.4.7（实测吸收：S4U 注册/切换需管理员控制台 0x80070005；检查日志加 `elapsed:` 行 + 空输出显式标记——w1 的 check_cmd 链空转、轮轮假通过的教训）；356/3d5 旧分支已由 3f1 清理
