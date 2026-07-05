import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_amap_base_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _setupAmapPlatformMocks();
  });

  tearDown(() async {
    await _clearPlatformMocks();
  });

  testWidgets('启动时展示 SDK 加载界面', (WidgetTester tester) async {
    await tester.pumpWidget(const AMapExampleApp());

    expect(find.text('正在初始化高德地图 SDK...'), findsOneWidget);
  });

  testWidgets('SDK 初始化完成后展示地图演示主界面', (WidgetTester tester) async {
    await tester.pumpWidget(const AMapExampleApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('地图与路线演示'), findsOneWidget);
    expect(find.text('线路规划'), findsOneWidget);
    expect(find.text('嵌入式导航'), findsOneWidget);
    expect(find.text('回到地图'), findsOneWidget);
  });
}

void _setupAmapPlatformMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('me.yohom/amap_base'),
    (MethodCall call) async {
      switch (call.method) {
        case 'setKey':
        case 'getBundleId':
          return 'com.example.test';
        default:
          return null;
      }
    },
  );

  messenger.setMockMethodCallHandler(
    const MethodChannel('me.yohom/location'),
    (MethodCall call) async {
      if (call.method == 'location#init') {
        return null;
      }
      return null;
    },
  );
}

Future<void> _clearPlatformMocks() async {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('me.yohom/amap_base'),
    null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('me.yohom/location'),
    null,
  );
}
