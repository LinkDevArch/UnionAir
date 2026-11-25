import '../domain/travel.dart';

class FlightService {
  FlightService({DateTime? today}) : today = dateOnly(today ?? DateTime.now());

  final DateTime today;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime daysFromToday(int days) =>
      DateTime(today.year, today.month, today.day + days);

  DateTime get demoDeparture {
    final figmaDate = DateTime(2026, 12, 23);
    return figmaDate.isAfter(daysFromToday(7)) ? figmaDate : daysFromToday(14);
  }

  DateTime get demoReturn =>
      DateTime(demoDeparture.year, demoDeparture.month, demoDeparture.day + 16);

  late final List<Offer> offers = List.unmodifiable([
    Offer(
      Airport.cali,
      Airport.medellin,
      daysFromToday(11),
      359900,
      'cali-medellin.png',
    ),
    Offer(
      Airport.bogota,
      Airport.cartagena,
      daysFromToday(15),
      459900,
      'bogota-cartagena.png',
    ),
    Offer(
      Airport.medellin,
      Airport.barranquilla,
      daysFromToday(9),
      359900,
      'medellin-barranquilla.png',
    ),
    Offer(
      Airport.bogota,
      Airport.cali,
      daysFromToday(17),
      459900,
      'bogota-cali.jpg',
    ),
  ]);

  static const _routes = [
    (Airport.cali, Airport.bogota, 189900),
    (Airport.cali, Airport.medellin, 359900),
    (Airport.bogota, Airport.cartagena, 459900),
    (Airport.medellin, Airport.barranquilla, 359900),
  ];

  static const _outboundTimes = [
    ('06:20', '07:25', '1h 05m', Fare.basic, 0),
    ('10:10', '11:18', '1h 08m', Fare.plus, 40000),
    ('18:45', '19:52', '1h 07m', Fare.flex, 90000),
  ];
  static const _returnTimes = [
    ('07:55', '09:00', '1h 05m', Fare.basic, 0),
    ('17:40', '18:48', '1h 08m', Fare.plus, 40000),
    ('20:15', '21:22', '1h 07m', Fare.flex, 90000),
  ];

  List<Flight> search(FlightQuery query, {bool returning = false}) {
    final date = returning ? query.returnDate : query.departure;
    if (date == null || query.validate(today) != null) return [];
    final origin = returning ? query.destination : query.origin;
    final destination = returning ? query.origin : query.destination;
    final route = _routes
        .where(
          (route) =>
              (route.$1 == origin && route.$2 == destination) ||
              (route.$2 == origin && route.$1 == destination),
        )
        .firstOrNull;
    if (route == null || date.isAfter(daysFromToday(120))) return [];

    final times = returning ? _returnTimes : _outboundTimes;
    return [
      for (final (index, time) in times.indexed)
        Flight(
          code:
              'UA-${origin.code}${destination.code}${query.travelClass.index}$index',
          origin: origin,
          destination: destination,
          date: date,
          departure: time.$1,
          arrival: time.$2,
          duration: time.$3,
          basePrice:
              route.$3 +
              time.$5 +
              (query.travelClass == Cabin.business ? 180000 : 0),
          recommendedFare: time.$4,
          travelClass: query.travelClass,
        ),
    ];
  }
}
