# MVP 验收记录

## 2026-11-12 接手审计与交付（本轮）

结论：**MVP 流程与图形交互验收通过，AI 可用性审查完成。** 没有真人反馈，不对趣味性或最终平衡作已验证结论。

### 基线与范围

- 实际工程：`C:\Users\Administrator\.codex\worktrees\match-state-mvp\game`；分支 `codex-example`；基线 `a703a24e7f2fdf375ff68382475a16f89e5e6a52`。开始时暂存、未暂存及未跟踪文件均为空，交付时有本轮未提交变更。
- 远程 `https://github.com/dsc114514/game.git` 保持不变；没有提交、推送、PR 或历史改写。
- `E:\Documents\ChatGPT\example` 是未提交过的空仓库，内有 `game-review` 审阅副本；`E:\Documents\ChatGPT\game` 为 `Card-Asset` 工作树并有既有本地修改。通过 Git worktree、分支及实际文件定位后，只修改已有 MVP 工作树，其他两处未改。
- 实际引擎 `4.6.1.stable.official.14d19694e`；图形验收为 OpenGL 3.3 / Compatibility / AMD Radeon 780M；另验证默认 D3D12 / Forward+ 入口正常退出。
- 已满足并复用：2～4 人、既有 23 格/24 边路线、每连接一步、岔路等待、落点结算、兑换、第三星返抵胜利与重开。未扩张卡牌、战斗等后续玩法。

### 修复与决定

| 文件 | 改动与理由 |
| --- | --- |
| `example/gameplay/turn_controller.gd` | `input_id` 进程内跨局唯一，每步也更新；`advance(id)` 校验旧步和旧局；加入可选随机种子、快照与控制台种子记录 |
| `example/gameplay/match_state.gd` | 仅补职责注释；保留受保护的数据事务，控制器统一决定何时结算、轮换、结束 |
| `example/gameplay/route_data.gd` | 安全处理畸形格子类型，避免校验器因不同 Variant 类型比较而抛脚本错误 |
| `example/board/route_layout.gd` | 非字典、缺失、非文本与空 ID 给出诊断，不让布局校验自身中断 |
| `example/board/game.gd` | 适配移动 token、支持 `--seed=整数`；按下时捕获操作上下文，拒绝跨回合松开；明确选路耗一步；日志行距设 0，修复最后一行越出视口 |
| `example/tests/turn_controller_test.gd` | 增加跨步/跨局、种子重现与非法掷骰不消耗 RNG 的回归；随机覆盖固定 seed=20261112 并打印实际骰子序列 |
| `example/tests/route_data_test.gd` | 增加畸形类型、ID 与显示数据的校验器回归 |
| `example/tests/game_ui_test.gd` | 真实鼠标按下/跨回合/松开的边界回归，填满日志后检查实际视口边界 |
| `example/tests/mvp_acceptance_test.gd` | 默认随机 UI 检查、十个阶段截图、真实帧完整对局；截图超时失败；恢复被最小化的验收窗口；记录字符串种子避免 JSON 数字精度丢失 |
| `example/tests/mvp_acceptance_test.gd.uid` | 本轮编辑器导入生成的脚本稳定资源 ID，与其他已有测试 UID 保持一致 |
| `AGENTS.md`、`README.md`、本文件 | 移除过期入口/无测试说明；README 保留当前规则、命令和限制；历史验收原文移入本文件并明确标为历史 |

关键取舍：沿用合法路线、程序生成占位 UI 和既有分层，不为文件数量或两个 enum 重构。状态层没有自己的定时器或输入来源；合法阶段组合和转换入口已写进 README/代码。固定骰子仍共用正常移动、结算和轮换路径。显式 `--seed` 重开复用同一 seed，默认重开产生新 seed；仅承诺同引擎版本和同操作顺序重现。将来若引入独立状态推进者或并发规则调用，再审查阶段职责；后续玩法、平衡与美术须另行授权。

### 本轮结果与证据级别

检查数不是独立场景数；逐帧、布局和随机路径会改变计数。下列通过项均为实际运行，退出码 0，无脚本错误。

| 证据层级 | 状态 | 本轮结果 / 文件 |
| --- | --- | --- |
| 静态检查 | 通过 | `git diff --check`；13 个本轮文件 UTF-8 无 BOM/LF/末尾换行；唯一根 `project.godot`；GDScript/场景资源路径存在；编辑器导入正常退出 |
| 规则运行 | 通过 | `match_state`: 229 / 0；`route_data`: 295 / 0；`turn_controller`: 1236 / 0；日志 `rules-match-state.log`、`route-audit-final.log`、`rules-turn-controller.log` |
| 无窗口显示与输入 | 通过 | `route_preview`: 93 / 0；快速 `game_ui`: 4826 / 0（`ui-log-bounds.log`）；真实帧 `mvp_acceptance`: 4789 / 0（`mvp-acceptance-final-headless.log`、`mvp-final-headless.jsonl`） |
| 图形模式交互与视觉 | 通过 | 最终 `mvp_acceptance`: **3945 / 0**，35.654 秒正常结束，原生进程退出码文件 `mvp-delivery.exit` 为 `0`；`mvp-acceptance-delivery.log`、`mvp-delivery.jsonl` |
| 默认入口 | 通过 | 图形测试加载实际 F5 场景，无测试按钮，鼠标点击随机 ROLL、正常帧移动并换人；另 `--path . --quit-after 4` 使用项目默认 D3D12/Forward+ 退出 0（`default-d3d12-final.log`） |
| 显式 seed | 通过 | `game_ui_test.gd -- --seed=123`: 4828 / 0，开局和重开均记录 seed 123（`ui-seed-123.log`） |
| AI 可用性审查 | 通过 | 实际渲染画面逐项检查，见下表；发现日志裁切并修复，最终图形与布局检查通过 |
| 真人反馈 | 未执行 | **未取得**；不宣称陌生玩家理解或真人试玩通过 |

所有运行日志、JSONL、PNG 在忽略目录 `.godot/`。最终图形记录已另存为 `.godot/mvp-delivery.jsonl`，不会被普通验收运行的 `mvp_acceptance.jsonl` 覆盖。截图同名重跑仍会覆盖。

关键边界的证据：规则用例从合法零开局买到三颗星后，经过中心而不获胜，再准确落点获胜；连续岔路、恰停岔路、普通路径、金币仅落点奖励、失败快照不变、重复结算、2/3/4 人两轮和结束冻结均有直接断言。完整图形局采用全 1 骰子，不将规则层“达标后路过中心”描述为该图形局过程。

### 完整图形对局记录

最终默认随机场景 seed `-4128579442513597572`，实掷 `1`，P1 准确落 `c01` 得 10 金钱后轮到 P2。没有显示测试骰子。固定完整局 seed `2261672442639872551`（仅记录环境；该局显式点击测试骰子），点数序列为 `1 × 134`，每次岔路选 `a01`。P1 中心放弃，P2 中心兑换。

| 时刻 | 实际状态 |
| --- | --- |
| 第 14 回合 | P2 兑换前 20 金钱，支付 20 后 0 金钱、1 星 |
| 第 54 回合 | P2 兑换前 70，支付后 50、2 星 |
| 第 94 回合 | P2 兑换前 120，支付后 100、3 星；仍未获胜，正常换人 |
| 进入第 97 回合时 | 已记录 P2 离开中心且保持 3 星、未获胜（离开的行动为第 96 回合） |
| 第 134 回合 | P2 再次准确落中心，3 星、170 金钱，立即获胜，不扣费、不换人 |
| 获胜后 | 点全部已禁用操作并等待正常帧，完整状态保持不变 |
| 重开 | 鼠标点击 NEW GAME，玩家/赢家/日志/骰子/余步/决策/计时清空；选 4 人，全部出生点、0 钱/0 星；P1 再掷 1，得 10 并轮到 P2 |

全程通过 Viewport 的鼠标移动、按下、松开进行真实控件命中，移动来自正常引擎帧，`Engine.time_scale=1`；没有直接调用按钮回调、`_process`、结算或获胜方法，没有改玩家资源。这是自动交互验收，不是人逐次点击。

### AI 可用性审查

实际查看 `.godot/default_random_setup.png`、`default_random_after.png`，以及 `acceptance_setup/branch/insufficient/exchange/win/restart/four_players/moving.png`。未以源码推断替代这些画面。

| 项目 | 观察与结论 |
| --- | --- |
| 当前轮到谁 | 顶部 CURRENT PLAYER 与玩家栏 CURRENT AT 同时指明，棋子编号对应玩家色块 |
| 下一步与点击位置 | 下一步提示紧邻操作行；开局、ROLL、两个出口、EXCHANGE/SKIP、NEW GAME 均明确 |
| 移动与等待输入 | MOVING / PLEASE WAIT 与 CHOOSE AN EXIT 明确区分，剩余步数可见；已改为说明选择耗一步 |
| 禁用原因 | 未开局提示选人数；移动提示等待；余额不足显示 NEED 20 / HAVE 0 并指向 SKIP；结束显示 GAME OVER |
| 费用与胜利条件 | 操作行下常驻 20 换 1、目标 3、离开后再次准确落点、路过不胜 |
| 遮挡与共格 | 完整 23 格和箭头可见；四名玩家在同一出生点分别显示 1～4 色块，无相互或文字遮挡；两条分支方向可读 |
| 日志与边界 | 首轮发现七行日志末行裁切；行距修复后实际图像完整，真实矩形视口断言通过 |
| 胜利与重开 | GAME OVER/P2 WINS 明确；仅 NEW GAME 可用；重开无棋子/资源/日志残留，四人新局继续 |

### 失败、限制与未执行项

- 原路线校验遇到畸形类型会抛 SCRIPT ERROR。新增回归修复前为 279 检查、25 失败、退出 1；修复后 295 / 0、退出 0。保留 `.godot/route-audit-regression-before.log`。
- 按下鼠标后跨回合再松开原本会作用于新等待；新回归先复现失败，修复后通过。有效断言未删除。
- Windows Computer Use 原生窗口捕获出现 `FrameArrived timed out` / `window capture timed out`，并曾报告窗口最小化；未获得原生 OS 点击验证。最终使用实际 Godot 图形窗口、Viewport 鼠标输入和引擎渲染 PNG 完成自动交互与视觉验收。
- 图形中间运行分别为 `4776 / 7`、`4786 / 5`，退出 1，均因窗口未绘制导致截图超时，不记为通过。最终日志确证曾有 `mode=1, can_draw=false`；验收脚本恢复最小化窗口后等待真正 `frame_post_draw`，仍保留 3 秒失败上限。随后一次 4487 / 0、最终补齐移动/四人画面为 3945 / 0，退出 0。未关闭或放宽截图断言。
- 键盘专项、导出包、其他机器/GPU、其他分辨率、真人反馈未执行。图形为英文占位、仅本机轮流、无存档，商店/事件仅日志。这些限制不阻塞当前指定闭环。
- 无已知阻断当前闭环的缺陷；未验证趣味性、最终平衡或后续玩法。

### 重现命令

在上面的实际工作树根目录执行，完整命令清单另见 README：

```powershell
$godot = 'C:\Users\Administrator\AppData\Local\Temp\codex-godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe'
& $godot --version
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --script res://example/tests/match_state_test.gd --log-file .godot/rules-match-state.log
& $godot --headless --path . --script res://example/tests/route_data_test.gd --log-file .godot/route-audit-final.log
& $godot --headless --path . --script res://example/tests/route_preview_test.gd --log-file .godot/preview-audit-final.log
& $godot --headless --path . --script res://example/tests/turn_controller_test.gd --log-file .godot/rules-turn-controller.log
& $godot --headless --path . --script res://example/tests/game_ui_test.gd --log-file .godot/ui-log-bounds.log
& $godot --headless --path . --script res://example/tests/mvp_acceptance_test.gd --log-file .godot/mvp-acceptance-final-headless.log
& $godot --path . --always-on-top --rendering-method gl_compatibility --script res://example/tests/mvp_acceptance_test.gd --log-file .godot/mvp-acceptance-delivery.log
& $godot --path . --quit-after 4 --log-file .godot/default-d3d12-final.log
```

本轮图形最终使用同目录非 console 的 `Godot_v4.6.1-stable_win64.exe` 与相同参数，由隐藏 PowerShell 监视进程启动可见窗口并记录真实退出码；只影响启动与日志收集，不注入玩法。工作文件 `.godot/run-graphics-delivery.ps1` 保留。

## 历史证据（不代表本轮通过）

以下从原 README 移出，保留原文的时间、数量与失败记录。其中“本轮”“当前”均指当时执行，不能作为本轮现状。

### 运行规则验证

无需安装测试框架。在当前工作区根目录，用 Godot 4.6 系列运行：

```powershell
godot --headless --path . --script res://example/tests/match_state_test.gd
godot --headless --path . --script res://example/tests/route_data_test.gd
godot --headless --path . --script res://example/tests/route_preview_test.gd
godot --headless --path . --script res://example/tests/turn_controller_test.gd
godot --headless --path . --script res://example/tests/game_ui_test.gd
```

若 Godot 未加入 PATH，将 `godot` 替换为本机实际可执行文件。2026-11-12 在本机的独立工作区实际运行命令为：

```powershell
& "C:\Users\Administrator\AppData\Local\Temp\codex-godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path . --script res://example/tests/match_state_test.gd
```

该程序由本机已有的 `E:\Downloads\Godot_v4.6.1-stable_win64.exe.zip` 解压获得，临时路径不保证在其他机器或重启后存在。实测版本 `4.6.1.stable.official.14d19694e`，输出 `match_state: 229 checks, 0 failures`，退出码 0。

状态层验证覆盖 2～4 人初始化与非法人数、玩家及对局隔离、快照隔离、合法收支和溢出、余额不足、精确扣费加星、重复及过期兑换、跳过兑换、轮换回首位、购买第 3 星不立即获胜、路过不触发、达标后再次落在停留点获胜，以及结束后所有状态保持不变。失败会输出错误并以退出码 1 结束。状态层测试只证明规则层；第 3 步另有回合及真实场景按钮验证。

2026-11-12 第 2 步在同一工作区使用上述 Godot 4.6.1 实际运行结果（均退出码 0）：

| 验证 | 实际结果 |
| --- | --- |
| `route_data_test.gd` | `251 checks, 0 failures`：固定路线无重复或悬空连接；两条分支分别按合法出口走三次到停留点，合计覆盖所有格子；出生／停留点存在且分开；普通格单出口、岔路双出口、汇合双入口；故意损坏数据时能识别重复 ID、缺失目标、必需点缺失、死路、孤立环、可进入但无法回到停留点的分支闭环、自连接、非法类型及格式。另验证显示坐标缺失、重叠、非整数及修改显示布局不影响图规则。 |
| `match_state_test.gd` 回归 | `229 checks, 0 failures`，上一轮规则保持通过。 |
| `route_preview_test.gd` 无窗口 | `93 checks, 0 failures`：23 个标签均生成、显示正确 ID 和类型、位于视口内，文字无横向溢出。无窗口检查不代表图形渲染验证。 |
| `route_preview_test.gd` 图形模式 | 使用 `--rendering-method gl_compatibility`，AMD Radeon 780M / OpenGL 3.3，`95 checks, 0 failures`；实际渲染截图保存在忽略目录 `.godot/route_preview.png`，已查看截图，整条路线、两条分支、汇合点、ID、类型和方向箭头可见，无重叠遮挡。 |
| 默认项目入口 | `godot --path . --quit-after 3`，实际 D3D12 / Forward+ 启动，输出 `route_preview: 23 tiles, 24 directed edges, validation passed`。 |
| 编辑器资源导入 | `godot --headless --path . --editor --import --quit` 实际完成，退出码 0。 |

图形验证命令（先完成首次导入）：

```powershell
godot --path . --rendering-method gl_compatibility --script res://example/tests/route_preview_test.gd
```

以上为第 2 步当时的运行记录；第 3 步结果如下。

2026-11-12 第 3 步在同一工作区使用 Godot `4.6.1.stable.official.14d19694e` 实际验证：

| 验证 | 实际结果 |
| --- | --- |
| `turn_controller_test.gd` | `1107 checks, 0 failures`。覆盖无岔路移动、上下分支、紧邻的两次岔路、恰好停在岔路与中心、每连接一步、路过币格无奖与落点仅一次、出生无奖励、商店／事件仅日志、兑换与放弃、2／3／4 人顺序循环、等待时不换人、重复和过期输入、重复内部结算、从零资金沿真实路线到玩家 2 达标返抵获胜、达标后先路过中心不获胜，以及胜利后状态冻结。包含 40 个正常随机回合，检查总数随随机路径略有变化。 |
| `game_ui_test.gd`（上一轮） | 当时实测无窗口 `318 checks, 0 failures`、OpenGL 图形模式 `343 checks, 0 failures`，均退出码 0。通过实际场景按钮的信号、移动计时回调完成零资金开局到玩家 2 获胜。本轮已升级为经 Godot Viewport 注入鼠标事件的界面验收，另验证重开，见下文。 |
| 原状态／路线回归 | `match_state: 229 checks, 0 failures`；`route_data: 251 checks, 0 failures`；静态 `route_preview_test: 93 checks, 0 failures`。 |
| 默认项目入口 | `godot --path . --quit-after 4`，实际 D3D12 / Forward+ / AMD Radeon 780M 启动当前玩法场景，退出码 0，无脚本报错。 |

图形界面闭环验证命令（单独运行并保持窗口可见）：

~~~powershell
godot --path . --always-on-top --rendering-method gl_compatibility --script res://example/tests/game_ui_test.gd
~~~

本轮 `game_ui_test.gd` 通过 Godot Viewport 注入鼠标移动、左键按下和松开事件，点击按钮本身，覆盖控件布局、点击命中与操作接线；不再仅发出 `pressed` 信号。正常随机回合还在引擎实际帧中自动推进，固定骰子长对局为缩短测试时间调用相同的 `_process` 回调完成移动。少数故意发出的重复信号专门用于验证防重保护。这是自动输入验收，不代表人工完整玩过一局，也不是网络或 AI 功能；测试不直接修改玩家资金、星数或位置。

检查覆盖完整路线与格子类型、四种玩家色块及编号、全部 23 格各放四名玩家时标记互不重叠、标记不遮格子文字、控件对齐 16px 网格、阶段文字提示、余额不足、费用与目标规则、胜利后禁用、重新选择人数、旧局回调无效及新局继续。重开检查直接比对玩家、骰子、余步、赢家、兑换编号、待选出口和日志，不仅检查屏幕文字。大量检查来自 92 个可能玩家位置的两两遮挡验证，随机回合导致总数略有变化。

图形模式截图写入忽略目录 `.godot/`：`game_setup.png`、`game_branch.png`、`game_insufficient.png`、`game_exchange.png`、`game_win.png`、`game_restart.png`。已逐张查看实际截图，开局、岔路、余额不足、兑换、胜利和重开画面中整条路线、操作提示、规则与控件均可见，无文字溢出或格子 ID 遮挡。

2026-11-12 本轮“必要界面补齐”最终实际结果，使用 Godot `4.6.1.stable.official.14d19694e`，以下运行均退出码 0：

| 验证 | 本轮结果 |
| --- | --- |
| Viewport 鼠标输入界面验收，无窗口 | `game_ui: 4818 checks, 0 failures`。从零开局到获胜、鼠标点击重开、改为四人、新局日志和状态清零、拒绝旧局回调、再次掷骰均通过。 |
| 同一输入验收，实际 OpenGL 3.3 图形模式 | `game_ui: 4885 checks, 0 failures`；包含六张实际渲染截图、HUD 文字宽高检查；AMD Radeon 780M。 |
| 回合规则回归 | `turn_controller: 1105 checks, 0 failures`。 |
| 原状态、路线、静态预览回归 | `match_state: 229`、`route_data: 251`、`route_preview_test: 93`，均 `0 failures`。 |
| 默认 F5 等价入口启动 | `godot --path . --quit-after 4` 实际以 D3D12 / Forward+ 启动当前 MVP，未报脚本错误。 |

本轮一次与另一个 Godot 窗口并行运行的图形验证未完成，已停止，未计为通过；随后单独使用上面的 `--always-on-top` 命令重跑并取得表中结果。自动截图等待实际渲染帧，运行此验证时保持窗口可见。

当前限制：界面为英文占位、仅本机轮流操作、无保存，商店／事件仍为日志占位；可在获胜后重开，进行中不能直接覆盖对局。未开始第 4 步及后续系统。本轮保留已有本地修改，未提交、推送或创建 PR。

### 本轮 MVP 验收（2026-11-12）

本轮只验收和修复现有闭环，没有增加玩法。实际入口仍是根目录 `project.godot` 的 `res://example/board/game.tscn`；运行时按 F5，或使用 Godot 4.6.1 的图形验收脚本：

```powershell
& "C:\Users\Administrator\AppData\Local\Temp\codex-godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe" --path . --always-on-top --rendering-method gl_compatibility --script res://example/tests/mvp_acceptance_test.gd
```

脚本在实际 Godot 图形窗口中，通过 Viewport 注入鼠标事件点击 `START 2/3/4`、测试骰子、分支、兑换、放弃和重开；移动只由场景的正常引擎帧计时推进，不写入玩家状态、不调用胜利方法。这是自动输入验收，不代表人工逐次点击的完整对局。测试骰子只是界面上的可控复现入口，F5 正常入口仍隐藏它并使用随机骰子。

| 验收项 | 结果 |
| --- | --- |
| 2、3、4 人开局与轮换 | 通过；分别记录 `1,2,1,2`、`1,2,3,1,2,3`、`1,2,3,4,1,2,3,4` |
| 岔路、金币落点与停留点结算 | 通过；两条分支均实际点击，路过金币不奖励，落点只奖励一次 |
| 余额不足、放弃、成功兑换、重复点击 | 通过；禁用兑换、双击放弃和双击兑换均无重复副作用 |
| 购买第 3 星不立即获胜 | 通过；第 94 回合 P2 买到第 3 星后仍是进行中 |
| 离开后再次落停留点获胜 | 通过；第 97 回合离开中心，第 134 回合再次落中心获胜 |
| 获胜后冻结 | 通过；掷骰、选路、兑换、放弃、测试骰子和计时均无效 |
| 重新开局清空状态 | 通过；玩家、位置、资源、骰子、步数、日志、待选出口和编号均复位，随后可开 4 人新局 |
| Godot 完整对局 | 通过；OpenGL 图形窗口从零开局到 P2 获胜，最终 P2 为 3 星、170 金钱 |
| 运行错误、阻塞、按钮状态和重复结算 | 通过；无运行错误，正常移动与等待选择继续，非法按钮禁用 |
| Git 与新增文件 | 通过；`git diff --check` 通过，新增文本均为 UTF-8/LF，资源引用和唯一根 `project.godot` 已检查 |

完整图形验收结果：`mvp_acceptance: 4139 checks, 0 failures`；随后无窗口回归重跑为 `4701 checks, 0 failures`。另外运行 `match_state_test.gd`（229）、`route_data_test.gd`（251）、`route_preview_test.gd`（93）、`turn_controller_test.gd`（1101）和 `game_ui_test.gd`（4820），均为零失败。第一次完整图形验收曾在可选的胜利截图等待处停住；移除该测试脚本的非必要截图等待后重新运行并完整通过，游戏流程本身未出现阻塞。

关键对局记录：P2 在第 14、54、94 回合分别以 20、70、120 金钱兑换第 1、2、3 星；购买第 3 星后没有立即获胜，离开中心后于第 134 回合再次落在中心，日志记录 `P2 WINS WITH 3 STARS`。随后点击 `NEW GAME`，日志清空并以 4 人、全员 0 金钱／0 星／出生点开始新局，P1 的首个金币落点仍可正常继续。

本轮结论：现有 MVP 可通过界面从正常开局玩到获胜，再重新开局，已达到本轮可玩验收条件。未发现需要修改现有玩法代码的闭环缺陷；仅新增验收脚本和本节记录。详细逐回合快照写入忽略目录 `.godot/mvp_acceptance.jsonl`（每次验收覆盖），检查数包含逐帧按钮检查，会随帧率变化。现存英文占位界面、无存档、商店／事件仅日志等限制不阻塞该闭环；没有增加后续玩法。默认入口本轮另以 D3D12 / Forward+ 实际启动成功。
