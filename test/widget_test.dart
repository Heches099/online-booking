import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:online_booking/features/auth/presentation/pages/login_page.dart';
import 'package:online_booking/features/booking/presentation/pages/passenger_details_page.dart';
import 'package:online_booking/features/search/domain/entities/bus.dart';
import 'package:online_booking/features/search/presentation/pages/bus_results_page.dart';

void main() {
  testWidgets('login page renders auth actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });

  testWidgets('passenger details opens after a seat is selected',
      (WidgetTester tester) async {
    final bus = Bus(
      id: 'test-bus',
      name: 'Test Coach',
      type: 'Executive',
      departureTime: '08:00 AM',
      arrivalTime: '02:00 PM',
      duration: '6h',
      price: 45000,
      rating: 4.5,
      availableSeats: 54,
      amenities: const [],
      route: const ['Dar es Salaam', 'Arusha'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PassengerDetailsPage(
          bus: bus,
          selectedSeats: const ['Seat 1'],
          travelDate: DateTime(2026, 10, 10),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PASSENGER INFO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bus results keeps the default demo provider',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BusResultsPage(
          from: 'Dar es Salaam',
          to: 'Arusha',
          date: DateTime(2026, 10, 10),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kilimanjaro Express'), findsOneWidget);
    expect(find.text('Tahmeed Coach'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment provider logo assets render',
      (WidgetTester tester) async {
    const logos = [
      'assets/images/m_pesa.png',
      'assets/images/mixx-by-yas.png',
      'assets/images/halopesa.png',
      'assets/images/Nmb_logo.jpg',
      'assets/images/Logo-crdb-bank-tanzania-clipart-PNG.avif',
    ];

    for (final logo in logos) {
      await tester.pumpWidget(
        MaterialApp(home: Image.asset(logo, width: 60, height: 60)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: logo);
    }
  });
}
