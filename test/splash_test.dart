import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_saver_client/pages/splash.dart';

void main() {

  Widget createWidgetForTesting({required Widget child}){
return MaterialApp(
  home: Scaffold(body:child),
);
}

  testWidgets('load splash page', (tester) async {
   
    await tester.pumpWidget(createWidgetForTesting(child: const Splash()));

    await tester.pumpAndSettle();
  });
}
