# game

游戏项目仓库，使用 Godot 4.6。

## 当前状态

- 默认分支：`main`，跟踪 GitHub 的 `origin/main`。
- 保留原有的 MIT 许可证与 Godot 忽略规则。
- 文本文件使用 UTF-8 和 LF 换行；Windows 批处理文件使用 CRLF。
- 引擎：Godot 4.6。唯一的工程文件是仓库根目录的 `project.godot`，所有人都打开这一份。
- 入口场景：`res://example/example.tscn`（卡牌拖拽示例）。

### 只保留一份 project.godot

Godot 会把含有 `project.godot` 的文件夹当成独立项目，根项目扫描时会跳过它。所以子目录里不要再放 `project.godot`，`.gitignore` 也已经忽略根目录以外的所有 `project.godot`。从别的工程拷内容进来时，只拷场景、脚本和素材；需要的项目设置（输入映射、窗口尺寸等）在根项目的"项目设置"里重新添加。

## 在这台电脑上使用

项目已经保存在：

```text
C:\Users\LENOVO\Documents\ChatGPT\game
```

在 PowerShell 中进入项目文件夹：

```powershell
Set-Location "C:\Users\LENOVO\Documents\ChatGPT\game"
```

查看 Git 版本、当前文件修改情况和关联的远程仓库：

```powershell
git --version
git status
git remote -v
```

这台电脑已经完成 Git 安装、仓库关联和本项目的提交身份配置，不需要重新初始化或重复克隆。如果新安装 Git 后提示找不到 `git`，请关闭并重新打开终端。

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
├── example/         卡牌拖拽示例（场景与脚本）
└── asset/           素材：Kenney 免费素材、像素素材等
    └── smart-drag-and-drop-cards/   卡牌示例的来源说明（LICENSE、README、演示 gif）
```

卡牌拖拽示例来自 SesinIvan 的 smart-drag-and-drop-cards，按 MIT 许可证使用，原许可证保留在 `asset/smart-drag-and-drop-cards/LICENSE`。

## 运行与后续开发

用 Godot 4.6 打开仓库根目录的 `project.godot`，按 F5 运行入口场景。首次打开会重新导入素材，需要等待一会儿。

目前还没有自动化测试或导出流程。后续还需要确定：

1. 游戏类型、核心玩法和目标平台。
2. 正式的入口场景（目前暂用卡牌示例）。
3. 测试和导出步骤，并将它们补充到本文件。

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
