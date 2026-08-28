import 'package:flutter_test/flutter_test.dart';
import 'package:jagx_ai/features/auth/auth_service.dart';
import 'package:jagx_ai/main.dart';

void main() {
  testWidgets('JagX shell loads', (tester) async {
    final auth = AuthService();
    await tester.pumpWidget(JagxApp(auth: auth));
    expect(find.textContaining('JagX'), findsWidgets);
  });
}
