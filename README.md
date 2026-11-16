# QuietType

**一个安静的 macOS 悬浮打字练习条。**

只显示当前词和下一个词，输入时即时标记正误，完整输入后自动换词。窗口紧凑、可拖动，可以藏到菜单栏，适合随手练习。

A minimal, offline macOS typing practice bar built with Swift and AppKit. Includes separate English and Chinese IME editions.

## 两个独立版本

| 版本 | 特点 | 源码 |
| --- | --- | --- |
| English v1.0 | 英文词语练习；正确字母变绿，错误字母变红并需退格修正 | [english/](english/) |
| 中文 v1.0 | 中文词语与短语；支持系统输入法组合、候选窗口与数字选词 | [chinese/](chinese/) |

两版使用不同的应用名与 Bundle ID，可以同时保留。英文版沿用已冻结的 v1.0 源码，中文版独立维护。

## 构建与运行

需要 **macOS 13+** 和 **Xcode Command Line Tools**（提供 `swiftc`）。无需第三方依赖或 API key。

```bash
git clone https://github.com/wlbwmykgua/quiettype.git
cd quiettype

# 英文版
zsh english/build.sh
open english/build/QuietType.app

# 中文版
zsh chinese/build.sh
open "chinese/build/QuietType 中文.app"
```

脚本在各版的 `build/` 目录生成应用并进行本机 ad-hoc 签名，不会自动安装到 `/Applications`。需要安装时，可自行把构建产物复制到应用程序目录。

## 操作

- 点击练习条后输入；当前词全部正确时自动前进。
- 错字会保留，以 Backspace 手动删除后再输入。
- 拖动窗口调整位置。
- `Esc` 隐藏；菜单栏图标左键显示 / 隐藏，右键打开菜单。
- 中文版由 macOS 输入法处理拼音组合和候选词选择。

## 实现与范围

- 原生 Swift + AppKit，词库随源码内置，离线运行。
- 中文版通过 `NSTextInputClient` 配合系统输入法。
- 保存窗口位置等本地偏好；不提供账户、云同步、联网模型或排行榜。
- 本仓库发布源码，不提供已公证的通用二进制安装包。构建结果使用当前机器的默认架构。

## 验证

修改后分别运行两个构建脚本，再检查：正确输入自动换词、错误字符与退格、隐藏 / 恢复、拖动，以及中文输入法组合和候选窗口。编译通过不代替这些交互检查。
