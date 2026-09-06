import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_agent/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  tz.initializeTimeZones();

  testWidgets('app boots with correct bottom nav tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProductivityAgentApp());
    await tester.pump();

    // Verify bottom navigation tab labels exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('BCS'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });
}
