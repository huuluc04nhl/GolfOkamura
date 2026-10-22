import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_booking/core/router/app_router.dart';
import 'package:golf_booking/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GolfBookingApp smoke test', (WidgetTester tester) async {
    AppRouter.router.go('/');
    await tester.pumpWidget(const GolfBookingApp());
    await tester.pumpAndSettle();

    expect(find.byType(GolfBookingApp), findsOneWidget);
    expect(find.text('ĐẶT PHÒNG NGAY', skipOffstage: false), findsOneWidget);
  });
}
