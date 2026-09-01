# Kity 权限标签与菜单图标尺寸设计

## 目标

删除 macOS 辅助功能设置中缓存的 `NotesEnglishShadow` 旧授权记录，并将 Kity 菜单栏彩色猫粮图标从 22pt 调整为 20pt。

## 根因

已安装应用的 `CFBundleDisplayName`、`CFBundleName` 均为 `Kity`，标识符为 `org.xiaozhu.NotesEnglishShadow`。系统设置中的旧名称来自 TCC（辅助功能权限）数据库在旧名称时期创建的缓存记录；删除应用包或更改显示名称不会自动刷新这条授权记录。

## 方案

执行 `tccutil reset Accessibility org.xiaozhu.NotesEnglishShadow`，只重置该标识符的辅助功能授权。重新启动 Kity 后，用户在系统设置中重新启用一次 Kity；系统会基于当前包信息登记为 Kity。修改 `MenuBarIconConfiguration.default.size` 为 20×20，运行全量测试、构建、签名并替换应用。

## 验收

- 系统设置的辅助功能列表不再保留旧 `NotesEnglishShadow` 记录。
- Kity 重新授权后可读取 Apple Notes。
- 菜单栏图标为彩色且为 20pt。
