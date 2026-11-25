import '../domain/travel.dart';
import 'flight_service.dart';

class BookingService {
  BookingService(this.flights);

  final FlightService flights;
  final List<({String account, Booking booking})> _bookings = [];
  final Map<BookingDraft, ({String account, Booking booking})>
  _confirmedDrafts = {};
  static const cabinRows = 10;
  static const cabinColumns = ['A', 'B', 'C', 'D'];
  static const _occupied = ['1D', '2A', '3C', '4B', '5A', '5D', '8B', '9C'];

  List<Booking> forAccount(String account) => List.unmodifiable(
    _bookings
        .where((entry) => entry.account == account)
        .map((entry) => entry.booking),
  );

  bool isSeatAvailable(Flight flight, String seat) {
    final match = RegExp(r'^([1-9]|10)[A-D]$').hasMatch(seat);
    if (!match || _occupied.contains(seat)) return false;
    return !_bookings.any(
      (entry) =>
          entry.booking.status != TripStatus.canceled &&
          entry.booking.seats[flight.inventoryKey] == seat,
    );
  }

  Booking confirm(BookingDraft draft, String account) {
    final confirmed = _confirmedDrafts[draft];
    if (confirmed != null) {
      if (confirmed.account != account) {
        throw const BookingException('La reserva pertenece a otra cuenta.');
      }
      return confirmed.booking;
    }

    final problem = draft.query.validate(flights.today);
    if (problem != null) throw BookingException(problem);
    if (!_matches(draft.outbound, flights.search(draft.query)) ||
        (draft.query.roundTrip &&
            !_matches(
              draft.inbound,
              flights.search(draft.query, returning: true),
            )) ||
        (!draft.query.roundTrip && draft.inbound != null)) {
      throw const BookingException(
        'Selecciona los vuelos de todos los trayectos.',
      );
    }
    if (draft.fare == null || draft.passenger?.isValid != true) {
      throw const BookingException(
        'Completa la tarifa y los datos del pasajero.',
      );
    }
    for (final flight in draft.flights) {
      final seat = draft.seats[flight.inventoryKey];
      if (seat == null || !isSeatAvailable(flight, seat)) {
        throw const BookingException(
          'Elige un asiento disponible para cada trayecto.',
        );
      }
    }

    final index = _confirmedDrafts.length;
    final reference = index == 0
        ? 'UA-4K82P'
        : 'UA-${(2120000 + index).toRadixString(36).toUpperCase()}';
    final booking = Booking(
      reference: reference,
      flights: draft.flights,
      seats: draft.seats,
      fare: draft.fare!,
      passenger: draft.passenger!,
      baggage: draft.baggage,
      total: draft.total,
      status: TripStatus.confirmed,
    );
    final entry = (account: account, booking: booking);
    _bookings.insert(0, entry);
    _confirmedDrafts[draft] = entry;
    return booking;
  }

  bool _matches(Flight? selected, List<Flight> options) =>
      selected != null &&
      options.any((flight) => flight.inventoryKey == selected.inventoryKey);

  bool canCancel(Booking booking) =>
      (booking.status == TripStatus.confirmed ||
          booking.status == TripStatus.upcoming) &&
      booking.outbound.departureInstant.isAfter(DateTime.now());

  bool cancel(Booking booking, String account) {
    final ownsBooking = _bookings.any(
      (entry) => entry.account == account && entry.booking == booking,
    );
    if (!ownsBooking || !canCancel(booking)) return false;
    booking.status = TripStatus.canceled;
    return true;
  }

  void seedDemoTrips() {
    const account = 'demo@unionair.com';
    const passenger = Passenger(
      'Ana',
      'Torres',
      '1234567890',
      account,
      '+57 300 555 0100',
    );

    void addTrip(
      String reference,
      Airport origin,
      Airport destination,
      DateTime date,
      TripStatus status,
    ) {
      final flight = Flight(
        code: 'UA-${origin.code}${destination.code}00',
        origin: origin,
        destination: destination,
        date: date,
        departure: '09:15',
        arrival: '10:25',
        duration: '1h 10m',
        basePrice: 189900,
        recommendedFare: Fare.basic,
        travelClass: Cabin.economy,
      );
      _bookings.add((
        account: account,
        booking: Booking(
          reference: reference,
          flights: [flight],
          seats: {flight.inventoryKey: '5B'},
          fare: Fare.basic,
          passenger: passenger,
          baggage: Baggage.none,
          total: 229800,
          status: status,
        ),
      ));
    }

    addTrip(
      'UA-7M31D',
      Airport.bogota,
      Airport.cartagena,
      flights.daysFromToday(42),
      TripStatus.upcoming,
    );
    addTrip(
      'UA-1Q55N',
      Airport.medellin,
      Airport.cali,
      flights.daysFromToday(-12),
      TripStatus.completed,
    );
  }
}
