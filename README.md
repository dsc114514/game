# game

游戏项目仓库，使用 Godot 4.6。

## 当前状态

- 默认分支：`main`，跟踪 GitHub 的 `origin/main`。
- 保留原有的 MIT 许可证与 Godot 忽略规则。
- 文本文件使用 UTF-8 和 LF 换行；Windows 批处理文件使用 CRLF。
- 引擎：Godot 4.6。唯一的工程文件是仓库根目录的 `project.godot`，所有人都打开这一份。
- 当前入口场景：`res://example/board/game.tscn`（2～4 人本机轮流操作的 MVP 完整回合）。静态路线预览保留在 `res://example/board/route_preview.tscn`，原卡牌示例保留在 `res://example/example.tscn`。

### 独立历史的 MVP 分享分支

`codex-example` 是孤儿分支：从已验收的英文 MVP 完整文件快照开始，首个提交没有父提交，不包含原项目的提交历史。它仍位于 `dsc114514/game` 仓库中，供同事单独获取和运行。分支名使用连字符，因为 Git 不允许分支名含空格。

```sh
git clone --single-branch --branch codex-example https://github.com/dsc114514/game.git game-mvp
```

打开 `game-mvp/project.godot`，使用 Godot 4.6 按 F5 运行；玩法界面保持英文。下文旧工作区与验收记录作为开发记录保留。

### 只保留一份 project.godot

Godot 会把含有 `project.godot` 的文件夹当成独立项目，根项目扫描时会跳过它。所以子目录里不要再放 `project.godot`，`.gitignore` 也已经忽略根目录以外的所有 `project.godot`。从别的工程拷内容进来时，只拷场景、脚本和素材；需要的项目设置（输入映射、窗口尺寸等）在根项目的"项目设置"里重新添加。

## 在这台电脑上使用

项目已经保存在：

```text
E:\Documents\ChatGPT\game
```

在 PowerShell 中进入项目文件夹：

```powershell
Set-Location "E:\Documents\ChatGPT\game"
```

查看 Git 版本、当前文件修改情况和关联的远程仓库：

```powershell
git --version
git status
git remote -v
```

这台电脑已经完成 Git 安装、仓库关联和本项目的提交身份配置，不需要重新初始化或重复克隆。如果新安装 Git 后提示找不到 `git`，请关闭并重新打开终端。

使用独立 Git worktree 时，进入对应工作区并打开其中根目录的 `project.godot`；各工作区共享 Git 历史，不需要再次初始化仓库。

当前 MVP 工作区为 `C:\Users\Administrator\.codex\worktrees\match-state-mvp\game`，分支为 `codex/match-state-mvp`。一局状态、路线数据、回合控制、占位界面和验证脚本位于该工作区的 `example/`。在 `example/` 内执行 Git 命令也使用 `game` 根目录的同一仓库和当前分支；`.git` 工作区关联文件及唯一的 `project.godot` 均留在 `game` 根目录。`E:\Documents\ChatGPT\example` 是另一个空仓库，不是本 MVP 工程，不在其中重复创建项目。

## 项目文件

```text
game/
├── .git/            本地版本记录与仓库配置，请勿手动删除
├── AGENTS.md        后续 agent 的项目协作约定
├── agent.md         指向协作约定的交接入口
├── .editorconfig    编辑器的编码、缩进和换行约定
├── .gitattributes   Git 的文本换行规则
├── .gitignore       不纳入版本管理的文件规则
├── LICENSE          MIT 许可证
├── README.md        本项目说明
├── project.godot    唯一的 Godot 工程文件
├── icon.svg         项目图标
├── control.tscn     测试场景
├── example/         原卡牌拖拽示例，以及 MVP 状态、路线和验证
│   ├── card/        原有卡牌示例脚本与场景
│   ├── field/       原有卡牌示例场地
│   ├── example.tscn 原卡牌示例入口（可单独 F6 运行）
│   ├── gameplay/    与显示无关的规则和路线数据
│   │   ├── mvp_rules.gd
│   │   ├── match_state.gd
│   │   ├── route_data.gd
│   │   └── turn_controller.gd   掷骰、移动、等待选择、结算与轮换
│   ├── board/       路线预览与本机轮流操作界面
│   │   ├── route_layout.gd       独立整数显示坐标
│   │   ├── route_preview.gd      按数据绘制节点、ID、类型与箭头
│   │   ├── route_preview.tscn    静态预览（可单独 F6 运行）
│   │   ├── game.gd              最少控件、玩家色块、HUD 与日志
│   │   ├── game.tscn            当前 F5 入口
│   │   └── placeholder_font.*   自制 5×7 调试位图字体，无外部字体依赖
│   └── tests/       无第三方依赖的 Godot 命令行验证
│       ├── match_state_test.gd
│       ├── route_data_test.gd
│       ├── route_preview_test.gd
│       ├── turn_controller_test.gd
│       └── game_ui_test.gd
├── scenes/          已有 card_face 卡面样板
└── asset/           素材：Kenney 免费素材、像素素材等
    └── smart-drag-and-drop-cards/   卡牌示例的来源说明（LICENSE、README、演示 gif）
```

卡牌拖拽示例来自 SesinIvan 的 smart-drag-and-drop-cards，按 MIT 许可证使用，原许可证保留在 `asset/smart-drag-and-drop-cards/LICENSE`。

## 运行与后续开发

用 Godot 4.6 打开仓库根目录的 `project.godot`，按 F5 运行入口场景。首次打开会重新导入素材，需要等待一会儿。

一局状态、路线、回合和界面已有下述验证脚本，尚无导出流程。已确定的方向：

1. 玩法是 2D 桌面棋盘对决，类似大富翁。视觉是正交顶视像素，网格、调色板和交互约束见 `AGENTS.md`。
2. F5 运行本机轮流操作界面，支持从 2～4 人开局到胜利；正式美术尚未制作。
3. 调色板色值、设计分辨率和导出步骤尚未锁定。

### 玩法与开发路线

以下为已确定的开发顺序和阶段验收目标。当前完成第 1～3 步，具体范围和验证见下文，第 4～8 步未继续开发。现有 `scenes/card_face.tscn` 是卡面样板，不代表正式卡牌系统已经实现。

| 顺序 | 阶段 | 范围与验收目标 |
| --- | --- | --- |
| 1 | 一局的状态（已完成） | 支持 2 到 4 人，玩家只记录位置、钱、星；实现开局、合法金钱变更、停留兑换、返抵胜利和玩家轮换。已用 Godot 无窗口脚本验证；不包含路线或完整回合界面。 |
| 2 | 一条能走完的路线（已完成） | 23 格固定有向循环，包含双出口岔路、汇合、出生点、停留点、金币、商店、事件。连接与整数显示坐标分离；Godot 中已验证图数据、错误诊断与占位显示。未接入玩家移动或完整回合。 |
| 3 | 一个回合走完（已完成） | 接通本机 2～4 人开局、随机掷骰、逐格移动、岔路等待、唯一落点结算、金币奖励、可选兑换、顺序轮换及达标后返抵胜利。真实 Godot 图形模式中已通过场景按钮从零开局运行到玩家 2 获胜；无网络或 AI。 |
| 4 | 格子种类补全 | 在已有回合上补齐商店、随机事件和传送，验证处理后能够继续或正常结束回合。此阶段仍不加入手牌。 |
| 5 | 卡牌 | 先实现手里有牌、自己回合打出、效果作用到人。仅开放掷骰前和移动后两个出牌时机，验证持有、打出和效果结算。现有卡面可用于展示，但不能代替玩法实现。 |
| 6 | 相遇战斗 | 在回合和卡牌已存在的基础上，路过其他玩家时可以选打或放过；战斗比点数，胜者取得对方一半的钱。验证选择、结算及后续回合继续执行。 |
| 7 | 角色技能 | 每人一个主动或被动技能，接到已有的出牌时机和战斗上，验证触发与效果。 |
| 8 | 画面 | 规则能运行后，再整合正式棋盘、棋子、骰子和最少 HUD。遵守 `AGENTS.md` 的正交像素网格约定，并验证完整路线、当前棋子和必要信息能同时看见。 |

第 3 步完成前不做卡牌系统或时点系统，第 4 步仍不加入手牌。第 5 步也不先建通用时点系统；只有实际出现同一张牌需要在多个时机打出时，才把已经用到的时机整理成一张表。

第 1 到第 7 步允许为运行规则添加必要的占位显示、操作控件和日志；正式画面在第 8 步制作。已有卡牌样板不改变这个顺序。

### MVP 暂定规则

以下规则用于验证闭环，集中在 [`example/gameplay/mvp_rules.gd`](example/gameplay/mvp_rules.gd)，不是最终平衡方案：

| 配置 | 暂定值 |
| --- | --- |
| 对局人数 | 2、3、4 人 |
| 初始金钱 / 初始星数 | 0 / 0 |
| 骰子范围 | 1～6，正常玩法使用独立随机数生成器 |
| 金币格落点奖励 | 10 金钱，仅步数走完的落点发放一次 |
| 兑换费用 | 20 金钱换 1 星，每次停留最多兑换一次，可以不兑换 |
| 目标星数 | 3 |
| 出生点 ID | `spawn` |
| 停留点 / 中心点 ID | `center`，与出生点分开 |

只有走完步数后的落点触发格子；路过不触发，也不强制停下。停留点结算先检查进入本次结算前的星数：已有至少 3 星则获胜，不再扣兑换费；否则允许兑换。本次兑换刚达到 3 星不立即获胜，必须离开后再次落在停留点。多个玩家可以处于同一格，不触发战斗。商店格和事件格落点只输出日志；出生点、普通格和岔路落点无奖励。只有金币格落点加钱。

### 第 1 步实际完成情况与接口

`example/gameplay/match_state.gd` 是独立于场景的 `RefCounted`。每名玩家只有 `position`（格子 ID）、`money`、`stars`，身份是玩家数组索引。对局内部保存玩家数组、当前玩家索引、赢家索引、流程阶段和停留编号；结束状态由阶段得出。`get_snapshot()` 返回深拷贝，包含这些可读状态，不能通过改写快照来改动对局。下划线成员仅供内部使用，调用方通过以下方法操作：

| 方法 | 行为 |
| --- | --- |
| `start_game(player_count)` | 仅未开局时接受 2～4 人，玩家 0 先行动。新一局使用新实例，不能覆盖进行中或已结束的对局。 |
| `change_money(player_index, amount)` | 有效索引可收款或支出，拒绝负余额和 int64 溢出；失败无副作用。 |
| `move_current_player_to(tile_id)` | 记录当前玩家移动到另一个非空格子 ID，可多次调用表示逐格移动；不结算路过格子。状态层自身不校验连接或步数，第 3 步由回合层保证。 |
| `settle_landing()` | 至少移动一次后才能调用，一次移动过程只结算一次；普通格结束结算，停留点先判胜再开放兑换。 |
| `exchange_star(visit_id)` | 从当前停留快照取得 `stop_visit_id` 并提交。足额时扣费、加一星、结束结算；不足时保持状态。重复兑换或过期编号会被拒绝。 |
| `end_turn()` | 已结算后轮换到下一人；停留点尚未兑换时调用表示放弃兑换。未移动或未结算时拒绝轮换。 |

所有操作返回 `bool`；`false` 表示请求被拒绝且整局不变。结束后拒绝全部修改操作。停留编号只在等待兑换时通过快照开放，其他阶段为 `-1`。不能原地反复结算：兑换后必须先结束回合，之后实际移动离开停留点，再返回并结算，才可能获胜。

最小调用示例（在脚本中执行，不需要场景）：

```gdscript
const MatchState = preload("res://example/gameplay/match_state.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")

func example() -> void:
	var game = MatchState.new()
	game.start_game(2)
	game.change_money(0, Rules.STAR_COST)
	game.move_current_player_to(Rules.STOP_TILE_ID)
	game.settle_landing()
	var visit_id: int = game.get_snapshot().stop_visit_id
	game.exchange_star(visit_id)
	game.end_turn()
```

第 1 步只实现上述规则层，不含路线与界面。第 3 步通过回合控制器接入合法路线与步数约束，原状态 API 保持不变。玩法界面使用回合控制器，不直接调用低层状态接口。

### 第 2 步路线结构与占位预览

路线规则由 [`example/gameplay/route_data.gd`](example/gameplay/route_data.gd) 的 `get_tiles()` 返回，共 23 格、24 条有向连接。每格仅记录 `id`、`type`、`next`（合法出口 ID 数组）。普通格恰好一个出口，`branch` 格至少两个不同出口；此测试路线仅 `fork` 为岔路，`merge` 为单出口、双入口的汇合点。

```text
spawn → c01 → fork
               ├→ a01 → shop01  → a02 ┐
               └→ b01 → event01 → b02 ┴→ merge → center
center → c02 → shop02 → event02 → c03 → p01 → c04 → p02
       → c05 → p03 → c06 → p04 → p05 → spawn → …
```

| 类型 | 格子 ID |
| --- | --- |
| 出生点 `spawn` | `spawn` |
| 中心／停留点 `stop` | `center`，沿用 `mvp_rules.gd` 的 ID |
| 岔路 `branch` | `fork`，出口为 `a01`、`b01` |
| 金币 `coin` | `c01`、`a01`、`b02`、`c02`、`c03`、`c04`、`c05`、`c06` |
| 商店 `shop` | `shop01`、`shop02`，只表示类型 |
| 事件 `event` | `event01`、`event02`，只表示类型 |
| 普通 `path` | `a02`、`b01`、`merge`、`p01`～`p05` |

[`example/board/route_layout.gd`](example/board/route_layout.gd) 单独保存 ID 到 `Vector2i` 网格坐标的映射；改坐标不改变连接，不通过屏幕距离或相邻方向推导出口。规则数据和布局均返回独立副本。现有玩家 `position` 继续保存格子 ID，状态层不保存屏幕位置。

路线预览先校验数据，再生成 23 个标签和 24 条带方向箭头的连线。节点显示 ID 与类型（ASCII 大写仅用于位图字体显示，规则 ID 保持原值）。采用正交顶视、整数坐标、Nearest 和整数倍拉伸，不使用正式地图素材。第 2 步视口为 1152×720，第 3 步为容纳操作、状态和日志调整为 1152×896，网格坐标与连接不变。原卡牌示例和 `card_face` 均保留。字体是第 2 步自制的 5×7 调试字形，以原生 8px 字号的两倍显示，不是正式字体或美术方案。

`RouteData.validate(tiles)` 返回错误字符串数组；空数组表示校验通过。检查 ID 唯一、目标存在、必需出生／停留点及类型、出口数量、重复出口、自连接和基本数据格式；从出生点遍历检查所有格子可达，再从停留点反向遍历检查每格都能走到停留点，包含无法返回的封闭子环。另检查停留点确实能离开后再次返回。`RouteLayout.validate()` 检查缺失、重叠、非整数与多余坐标。预览遇到校验错误会停止生成棋盘，画面提示 `ROUTE INVALID - SEE ERROR OUTPUT`，Godot 错误输出列出具体格子 ID 和原因，例如 `格子 c01 连接到不存在的目标: missing`。

静态预览自身不启动对局；第 3 步玩法场景复用棋盘，并隐藏静态预览的说明文字。

### 第 3 步：操作与复现

在上文 MVP 工作区用 Godot 4.6 打开根目录 `project.godot`，按 F5：

1. 点击 `START 2`、`START 3` 或 `START 4` 开局。每人初始金钱 0、星数 0、位置 `spawn`。
2. 当前玩家点击 `ROLL`，随机取得 1～6。每 0.18 秒沿一条连接跳到下一格并消耗一步，移动期间掷骰按钮禁用。
3. 若尚有步数且当前格有多个出口，暂停显示 `TO A01`、`TO B01`。选择后沿该连接消耗一步，用余下步数继续；若恰好零步停在 `fork`，直接结算，不要求预选下一回合的路。
4. 普通落点自动结算并切换下一人。落到中心时保留当前玩家，足额可点 `EXCHANGE 20` 兑换一星，或点 `SKIP` 放弃；余额不足时兑换禁用，仍可放弃。两种决定都结束回合。
5. 已有至少三颗星的玩家再次准确落在中心时立即获胜，显示 `P<n> WINS / GAME OVER`；不再扣钱、不再换人，所有行动控件禁用。刚兑换第三星仍需离开中心后再落回来。

顶部显示当前玩家、骰子结果和余步，以及每人的金钱、星数、格子 ID；当前玩家同时有 `CURRENT` 文字标记。待掷骰显示 `DICE -`，避免把上一人的结果当作本次点数；胜利画面仍保留最终骰子和余步。棋盘下方的 32×32 色块和数字代表玩家，同格时按玩家编号使用 32px 整数偏移，不相互覆盖或遮住格子 ID、类型。下方显示最近 7 行日志，控制器保留最近 128 行。界面使用英文短文本匹配已有调试位图字体。

操作区上方始终显示当前应做什么：开局选择人数、点击掷骰、移动时等待、在合法出口中选路、兑换或放弃、获胜后重开。余额不足会显示需要多少金钱、当前余额，并提示点击 `SKIP`。所有不合法按钮均禁用，只有当前阶段的出口按钮存在，不靠颜色表达下一步。费用、目标星数和“最后一星兑换后必须离开并再次落在中心、路过不获胜”的暂定规则常驻操作区下方。

获胜后点击 `NEW GAME` 返回人数选择，再点击 `START 2/3/4` 开始新局，无需退出 Godot。只有获胜后可重开；新局使用全新的回合控制器，清空所有玩家、位置、金钱、星数、当前人、赢家、骰子、余步、回合数、待选出口、停留兑换编号和日志，移动计时归零。旧局回调携带局编号，重开后即使新旧等待编号相同，也不能用旧按钮请求选路、兑换、掷骰或再次重开。

正常 F5 只开放随机骰子。复现时使用显式测试入口：

~~~powershell
godot --path . -- --test-dice
~~~

这会额外显示 `TEST DICE` 和 `1`～`6` 六个按钮；每次仅为当前待掷骰回合指定一次合法点数，`ROLL` 仍是随机骰子。测试按钮与正常骰子共享相同的阶段、编号和步数校验，移动或等待选择期间均禁用。没有加钱、加星、改位置或自动玩家功能。

完整复现方法：两人开局，每回合都点测试骰子 `1`，从 `fork` 出发时选 `TO A01`，玩家 1 每次中心选择 `SKIP`，玩家 2 每次中心选择 `EXCHANGE 20`。玩家 2 第一次到中心可从真实金币格获得恰好 20；第三次购买后继续，第四次落在中心获胜。然后点 `NEW GAME`，改选四人并继续掷骰。全程不修改资金、星数或位置。正常随机骰子走相同回合流程。

本轮必要界面属于现有闭环的操作与验收补齐，不是开发路线中的正式美术阶段。仍为 1152×896 正交占位棋盘，16px 控件网格、整数坐标和整数倍拉伸；根目录只有一个 `project.godot`，F5 入口为 `example/board/game.tscn`，卡牌示例保持分离。没有制作正式地图、角色动画、特效或新卡面，也没有继续开发第 4 步。

### 第 3 步回合接口

[`example/gameplay/turn_controller.gd`](example/gameplay/turn_controller.gd) 是与场景无关的 `RefCounted`，组合既有 `MatchState` 和经过校验的路线。流程为 `NOT_STARTED → WAITING_FOR_ROLL → MOVING ↔ WAITING_FOR_PATH → 落点结算 → WAITING_FOR_EXCHANGE / 下一人 WAITING_FOR_ROLL / FINISHED`。每次推进只走一条连接；选择本身也沿所选连接走一步。落点结算是内部动作，不暴露重复领奖按钮。

| 方法 | 说明 |
| --- | --- |
| `start_game(player_count)` | 仅未开局时接受 2～4 人；坏路线拒绝开局并在快照提供错误。 |
| `get_snapshot()` | 包含原玩家状态及 `turn_phase`、`turn_number`、`input_id`、`remaining_steps`、`last_roll`、`legal_exits`、`logs`、`errors`；均是副本。 |
| `roll_dice(input_id)` | 仅待掷骰阶段且编号匹配时取随机结果；重复或旧编号请求无副作用。 |
| `advance()` | 仅移动阶段沿唯一出口走一步，零步立即结算；等待选路、兑换或结束时拒绝。 |
| `choose_path(target, input_id)` | 仅接受本次等待的合法出口。每次岔路等待均换编号，连续岔路不能复用上次选择。 |
| `exchange_star(input_id)` / `skip_exchange(input_id)` | 仅接受当前停留决策。兑换复用状态层的停留编号和先判胜规则，成功后自动轮换；失败不改变回合。 |
| `roll_for_test(value, input_id)` | 仅 `TurnController.new(true)` 的测试实例可用，点数仍受配置限制。第二个可选构造参数仅在测试模式接受小型路线，用于验证连续岔路，不改变正常棋盘。 |

界面 [`example/board/game.gd`](example/board/game.gd) 只读取快照、提交操作并按时间调用 `advance()`；不自行改钱、星、位置或判胜。操作按钮绑定创建或刷新时的等待编号与界面局编号。所有无效规则请求返回 `false`，结束状态拒绝后续操作；`NEW GAME` 只在获胜后创建全新对局实例。内部结算同时受回合阶段和既有状态层阶段保护，重复结算不重复发钱、兑换或切换玩家。日志明确记录掷骰、主动选择的分支、落点 ID／类型、金币奖励金额和新余额、兑换扣费及新星数、放弃兑换和获胜。没有添加通用时点、效果插件、卡牌、战斗、技能、传送、完整商店或随机事件系统。

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

### 后续阶段仍需明确的规则

- 商店出售的内容与价格、随机事件范围、传送目标规则；第 4 步不以手牌系统作为实现前提。
- 第 5 步的卡牌获取方式、具体卡牌效果和使用后去向。
- 战斗点数的产生方式、平局处理，以及一半金钱遇到奇数时的取整规则。
- 各角色具体技能及主动或被动的选择。

以上未定项在对应阶段实现前明确并更新本节；不得把占位参数写成已确认规则。后续阶段完成后，在此记录实际完成情况和验证结果。

## 在其他电脑上获取项目

```sh
git clone https://github.com/dsc114514/game.git
cd game
```

在其他电脑上首次提交前，需要为那里的本地仓库设置提交身份（当前这台电脑已配置，不需要重复执行）：

```sh
git config --local user.name "你的名字"
git config --local user.email "你的提交邮箱"
```

这些设置只影响当前电脑上的此仓库，不会随克隆同步给其他人。

## 日常协作

开始工作前，在工作区干净时同步远程更新：

```sh
git pull --ff-only
```

提交前先检查变更，确认没有密码、密钥或无关文件，再添加需要的文件：

```sh
git status
git diff
git add <需要提交的文件>
git diff --cached
git commit -m "说明本次修改"
git push
```

较大的功能可以使用独立分支：

```sh
git switch -c feature/功能名称
# 完成功能并提交后：
git push -u origin HEAD
```

## Agent 加入项目

后续 agent 从当前项目根目录开始工作时，请先阅读 [AGENTS.md](AGENTS.md)，再阅读本文件。用户指定的 [agent.md](agent.md) 也会指向同一份协作说明。

交接说明包含当前项目状态、开始工作的检查步骤、编码约定、Git 安全边界、验证方法与后续待办。已有的本地修改应当保留；只有得到明确授权后才提交或推送。

## 配置文件

| 文件 | 用途 |
| --- | --- |
| `AGENTS.md` | agent 的项目协作规则与交接信息 |
| `agent.md` | 指向完整工作说明的入口 |
| `.gitignore` | 排除 Godot 缓存、本地环境配置、构建产物和常见临时文件 |
| `.gitattributes` | 统一跨平台换行，避免无意义的整文件差异 |
| `.editorconfig` | 约定编码、换行和缩进；GDScript 使用制表符 |
| `LICENSE` | MIT 许可证 |

## 安全注意

- 不要提交访问令牌、密码、私钥或包含真实凭据的配置文件。
- `.env` 和 `.env.*` 默认忽略；可提交不含真实凭据的 `.env.example` 或 `.env.*.example`。
- `.gitignore` 不会自动移除已经被跟踪的敏感文件；如果凭据泄露，应立即撤销或更换。
- 游戏素材和源码应按需纳入版本管理；大型二进制素材引入后，再评估是否配置 Git LFS。

## 许可证

本项目使用 [MIT License](LICENSE)。
