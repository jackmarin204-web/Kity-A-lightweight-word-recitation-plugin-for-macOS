# Kity

Kity 是一个面向 macOS“备忘录”的轻量菜单栏英语学习工具。你确认输入一个中文词或短语后，它会在光标旁显示英文提示。

[English README](README.md)

## 功能

- 仅支持苹果“备忘录”。
- 保留你原有的中文输入法，不接管键盘输入。
- 每次确认中文后，调用 macOS 已下载的中译英离线模型生成提示。
- 新词会直接覆盖上一张词卡。
- 不内置大词库，不发起网络请求，不修改备忘录内容，也不记录按键。

## 使用要求

- macOS 26 或更高版本。
- Xcode 26 或更高版本（仅开发/自行构建时需要）。
- 苹果“备忘录”。
- 为 Kity 授予“辅助功能”权限。
- 已下载简体中文和英语的系统翻译语言模型。

## 下载系统离线翻译模型

打开“系统设置 → 通用 → 语言与地区 → 翻译语言”，下载：

- 中文（简体）
- 英语

模型由 macOS 管理。下载完成后，Kity 可离线运行；模型不会被打包进 Kity，也不会上传你的文本。

## 构建与运行

1. 使用 Xcode 打开 `NotesEnglishShadow.xcodeproj`。
2. 在 App Target 中选择你的签名团队，并设置自己的 Bundle Identifier。
3. 构建并运行。
4. 前往“系统设置 → 隐私与安全性 → 辅助功能”，允许 Kity。

也可以在终端运行测试：

```sh
xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -destination 'platform=macOS'
```

## 隐私

Kity 只会在“备忘录”处于前台时工作。它仅临时读取光标前最多 48 个 UTF-16 字符，用于定位刚确认的中文；该文本不会写入磁盘。

Kity 不需要：

- 输入监控权限
- 屏幕录制权限
- 自动化权限
- 网络权限

英文提示由已下载的 macOS 系统翻译模型处理。

## 发布提醒

不要上传 `xcode-derived/`、`DerivedData/`、`.app`、证书、签名文件或任何个人备忘录内容。项目中的 `.gitignore` 已排除这些内容。

## 致谢与许可

可选旧词库数据及其来源说明保留在 `LICENSES/LEXICON-NOTICE.md` 中，用于归属与可复现性；当前纯系统翻译版本不会打包或查询该词库。

仓库尚未选择开源许可证。发布前如希望他人可以复用或贡献代码，请自行添加合适的许可证。

## 图标署名

<a href="https://www.flaticon.com/free-icons/cat-food" title="cat food icons">Cat food icons created by Magnific - Flaticon</a>
