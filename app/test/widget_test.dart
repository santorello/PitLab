import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitlap_app/app/bootstrap/bootstrap.dart';

void main() {
  testWidgets('renders PitLap shell', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PitLapBootstrap()),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Piste').evaluate().isNotEmpty ||
          find.text('Tracks').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(Directionality), findsWidgets);
  });
}
