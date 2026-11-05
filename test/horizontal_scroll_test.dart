import 'package:appmobi/core/app_scroll_behavior.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Có thể kéo các hàng danh mục bằng chuột', (tester) async {
    final tabsController = ScrollController();
    final filtersController = ScrollController();
    addTearDown(tabsController.dispose);
    addTearDown(filtersController.dispose);

    await tester.pumpWidget(MaterialApp(
      scrollBehavior: const AppScrollBehavior(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    key: const Key('tabs'),
                    controller: tabsController,
                    scrollDirection: Axis.horizontal,
                    children: List.generate(
                      8,
                      (index) => SizedBox(
                        width: 120,
                        child: Center(child: Text('Tab $index')),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  key: const Key('filters'),
                  controller: filtersController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      8,
                      (index) => SizedBox(
                        width: 120,
                        child: Center(child: Text('Bộ lọc $index')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    await tester.drag(find.byKey(const Key('tabs')), const Offset(-240, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(tabsController.offset, greaterThan(0));

    await tester.drag(find.byKey(const Key('filters')), const Offset(-240, 0),
        kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(filtersController.offset, greaterThan(0));
  });
}
