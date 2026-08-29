import 'package:flutter_test/flutter_test.dart';
import 'package:jagx_ai/main.dart';

void main() {
  testWidgets('JagX shell loads', (tester) async {
    await tester.pumpWidget(const JagxApp());
    await tester.pump();
    expect(find.textContaining('JagX'), findsWidgets);
  });
}
