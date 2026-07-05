# flutter_amap_base_example

这个 example 把下面几类能力放进了一个页面里：

- 地图展示
- 驾车路线规划
- 地图路线绘制
- 嵌入式导航视图
- 底部卡片区域预留
- 调起原生导航

入口文件：

- `lib/main.dart`

## 运行前配置

### Android

在 `android/app/src/main/AndroidManifest.xml` 中把下面占位值替换成你的高德 Key：

```xml
<meta-data
    android:name="com.amap.api.v2.apikey"
    android:value="YOUR_AMAP_ANDROID_KEY" />
```

### iOS

运行前请先在代码里调用：

```dart
await AMap.init('YOUR_AMAP_IOS_KEY');
```

当前插件 README 里提到 iOS 需要打开 `UiKitView` 预览开关，这个 example 已经在 `ios/Runner/Info.plist` 里加好了：

```xml
<key>io.flutter.embedded_views_preview</key>
<true/>
```

## 启动

```bash
cd example
flutter pub get
flutter run
```

## 说明

- 示例里使用的是固定起终点坐标，方便直接验证路线规划和导航流程。
- “自定义底部卡片”这里演示的是 Flutter 自己绘制底部卡片，并通过 `bottomContentH` 给导航视图预留底部区域。
- 如果你希望我继续补成“可直接发版级”的 example，我下一步可以把 iOS 的 `AMap.init(...)` 初始化入口也一并接到示例代码里。
