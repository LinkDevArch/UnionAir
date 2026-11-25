enum Airport {
  cali('Cali', 'CLO'),
  bogota('Bogotá', 'BOG'),
  medellin('Medellín', 'MDE'),
  cartagena('Cartagena', 'CTG'),
  barranquilla('Barranquilla', 'BAQ');

  const Airport(this.city, this.code);
  final String city;
  final String code;
  String get label => '$city ($code)';
}

enum Cabin {
  economy('Económica'),
  business('Ejecutiva');

  const Cabin(this.label);
  final String label;
}

enum Fare {
  basic('Basic', 0, [
    'Equipaje personal',
    'Cambios no incluidos',
    'Sin selección preferencial',
  ]),
  plus('Plus', 20000, [
    'Equipaje de mano',
    '1 maleta en bodega 23 kg',
    'Selección de asiento',
  ]),
  flex('Flex', 90000, [
    'Cambios permitidos',
    'Reembolso parcial',
    'Equipaje completo',
  ]);

  const Fare(this.label, this.surcharge, this.benefits);
  final String label;
  final int surcharge;
  final List<String> benefits;

  int price(Flight flight) => flight.basePrice + surcharge;
}

enum Baggage {
  none('Sin equipaje adicional', 0),
  checked('1 maleta en bodega 23 kg', 79900);

  const Baggage(this.label, this.price);
  final String label;
  final int price;
}

enum TripStatus {
  confirmed('Confirmada'),
  upcoming('Próximo'),
  completed('Completado'),
  canceled('Cancelada');

  const TripStatus(this.label);
  final String label;
}

class FlightQuery {
  const FlightQuery({
    required this.origin,
    required this.destination,
    required this.departure,
    required this.travelClass,
    this.returnDate,
  });

  final Airport origin;
  final Airport destination;
  final DateTime departure;
  final DateTime? returnDate;
  final Cabin travelClass;

  bool get roundTrip => returnDate != null;
  String get typeLabel => roundTrip ? 'Ida y vuelta' : 'Solo ida';

  String? validate(DateTime today) {
    if (origin == destination) {
      return 'Selecciona un origen y un destino distintos.';
    }
    if (departure.isBefore(today)) {
      return 'La salida no puede estar en el pasado.';
    }
    if (returnDate case final date? when !date.isAfter(departure)) {
      return 'El regreso debe ser posterior a la salida.';
    }
    return null;
  }
}

class Flight {
  const Flight({
    required this.code,
    required this.origin,
    required this.destination,
    required this.date,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.basePrice,
    required this.recommendedFare,
    required this.travelClass,
  });

  final String code;
  final Airport origin;
  final Airport destination;
  final DateTime date;
  final String departure;
  final String arrival;
  final String duration;
  final int basePrice;
  final Fare recommendedFare;
  final Cabin travelClass;

  DateTime get departureInstant {
    const colombiaUtcOffset = Duration(hours: -5);
    final time = departure.split(':');
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
      int.parse(time[0]),
      int.parse(time[1]),
    ).subtract(colombiaUtcOffset);
  }

  String get route => '${origin.label} → ${destination.label}';
  String get cityRoute => '${origin.city} → ${destination.city}';
  String get timeRange => '$departure – $arrival';
  String get inventoryKey => '$code:${date.year}-${date.month}-${date.day}';
}

class Offer {
  const Offer(this.origin, this.destination, this.date, this.price, this.image);

  final Airport origin;
  final Airport destination;
  final DateTime date;
  final int price;
  final String image;
  String get route => '${origin.city} → ${destination.city}';
}

class Passenger {
  const Passenger(
    this.firstName,
    this.lastName,
    this.document,
    this.email,
    this.phone,
  );

  final String firstName;
  final String lastName;
  final String document;
  final String email;
  final String phone;

  String get name => '$firstName $lastName';

  bool get isValid =>
      firstName.trim().length >= 2 &&
      lastName.trim().length >= 2 &&
      validDocument(document) &&
      validEmail(email) &&
      validPhone(phone);

  static bool validDocument(String value) =>
      RegExp(r'^[a-zA-Z0-9]{5,20}$').hasMatch(value.trim());
  static bool validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  static bool validPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[ +()-]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(digits);
  }
}

class BookingDraft {
  BookingDraft(this.query);

  final FlightQuery query;
  Flight? outbound;
  Flight? inbound;
  Fare? fare;
  Passenger? passenger;
  Baggage baggage = Baggage.none;
  final Map<String, String> seats = {};

  List<Flight> get flights => [?outbound, ?inbound];
  int get faresTotal =>
      flights.fold(0, (total, flight) => total + (fare?.price(flight) ?? 0));
  int get fees => flights.isEmpty ? 0 : 39900;
  int get total => faresTotal + baggage.price + fees;

  void selectFlight(Flight flight, {required bool isReturn}) {
    final previous = isReturn ? inbound : outbound;
    if (previous?.inventoryKey == flight.inventoryKey) return;
    if (previous != null) seats.remove(previous.inventoryKey);
    if (isReturn) {
      inbound = flight;
    } else {
      outbound = flight;
    }
  }
}

class Booking {
  Booking({
    required this.reference,
    required List<Flight> flights,
    required Map<String, String> seats,
    required this.fare,
    required this.passenger,
    required this.baggage,
    required this.total,
    required this.status,
  }) : flights = List.unmodifiable(flights),
       seats = Map.unmodifiable(seats);

  final String reference;
  final List<Flight> flights;
  final Map<String, String> seats;
  final Fare fare;
  final Passenger passenger;
  final Baggage baggage;
  final int total;
  TripStatus status;

  Flight get outbound => flights.first;
  Flight? get inbound => flights.length > 1 ? flights[1] : null;
  String seatFor(Flight flight) => seats[flight.inventoryKey] ?? '—';
}

class BookingException implements Exception {
  const BookingException(this.message);
  final String message;
}
