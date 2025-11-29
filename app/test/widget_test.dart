// // Farm Disease Detection App Widget Tests

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:dowa/main.dart';

// void main() {
//   testWidgets('App should load without errors', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());
//     await tester.pumpAndSettle();

//     // Verify that the app loads without throwing exceptions
//     // The app should show either login screen or home screen based on auth state
//     expect(tester.takeException(), isNull);
//   });

//   testWidgets('App should have MaterialApp', (WidgetTester tester) async {
//     await tester.pumpWidget(const MyApp());
    
//     // Verify that MaterialApp is present
//     expect(find.byType(MaterialApp), findsOneWidget);
//   });
// }
