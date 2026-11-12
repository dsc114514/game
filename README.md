# better-example / game MVP

Godot 4.6 / GDScript 的本机轮流操作 MVP，支持 2～4 人。保留原卡牌拖拽示例及 `card_face`，当前不实现卡牌、战斗、技能、传送、联网、电脑玩家、完整商店、随机事件系统或存档。

## better-example 独立快照

2026-11-12 按用户要求发布本次已验收的 MVP。该分支首个提交没有父提交，不携带原项目的 Git 历史。

- 私有仓库：`https://github.com/beifeng08/better-example`，默认分支 `main`。
- 原项目分支：`https://github.com/dsc114514/game/tree/better-example`，孤儿分支 `better-example`；原项目为公开仓库，因此该分支公开可见。
- 两处起点是同一个独立提交、同一份文件快照。原工作树的未提交改动保留不变。
- 本次仅调整发布说明，游戏实现与已验收版本相同；不创建 PR、不改写原分支历史。
## 当前工程与入口

- 唯一工程文件：根目录 `project.godot`。
- F5 入口：`res://example/board/game.tscn`，默认随机骰子，不显示测试按钮。
- 路线预览：`res://example/board/route_preview.tscn`；原卡牌示例：`res://example/example.tscn`（单独 F6）。
- 本机 MVP 工作树：`C:\Users\Administrator\.codex\worktrees\match-state-mvp\game`，2026-11-12 接手时分支 `codex-example`、基线 `a703a24`，工作区干净。分支、路径可能变化，每次先检查 Git。
- `E:\Documents\ChatGPT\game` 的 `Card-Asset` 工作树有原有本地修改；`E:\Documents\ChatGPT\example\game-review` 是审阅副本。本轮均未改动，不在空仓库重复创建工程。
- `codex-example` 是此前的独立历史分享分支；本次 `better-example` 分发以已验收工作文件建立新的无父提交快照，原验收阶段未提交，详见验收记录。

用 Godot 4.6 打开本工作树根目录的 `project.godot`，等待首次资源导入后按 F5。图形为英文位图字体、1152×896 正交占位棋盘，整数坐标、16px 控件网格、Nearest 与整数倍拉伸；正式美术与最终平衡尚未验证。

## MVP 暂定规则

规则集中在 [`mvp_rules.gd`](example/gameplay/mvp_rules.gd)，用于验证闭环，不是最终平衡方案。

| 规则 | 行为 |
| --- | --- |
| 人数与初始状态 | 只接受 2、3、4 人；每人位于 `spawn`，金钱 0、星数 0；玩家仅有位置、金钱、星数，身份为数组索引 |
| 骰子与移动 | 每回合掷一次 1～6；每条连接消耗一步；路过不触发任何效果、不强停 |
| 岔路 | 尚有步数才等待选路，选择本身走一步；零步停在岔路直接结算 |
| 金币落点 | 金钱 +10，仅结算一次 |
| 中心／停留点 | `center` 与出生点分开；支付 20 金钱兑换 1 星，每次停留最多一次，可放弃；不足时保持决策 |
| 胜利 | 进入停留点结算前已有至少 3 星，立即获胜，不兑换、不换人；本次买到第 3 星必须离开并再次准确落点，路过不胜 |
| 其他落点 | 出生、普通、岔路无奖励；商店、事件只输出日志 |
| 回合与共格 | 等待选择／兑换时不换人；兑换或放弃后顺序轮换、末位回首位；可以共格，无战斗 |
| 失败与结束 | 金钱不能为负；非法操作无玩法副作用；胜利后操作冻结，重开创建干净新对局 |

## 操作与复现

1. 点 `START 2/3/4` 开局，顶部 `CURRENT PLAYER` 和各玩家 `CURRENT AT` 标明当前玩家。
2. 点 `ROLL`。每 0.18 秒沿一条连接移动；`MOVING / PLEASE WAIT` 表示等待移动。
3. 出现出口按钮时点 `TO A01` 或 `TO B01`。选择消耗一步，用剩余步数继续。
4. 准确停在中心时点 `EXCHANGE 20` 或 `SKIP`。余额不足会显示所需金钱和当前余额。
5. 达标后再次准确落到中心获胜，点 `NEW GAME`，重新选择人数。进行中不覆盖已有对局。

操作区常驻显示费用、目标、“买最后一星或路过中心不获胜”；四种玩家色块有编号，共格时分开显示；日志展示最近 7 条，控制器保存最近 128 条。

在项目根目录使用 PowerShell（本机实际引擎版本 `4.6.1.stable.official.14d19694e`）：

```powershell
$godot = 'C:\Users\Administrator\AppData\Local\Temp\codex-godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe'
& $godot --path .
# 显式复现：显示 1～6 测试骰子，仍共用正常移动、落点和轮换路径
& $godot --path . -- --test-dice
# 固定随机种子（相同引擎版本与相同操作顺序）
& $godot --path . -- --seed=12345
```

其他机器将 `$godot` 改为实际安装路径。启动输出和控制器快照记录随机种子；不保证跨 Godot 版本产生相同序列。测试骰子是显式调试入口，无加钱、加星、改位置或自动玩家功能。

完整固定对局复现：两人开局，每回合点测试骰子 `1`，岔路选 `A01`；P1 每次中心点 `SKIP`，P2 每次点 `EXCHANGE 20`。P2 第 14、54、94 回合买第 1、2、3 星，第 134 回合再次落中心胜利，最终 170 金钱、3 星。随后重开 4 人，并继续掷骰。每一步均为合法操作。

## 结构与流程权威

| 文件 | 职责 |
| --- | --- |
| `example/gameplay/mvp_rules.gd` | MVP 暂定常量 |
| `example/gameplay/match_state.gd` | 玩家数据、余额／兑换原子操作、内部生命周期防重；不依赖显示 |
| `example/gameplay/turn_controller.gd` | 对外唯一回合规则入口，决定掷骰、移动、何时结算、换人和结束 |
| `example/gameplay/route_data.gd` | 23 格、24 条有向连接及图校验 |
| `example/board/route_layout.gd` | 单独的整数显示坐标与布局校验 |
| `example/board/game.gd` / `game.tscn` | 读取快照、提交带上下文操作、正常帧计时、占位界面 |
| `example/board/route_preview.gd` | 绘制完整路线与方向箭头；连接不由屏幕位置推导 |
| `example/tests/` | 独立规则、输入与完整图形验收入口 |

控制器流程：`NOT_STARTED → WAITING_FOR_ROLL → MOVING ↔ WAITING_FOR_PATH → WAITING_FOR_EXCHANGE / 下一人 WAITING_FOR_ROLL / FINISHED`。零步时内部唯一结算；所有外部操作经过控制器。UI 不直接写钱、星、位置或赢家。快照为深拷贝。

保留既有两层阶段：控制器拥有流程，MatchState 阶段是数据事务的合法性防护，只由控制器调用。合法组合：

| 控制器 | MatchState |
| --- | --- |
| NOT_STARTED | NOT_STARTED |
| WAITING_FOR_ROLL | WAITING_FOR_MOVE |
| MOVING / WAITING_FOR_PATH | WAITING_FOR_MOVE（本回合尚未迈步）或 MOVING |
| WAITING_FOR_EXCHANGE | AT_STOP |
| FINISHED | FINISHED |

`TURN_COMPLETE` 仅是落点／兑换到控制器立即轮换之间的同步内部过渡，不暴露第二套 UI 流程。没有独立定时器、自动换人者或 UI 状态机决定同一回合。若今后职责发生重叠，再统一结构；本轮不为文件数或两个 enum 重构。

操作使用快照的 `input_id`：`roll_dice(id)`、`choose_path(target,id)`、`exchange_star(id)`、`skip_exchange(id)`、`advance(id)`。编号在同一进程内跨局唯一，每次等待和移动步更新，拒绝旧决策、旧局和重复移动回调。UI 另外绑定局编号，并在输入按下时固定动作上下文。内部下划线成员不是调用接口。

路线：`spawn → c01 → fork → a01/shop01/a02 或 b01/event01/b02 → merge → center → c02 → shop02 → event02 → c03 → p01 → c04 → p02 → c05 → p03 → c06 → p04 → p05 → spawn`。校验覆盖唯一 ID、出口类型与数量、悬空连接、死路、可达性、返抵中心和畸形数据诊断。

## 验证

先完成导入，再运行规则与输入验证：

```powershell
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --script res://example/tests/match_state_test.gd
& $godot --headless --path . --script res://example/tests/route_data_test.gd
& $godot --headless --path . --script res://example/tests/route_preview_test.gd
& $godot --headless --path . --script res://example/tests/turn_controller_test.gd
& $godot --headless --path . --script res://example/tests/game_ui_test.gd
& $godot --headless --path . --script res://example/tests/mvp_acceptance_test.gd
# 单独运行图形窗口，保持可见；鼠标事件经过真实 Viewport 命中，移动只由引擎正常帧推进
& $godot --path . --always-on-top --rendering-method gl_compatibility --script res://example/tests/mvp_acceptance_test.gd
```

`game_ui_test.gd` 是快速输入与布局回归，其长局直接调用 `_process`，不能代替真实帧完整验收。`mvp_acceptance_test.gd` 从实际 F5 配置加载场景，以鼠标按下／松开事件点击按钮，不调用按钮回调、结算或胜利方法，不写玩家状态、不加速引擎时间。完整过程、版本、种子、骰子与选路记录在 `.godot/mvp_acceptance.jsonl`；重复运行会覆盖，保留证据时先复制。失败输出错误并非零退出；检查数包含逐帧与布局断言，不等于独立场景数。

本轮结果、失败修复过程、图形画面与 AI 可用性审查，以及区分后的历史证据见 [MVP 验收记录](docs/mvp-acceptance.md)。没有真人反馈，不称为真人试玩通过；不对趣味性或最终平衡作已验证结论。

## 后续范围与维护

开发顺序继续为：状态 → 路线 → 完整回合与胜负 → 格子种类 → 卡牌 → 相遇战斗 → 角色技能 → 正式画面。当前只维护前三步 MVP，后续未授权。商店价格／内容、事件范围、传送规则、卡牌获取与效果、战斗点数与平局取整、角色技能等须在对应阶段明确。

长期协作约定见 [AGENTS.md](AGENTS.md)，`agent.md` 只是指向该文件。保留 UTF-8/LF、`.editorconfig`、`.gitattributes` 和 MIT 许可证。提交前检查暂存与未暂存变更、新文件和 `git diff --check`；只在用户明确要求时提交或推送。根项目下不再建立第二份 `project.godot`。

原卡牌拖拽示例来自 SesinIvan 的 smart-drag-and-drop-cards，原 MIT 许可证保留在 `asset/smart-drag-and-drop-cards/LICENSE`。本项目使用 [MIT License](LICENSE)。
