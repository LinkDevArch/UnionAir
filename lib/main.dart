import 'package:material_ui/material_ui.dart';

import 'data/booking_service.dart';
import 'data/flight_service.dart';
import 'data/session_service.dart';
import 'domain/travel.dart';
import 'ui/design.dart';
import 'ui/motion.dart';
import 'ui/screens/booking_screens.dart';
import 'ui/screens/flight_screens.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/passenger_screens.dart';
import 'ui/screens/search_screen.dart';

void main() => runApp(const UnionAirApp());

class UnionAirApp extends StatefulWidget {
  const UnionAirApp({super.key});

  @override
  State<UnionAirApp> createState() => _UnionAirAppState();
}

class _UnionAirAppState extends State<UnionAirApp> {
  final _session = SessionService();
  final _flights = FlightService();
  late final _bookings = BookingService(_flights)..seedDemoTrips();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'UnionAir',
    debugShowCheckedModeBanner: false,
    theme: unionAirTheme(),
    locale: const Locale('es', 'CO'),
    supportedLocales: const [Locale('es', 'CO')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFE7EDF5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: child!,
        ),
      ),
    ),
    home: Builder(
      builder: (context) => AnimatedSwitcher(
        duration: motionDuration(context, motionStandard),
        switchInCurve: motionEase,
        switchOutCurve: motionEase,
        child: _session.email == null
            ? LoginScreen(session: _session, onSignIn: () => setState(() {}))
            : _Home(
                account: _session.email!,
                flights: _flights,
                bookings: _bookings,
                onSignOut: () => setState(_session.signOut),
              ),
      ),
    ),
  );
}

class _Home extends StatefulWidget {
  const _Home({
    required this.account,
    required this.flights,
    required this.bookings,
    required this.onSignOut,
  });
  final String account;
  final FlightService flights;
  final BookingService bookings;
  final VoidCallback onSignOut;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final _tabMotion = AnimationController(
    vsync: this,
    duration: motionStandard,
    value: 1,
  );
  late final _tabOpacity = _tabMotion
      .drive(CurveTween(curve: motionEase))
      .drive(Tween(begin: .78, end: 1.0));

  @override
  void dispose() {
    _tabMotion.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
    if (!reducesMotion(context)) {
      _tabMotion.forward(from: 0);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await askConfirmation(
      context,
      'Cerrar sesión',
      'Podrás volver a consultar tus reservas cuando ingreses de nuevo.',
      'Cerrar sesión',
    );
    if (mounted && confirmed) widget.onSignOut();
  }

  Future<void> _openBooking(Booking booking) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(
          booking: booking,
          service: widget.bookings,
          account: widget.account,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _search(FlightQuery query) async {
    final draft = BookingDraft(query);
    final flow = _BookingFlow(
      navigator: Navigator.of(context),
      draft: draft,
      flights: widget.flights,
      bookings: widget.bookings,
      account: widget.account,
      onFinish: _selectTab,
    );
    await flow.showResults();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FadeTransition(
      opacity: reducesMotion(context)
          ? const AlwaysStoppedAnimation(1.0)
          : _tabOpacity,
      child: IndexedStack(
        index: _tab,
        children: [
          SearchScreen(
            flights: widget.flights,
            onSearch: _search,
            onSignOut: _signOut,
          ),
          TripsScreen(
            bookings: widget.bookings.forAccount(widget.account),
            onOpen: _openBooking,
            onSearch: () => _selectTab(0),
          ),
        ],
      ),
    ),
    bottomNavigationBar: Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: _tab == 0 ? Alignment.topLeft : Alignment.topRight,
                duration: motionDuration(context, motionStandard),
                curve: motionEase,
                child: const FractionallySizedBox(
                  widthFactor: .5,
                  child: Center(
                    heightFactor: 1,
                    child: SizedBox(
                      width: 44,
                      height: 3,
                      child: ColoredBox(color: blue),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Tab(
                    icon: 'search',
                    label: 'Buscar',
                    selected: _tab == 0,
                    onTap: () => _selectTab(0),
                  ),
                ),
                Expanded(
                  child: _Tab(
                    icon: 'briefcase',
                    label: 'Mis Viajes',
                    selected: _tab == 1,
                    onTap: () => _selectTab(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? blue : muted;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 11),
            ArtIcon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Copy(
              label,
              size: 12,
              color: color,
              weight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            const SizedBox(height: 9),
          ],
        ),
      ),
    );
  }
}

class _BookingFlow {
  _BookingFlow({
    required this.navigator,
    required this.draft,
    required this.flights,
    required this.bookings,
    required this.account,
    required this.onFinish,
  });

  final NavigatorState navigator;
  final BookingDraft draft;
  final FlightService flights;
  final BookingService bookings;
  final String account;
  final ValueChanged<int> onFinish;
  bool _finished = false;

  Future<void> showResults() => navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => FlightResultsScreen(
        service: flights,
        draft: draft,
        onContinue: _showFare,
      ),
    ),
  );

  void _showFare() => _push(FareScreen(draft: draft, onContinue: _showSeats));

  void _showSeats() => _push(
    SeatScreen(service: bookings, draft: draft, onContinue: _showPassenger),
  );

  void _showPassenger() =>
      _push(PassengerScreen(draft: draft, onContinue: _showReview));

  void _showReview() {
    navigator.push<void>(
      MaterialPageRoute(
        builder: (context) =>
            ReviewScreen(draft: draft, onConfirm: () => _confirm(context)),
      ),
    );
  }

  void _push(Widget screen) =>
      navigator.push<void>(MaterialPageRoute(builder: (_) => screen));

  void _confirm(BuildContext context) {
    if (_finished) return;
    try {
      final booking = bookings.confirm(draft, account);
      _finished = true;
      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute(
          builder: (_) => ConfirmedScreen(
            booking: booking,
            onHome: () => _finish(0),
            onTrips: () => _finish(1),
          ),
        ),
        (route) => route.isFirst,
      );
    } on BookingException catch (error) {
      showMessage(context, error.message);
    }
  }

  void _finish(int tab) {
    onFinish(tab);
    navigator.popUntil((route) => route.isFirst);
  }
}
