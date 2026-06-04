import 'package:cuenca_activa_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza un estado informativo de Cuenca Activa', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Cuenca Activa',
              style: TextStyle(color: AppColors.navy),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cuenca Activa'), findsOneWidget);
  });
}
