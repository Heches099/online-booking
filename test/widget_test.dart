import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:online_booking/features/auth/presentation/pages/login_page.dart';
import 'package:online_booking/features/booking/presentation/pages/passenger_details_page.dart';
import 'package:online_booking/features/search/domain/entities/bus.dart';
import 'package:online_booking/features/search/presentation/pages/bus_results_page.dart';

void main() {
  test('ABC trip and seat metadata are included in bus serialization', () {
    final bus = Bus(
      id: 'abc-trip',
      name: 'ABC Upper Class',
      type: 'VVIP',
      departureTime: '07:00 AM',
      arrivalTime: '01:00 PM',
      duration: '6h',
      price: 55000,
      rating: 5,
      availableSeats: 45,
      amenities: const [],
      route: const ['Dar es Salaam', 'Dodoma'],
      operatorCode: 'abc',
      operatorTripId: 'abc-sub-id',
      abcFromId: 1,
      abcToId: 26,
      abcSeatIds: const {'Seat 10': 'L-2-3-10'},
    );

    final data = bus.toFirestore();

    expect(data['operatorTripId'], 'abc-sub-id');
    expect(data['abcFromId'], 1);
    expect(data['abcToId'], 26);
    expect(data['abcSeatIds'], {'Seat 10': 'L-2-3-10'});
  });

  group('Bus ABC checkout guards', () {
    Bus realAbcBus() => Bus(
          id: 'abc-trip',
          name: 'ABC Upper Class',
          type: 'VVIP',
          departureTime: '07:00 AM',
          arrivalTime: '01:00 PM',
          duration: '6h',
          price: 55000,
          rating: 5,
          availableSeats: 45,
          amenities: const [],
          route: const ['Dar es Salaam', 'Mbeya'],
          operatorCode: 'abc',
          operatorTripId: '1579063',
          abcFromId: 1,
          abcToId: 26,
          abcSeatIds: const {'A10': 'L-2-3-10'},
        );

    test('real ABC bus can checkout only with a mapped seat', () {
      final bus = realAbcBus();

      expect(bus.isABC, isTrue);
      expect(bus.isABCDemo, isFalse);
      expect(bus.canCheckoutABC('L-2-3-10'), isTrue);
      expect(bus.canCheckoutABC(null), isFalse);
      expect(bus.canCheckoutABC('  '), isFalse);
    });

    test('real ABC bus without trip IDs cannot checkout', () {
      final bus = Bus(
        id: 'abc-trip',
        name: 'ABC Upper Class',
        type: 'VVIP',
        departureTime: '07:00 AM',
        arrivalTime: '01:00 PM',
        duration: '6h',
        price: 55000,
        rating: 5,
        availableSeats: 45,
        amenities: const [],
        route: const ['Dar es Salaam', 'Mbeya'],
        operatorCode: 'abc',
      );

      expect(bus.isABC, isTrue);
      expect(bus.canCheckoutABC('L-2-3-10'), isFalse);
    });

    test('demo bus with ABC name never counts as real ABC', () {
      final bus = Bus(
        id: '4',
        name: 'ABC Luxury Coach',
        type: 'VVIP 1 Luxury',
        departureTime: '10:00 AM',
        arrivalTime: '06:00 PM',
        duration: '8h 00m',
        price: 45000,
        rating: 5.7,
        availableSeats: 54,
        amenities: const ['WiFi'],
        route: const ['Dar es Salaam', 'Mbeya'],
        operatorCode: 'demo',
        operatorTripId: '4',
      );

      expect(bus.isABC, isFalse);
      expect(bus.isABCDemo, isTrue);
      expect(bus.canCheckoutABC('L-2-3-10'), isFalse);
    });

    test('ordinary bus is neither ABC nor demo', () {
      final bus = Bus(
        id: '1',
        name: 'Kilimanjaro Express',
        type: 'Luxury AC Sleeper',
        departureTime: '06:00 AM',
        arrivalTime: '02:00 PM',
        duration: '8h 00m',
        price: 45000,
        rating: 4.9,
        availableSeats: 54,
        amenities: const ['WiFi'],
        route: const ['Dar es Salaam', 'Arusha'],
        operatorCode: 'demo',
        operatorTripId: '1',
      );

      expect(bus.isABC, isFalse);
      expect(bus.isABCDemo, isFalse);
      expect(bus.canCheckoutABC('L-2-3-10'), isFalse);
    });
  });

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

    for (final name in [
      'Kilimanjaro Express',
      'Abood Express',
      'Shabiby Express',
      'Tahmeed Coach',
    ]) {
      await tester.scrollUntilVisible(find.text(name), 500);
      expect(find.text(name), findsOneWidget);
    }
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
