import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutor_adaptativo_sabd/app.dart';

void main() {
  testWidgets(
    'entrar como estudiante de prueba abre la ruta del módulo 1',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: TutorAdaptativoApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Elige un perfil'), findsOneWidget);

      await tester.tap(find.text('Entrar como estudiante de prueba').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Hola,'), findsOneWidget);
      expect(find.text('Ajuste en tiempo real'), findsOneWidget);
    },
  );
}
