import 'package:material_ui/material_ui.dart';

import '../../data/flight_service.dart';
import '../../domain/travel.dart';
import '../design.dart';

class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({
    super.key,
    required this.service,
    required this.draft,
    required this.onContinue,
  });

  final FlightService service;
  final BookingDraft draft;
  final VoidCallback onContinue;

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  bool _returning = false;
  bool _confirmingExit = false;

  Future<void> _confirmExit(bool didPop, void _) async {
    if (didPop || _confirmingExit) return;

    _confirmingExit = true;
    try {
      final discard = await askConfirmation(
        context,
        '¿Salir de la reserva?',
        'Se perderán las selecciones y los datos de esta reserva.',
        'Salir de la reserva',
        cancelLabel: 'Seguir reservando',
      );
      if (mounted && discard && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    } finally {
      _confirmingExit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final query = draft.query;
    final results = widget.service.search(query, returning: _returning);
    final selected = _returning ? draft.inbound : draft.outbound;
    final missingReturn = query.roundTrip && draft.inbound == null;
    final canContinue =
        draft.outbound != null && (!missingReturn || !_returning);

    void proceed() {
      if (missingReturn) {
        setState(() => _returning = true);
      } else {
        widget.onContinue();
      }
    }

    return PopScope<void>(
      canPop: draft.outbound == null && draft.inbound == null,
      onPopInvokedWithResult: _confirmExit,
      child: AppPage(
        header: PageHeader(
          action: IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Editar búsqueda',
            icon: const Icon(Icons.tune, size: 20),
          ),
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton('Continuar', canContinue ? proceed : null),
            if (!canContinue) ...[
              const SizedBox(height: 5),
              const Copy(
                'Selecciona un vuelo para continuar',
                size: 11,
                color: muted,
                align: TextAlign.center,
              ),
            ],
          ],
        ),
        children: responsiveColumns(
          context,
          firstFlex: 4,
          secondFlex: 7,
          mobileGap: 21,
          first: [
            Panel(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCell(
                    'takeoff',
                    '${query.origin.label}   →   ${query.destination.label}',
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(child: _SummaryCell('landing', query.typeLabel)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _SummaryCell(
                          'calendar',
                          '${dateLabel(query.departure)}${query.returnDate == null ? '' : ' · ${dateLabel(query.returnDate!)}'}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Expanded(child: _SummaryCell('user', '1 adulto')),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _SummaryCell('seat', query.travelClass.label),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ActionButton(
                    'Editar búsqueda',
                    () => Navigator.maybePop(context),
                    outline: true,
                    height: 34,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
          ],
          second: [
            Row(
              children: [
                const Expanded(child: Heading('Vuelos disponibles', size: 21)),
                Copy(
                  '${results.length} ${results.length == 1 ? 'vuelo' : 'vuelos'}',
                  size: 12,
                  color: muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (query.roundTrip) ...[
              Segments(
                labels: const ['Ida', 'Regreso'],
                index: _returning ? 1 : 0,
                onChange: (index) => setState(() => _returning = index == 1),
              ),
              const SizedBox(height: 12),
            ],
            if (results.isEmpty)
              Panel(
                child: Column(
                  children: [
                    const Icon(Icons.search_off, color: blue, size: 34),
                    const SizedBox(height: 8),
                    const Heading('No encontramos vuelos', size: 17),
                    const SizedBox(height: 4),
                    const Copy(
                      'Elige otra fecha o cambia la ruta para buscar de nuevo.',
                      align: TextAlign.center,
                      color: muted,
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                      'Cambiar búsqueda',
                      () => Navigator.maybePop(context),
                      outline: true,
                    ),
                  ],
                ),
              ),
            for (final flight in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _FlightCard(
                  flight: flight,
                  selected: selected?.inventoryKey == flight.inventoryKey,
                  onSelect: () => setState(
                    () => draft.selectFlight(flight, isReturn: _returning),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(this.icon, this.label);
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.centerLeft,
    constraints: const BoxConstraints(minHeight: 32),
    decoration: BoxDecoration(
      color: fieldColor,
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    child: Row(
      children: [
        ArtIcon(icon, color: navy, size: 16),
        const SizedBox(width: 8),
        Flexible(child: Copy(label, size: 12)),
      ],
    ),
  );
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.flight,
    required this.selected,
    required this.onSelect,
  });
  final Flight flight;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final recommended = flight.recommendedFare == Fare.plus;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Panel(
          radius: 15,
          outline: selected || recommended ? blue : borderColor,
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
          child: Column(
            children: [
              Row(
                children: [
                  _FlightTime(flight.departure, flight.origin.code),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Color(0xFFBCCADB)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Transform.rotate(
                                angle: .6,
                                child: const Icon(
                                  Icons.flight_outlined,
                                  color: muted,
                                  size: 17,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Color(0xFFBCCADB)),
                            ),
                          ],
                        ),
                        Copy(
                          '${flight.duration} · Directo',
                          size: 10,
                          color: muted,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  _FlightTime(
                    flight.arrival,
                    flight.destination.code,
                    end: true,
                  ),
                ],
              ),
              const Divider(height: 12, color: borderColor),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Copy('Tarifa', size: 10, color: muted),
                      Copy(
                        flight.recommendedFare.label,
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Copy('Desde', size: 10, color: muted),
                        Copy(
                          money(flight.basePrice),
                          size: 17,
                          color: blue,
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ActionButton(
                      selected ? 'Seleccionado' : 'Seleccionar',
                      onSelect,
                      height: 34,
                      fontSize: 11,
                      radius: 10,
                      outline: selected,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (recommended)
          const Positioned(
            top: -8,
            right: 17,
            child: StatusPill('Recomendado'),
          ),
      ],
    );
  }
}

class _FlightTime extends StatelessWidget {
  const _FlightTime(this.time, this.code, {this.end = false});
  final String time;
  final String code;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Copy(time, size: 19, weight: FontWeight.w600),
      Copy(code, size: 11, color: muted),
    ],
  );
}

class FareScreen extends StatefulWidget {
  const FareScreen({super.key, required this.draft, required this.onContinue});
  final BookingDraft draft;
  final VoidCallback onContinue;

  @override
  State<FareScreen> createState() => _FareScreenState();
}

class _FareScreenState extends State<FareScreen> {
  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final outbound = draft.outbound!;
    return AppPage(
      footer: ActionButton(
        'Continuar',
        draft.fare == null ? null : widget.onContinue,
      ),
      children: responsiveColumns(
        context,
        firstFlex: 4,
        secondFlex: 7,
        mobileGap: 31,
        first: [
          Panel(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final (index, flight) in draft.flights.indexed) ...[
                  if (index > 0) const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ArtIcon(index == 0 ? 'takeoff' : 'landing'),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Copy(
                                flight.route,
                                size: 12,
                                weight: FontWeight.w600,
                              ),
                              Copy(
                                dateLabel(flight.date, weekday: true),
                                size: 11,
                                color: muted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const StatusPill('Seleccionado ✓'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        second: [
          const Row(
            children: [
              Expanded(child: Heading('Elige tu tarifa', size: 21)),
              ArtIcon('user', size: 19, color: muted),
              SizedBox(width: 5),
              Copy('1 adulto', size: 11, color: muted),
            ],
          ),
          const SizedBox(height: 14),
          for (final fare in Fare.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FareCard(
                fare: fare,
                price: fare.price(outbound),
                selected: draft.fare == fare,
                onSelect: () => setState(() => draft.fare = fare),
              ),
            ),
        ],
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({
    required this.fare,
    required this.price,
    required this.selected,
    required this.onSelect,
  });
  final Fare fare;
  final int price;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Panel(
        outline: selected ? blue : borderColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 19),
        radius: 17,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 19,
                  color: selected ? blue : muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Copy(fare.label, size: 19, weight: FontWeight.w600),
                ),
                Copy(
                  money(price),
                  size: 21,
                  color: blue,
                  weight: FontWeight.w600,
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, benefit) in fare.benefits.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(
                                [
                                  Icons.luggage_outlined,
                                  Icons.work_outline,
                                  Icons.event_seat_outlined,
                                ][index],
                                size: 16,
                              ),
                              const SizedBox(width: 7),
                              Expanded(child: Copy(benefit, size: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 86,
                  child: ActionButton(
                    selected ? 'Elegida ✓' : 'Elegir',
                    onSelect,
                    fontSize: 11,
                    height: 36,
                    outline: selected,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (fare == Fare.plus)
        const Positioned(top: -8, right: 17, child: StatusPill('Recomendada')),
    ],
  );
}
