import 'package:material_ui/material_ui.dart';

import '../../data/flight_service.dart';
import '../../domain/travel.dart';
import '../design.dart';
import '../motion.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.flights,
    required this.onSearch,
    required this.onSignOut,
  });
  final FlightService flights;
  final ValueChanged<FlightQuery> onSearch;
  final VoidCallback onSignOut;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Airport _origin = Airport.cali;
  Airport _destination = Airport.bogota;
  Cabin _cabin = Cabin.economy;
  late DateTime _departure = widget.flights.demoDeparture;
  late DateTime _return = widget.flights.demoReturn;
  bool _roundTrip = true;

  Future<void> _chooseDate({required bool returning}) async {
    final today = widget.flights.today;
    final date = await showDatePicker(
      context: context,
      initialDate: returning ? _return : _departure,
      firstDate: today,
      lastDate: widget.flights.daysFromToday(365),
      helpText: returning
          ? 'Selecciona la fecha de regreso'
          : 'Selecciona la fecha de salida',
    );
    if (!mounted || date == null) return;
    setState(() {
      if (returning) {
        _return = date;
      } else {
        _departure = date;
      }
    });
  }

  Future<T?> _choose<T>(
    String title,
    List<T> options,
    T current,
    String Function(T) label,
  ) {
    Widget optionList(BuildContext context, {double top = 0}) => ListView(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16, top, 16, 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Heading(title, size: 19),
        ),
        for (final option in options)
          ListTile(
            title: Text(label(option)),
            trailing: option == current
                ? const Icon(Icons.check, color: blue)
                : null,
            onTap: () => Navigator.pop(context, option),
          ),
      ],
    );

    if (usesDesktopLayout(context)) {
      return showDialog<T>(
        context: context,
        builder: (context) => Dialog(
          child: SizedBox(width: 430, child: optionList(context, top: 22)),
        ),
      );
    }
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: motionDuration(context, motionStandard),
        reverseDuration: motionDuration(context, motionQuick),
      ),
      builder: (context) => SafeArea(child: optionList(context)),
    );
  }

  Future<void> _chooseAirport({required bool origin}) async {
    final selected = await _choose(
      origin ? 'Origen' : 'Destino',
      Airport.values,
      origin ? _origin : _destination,
      (airport) => airport.label,
    );
    if (!mounted || selected == null) return;
    setState(() {
      if (origin) {
        _origin = selected;
      } else {
        _destination = selected;
      }
    });
  }

  Future<void> _chooseCabin() async {
    final selected = await _choose(
      'Clase',
      Cabin.values,
      _cabin,
      (cabin) => cabin.label,
    );
    if (mounted && selected != null) setState(() => _cabin = selected);
  }

  void _swap() => setState(() {
    final previousOrigin = _origin;
    _origin = _destination;
    _destination = previousOrigin;
  });

  void _search() {
    final query = FlightQuery(
      origin: _origin,
      destination: _destination,
      departure: _departure,
      travelClass: _cabin,
      returnDate: _roundTrip ? _return : null,
    );
    final problem = query.validate(widget.flights.today);
    if (problem != null) {
      showMessage(context, problem);
    } else {
      widget.onSearch(query);
    }
  }

  void _selectOffer(Offer offer) {
    setState(() {
      _origin = offer.origin;
      _destination = offer.destination;
      _departure = offer.date;
      _roundTrip = false;
    });
    _search();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
    header: usesDesktopLayout(context)
        ? null
        : PageHeader(
            back: false,
            action: PopupMenuButton<String>(
              tooltip: 'Menú de cuenta',
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (_) => widget.onSignOut(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'sign-out', child: Text('Cerrar sesión')),
              ],
            ),
          ),
    children: responsiveColumns(
      context,
      firstFlex: 5,
      secondFlex: 6,
      mobileGap: 16,
      first: [
        Copy(
          'Bienvenido a tu próximo vuelo',
          size: 23,
          align: usesDesktopLayout(context)
              ? TextAlign.start
              : TextAlign.center,
        ),
        const SizedBox(height: 13),
        Panel(
          shadow: true,
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Copy('¿Para dónde vas?', size: 18, weight: FontWeight.w600),
              const SizedBox(height: 7),
              Segments(
                labels: const ['Solo ida', 'Ida y vuelta'],
                index: _roundTrip ? 1 : 0,
                onChange: (index) => setState(() => _roundTrip = index == 1),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Column(
                    children: [
                      InfoTile(
                        'Origen',
                        _origin.label,
                        icon: 'takeoff',
                        onTap: () => _chooseAirport(origin: true),
                      ),
                      const SizedBox(height: 7),
                      InfoTile(
                        'Destino',
                        _destination.label,
                        icon: 'landing',
                        onTap: () => _chooseAirport(origin: false),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 13),
                    child: Material(
                      color: paleBlue,
                      shape: const CircleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        tooltip: 'Intercambiar origen y destino',
                        onPressed: _swap,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: const EdgeInsets.all(6),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.swap_vert,
                          color: blue,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _fieldPair(
                InfoTile(
                  'Salida',
                  dateLabel(_departure, weekday: true, year: true),
                  icon: 'calendar',
                  onTap: () => _chooseDate(returning: false),
                ),
                _roundTrip
                    ? InfoTile(
                        'Regreso',
                        dateLabel(_return, weekday: true, year: true),
                        icon: 'calendar',
                        onTap: () => _chooseDate(returning: true),
                      )
                    : null,
              ),
              const SizedBox(height: 7),
              _fieldPair(
                InfoTile(
                  'Pasajeros',
                  '1 adulto',
                  icon: 'user',
                  onTap: () => _choose(
                    'Pasajeros',
                    ['1 adulto'],
                    '1 adulto',
                    (value) => value,
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_down, size: 18),
                ),
                InfoTile(
                  'Clase',
                  _cabin.label,
                  icon: 'seat',
                  onTap: _chooseCabin,
                  trailing: const Icon(Icons.keyboard_arrow_down, size: 18),
                ),
              ),
              const SizedBox(height: 11),
              ActionButton('Buscar vuelos', _search),
            ],
          ),
        ),
      ],
      second: [
        const Heading('Ofertas de hoy', size: 18),
        const SizedBox(height: 10),
        _offers(),
      ],
    ),
  );

  Widget _fieldPair(Widget first, Widget? second) {
    final horizontal = Row(
      children: [
        Expanded(child: first),
        if (second != null) ...[
          const SizedBox(width: 10),
          Expanded(child: second),
        ],
      ],
    );
    if (!usesDesktopLayout(context) || second == null) return horizontal;

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 310
          ? horizontal
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [first, const SizedBox(height: 7), second],
            ),
    );
  }

  Widget _offers() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 255 ? 1 : 2;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final offer in widget.flights.offers)
            SizedBox(
              width: width,
              child: _OfferCard(offer: offer, onTap: () => _selectOffer(offer)),
            ),
        ],
      );
    },
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onTap});
  final Offer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: usesDesktopLayout(context) ? 2.25 : 3.15,
            child: Image.asset(
              'assets/${offer.image}',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Copy(offer.route, size: 11.5, weight: FontWeight.w600),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const ArtIcon('calendar', color: muted, size: 12),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Copy(
                        dateLabel(offer.date, weekday: true, year: true),
                        size: 10,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Copy('Desde', size: 10, color: muted),
                    Copy(
                      money(offer.price),
                      size: 17,
                      weight: FontWeight.w600,
                      color: blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
