# time-bar

macOS 常驻菜单栏时钟，支持自定义时区（如美国洛杉矶时间）。

## 功能

- 菜单栏显示所选时区的时间，可选显示城市名、秒、12/24 小时制
- 下拉菜单实时显示所有已添加时区的时间与日期
- 内置常用城市预设，也可输入任意 IANA 时区标识（如 `America/Los_Angeles`）
- 点击某个时区即可将其设为菜单栏显示
- 开机自启动（需用 `.app` 运行）
- 无 Dock 图标，设置保存在 UserDefaults

## 构建与运行

```sh
./scripts/build-app.sh      # 生成 build/TimeBar.app
open build/TimeBar.app
```

开发时也可直接 `swift run --build-system native`。

要求：macOS 13+，Xcode Command Line Tools（Swift 5.9+）。

## 许可证

[MIT](LICENSE)
