# game

游戏项目仓库。当前已完成 Git 基础配置，尚未添加游戏工程或源码。

## 当前状态

- 默认分支：`main`，跟踪 GitHub 的 `origin/main`。
- 保留原有的 MIT 许可证与 Godot 忽略规则。
- 文本文件使用 UTF-8 和 LF 换行；Windows 批处理文件使用 CRLF。
- 尚未指定游戏引擎版本、入口场景、运行命令或构建方式。

现有 Godot 忽略规则不代表完整的 Godot 工程；创建实际工程后再补充运行说明。

## 获取项目

```sh
git clone https://github.com/dsc114514/game.git
cd game
```

首次提交前，为自己的本地仓库设置提交身份：

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

## 配置文件

| 文件 | 用途 |
| --- | --- |
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
