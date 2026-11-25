import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../data/booking_service.dart';
import '../../domain/travel.dart';
import '../design.dart';
import '../motion.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.draft, required this.onConfirm});
  final BookingDraft draft;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => AppPage(
    footer: ActionButton('Confirmar reserva', onConfirm),
    children: [
      const Heading(
        'Revisa tu reserva',
        subtitle: 'Verifica los detalles antes de confirmar',
      ),
      const SizedBox(height: 17),
      ...responsiveColumns(
        context,
        firstFlex: 6,
        secondFlex: 4,
        mobileGap: 14,
        first: [
          Panel(
            child: Column(
              children: [
                for (final (index, flight) in draft.flights.indexed) ...[
                  if (index > 0) const Divider(height: 18, color: borderColor),
                  _ItineraryLeg(flight: flight, returning: index > 0),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Panel(child: _LabeledIcon('user', 'Pasajero', draft.passenger!.name)),
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _DetailRow('tag', 'Tarifa', draft.fare!.label),
                const SizedBox(height: 5),
                _DetailRow(
                  'seat',
                  'Asiento',
                  draft.flights
                      .map((flight) => draft.seats[flight.inventoryKey]!)
                      .join(' · '),
                ),
                const SizedBox(height: 5),
                _DetailRow(
                  'briefcase',
                  'Equipaje adicional',
                  draft.baggage == Baggage.none
                      ? 'Sin equipaje'
                      : '1 maleta 23 kg',
                ),
              ],
            ),
          ),
        ],
        second: [
          Panel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                LabelValue(
                  'Vuelo ida',
                  money(draft.fare!.price(draft.outbound!)),
                ),
                if (draft.inbound != null) ...[
                  const Divider(height: 12, color: borderColor),
                  LabelValue(
                    'Vuelo regreso',
                    money(draft.fare!.price(draft.inbound!)),
                  ),
                ],
                const Divider(height: 12, color: borderColor),
                LabelValue('Equipaje adicional', money(draft.baggage.price)),
                const Divider(height: 12, color: borderColor),
                LabelValue('Tasas', money(draft.fees)),
                const SizedBox(height: 9),
                _Total('Total', draft.total),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

class ConfirmedScreen extends StatelessWidget {
  const ConfirmedScreen({
    super.key,
    required this.booking,
    required this.onHome,
    required this.onTrips,
  });
  final Booking booking;
  final VoidCallback onHome;
  final VoidCallback onTrips;

  @override
  Widget build(BuildContext context) => AppPage(
    header: const PageHeader(back: false),
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionButton('Ver mis viajes', onTrips),
        const SizedBox(height: 9),
        ActionButton('Ir al inicio', onHome, outline: true),
      ],
    ),
    children: responsiveColumns(
      context,
      mobileGap: 15,
      first: [
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 21, 16, 23),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: reducesMotion(context) ? 1 : .72, end: 1),
                  duration: motionDuration(
                    context,
                    const Duration(milliseconds: 400),
                  ),
                  curve: Curves.easeOutBack,
                  child: const CircleAvatar(
                    radius: 44,
                    backgroundColor: blue,
                    child: Icon(Icons.check, color: Colors.white, size: 43),
                  ),
                  builder: (context, scale, child) => Transform.scale(
                    scale: reducesMotion(context) ? 1 : scale,
                    child: child,
                  ),
                ),
              ),
              const SizedBox(height: 19),
              const Copy(
                '¡Reserva confirmada!',
                size: 23,
                weight: FontWeight.w600,
                align: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Copy(
                'Tu viaje ha sido registrado con éxito',
                size: 13,
                color: muted,
                align: TextAlign.center,
              ),
              const SizedBox(height: 23),
              Panel(
                color: paleBlue,
                outline: paleBlue,
                child: Column(
                  children: [
                    const Copy('Código de reserva', size: 13, color: muted),
                    Copy(
                      booking.reference,
                      size: 32,
                      color: blue,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      second: [
        Panel(
          padding: const EdgeInsets.all(11),
          child: Column(
            children: [
              for (final (index, flight) in booking.flights.indexed) ...[
                _DetailRow(
                  index == 0 ? 'takeoff' : 'landing',
                  flight.cityRoute,
                  dateLabel(flight.date, weekday: true),
                  tag: index == 0 ? 'Ida' : 'Regreso',
                  route: true,
                ),
                const SizedBox(height: 7),
              ],
              InfoTile('Pasajero', booking.passenger.name, icon: 'user'),
              const SizedBox(height: 7),
              InfoTile(
                'Asiento',
                booking.flights.map(booking.seatFor).join(' · '),
                icon: 'seat',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
    required this.bookings,
    required this.onOpen,
    required this.onSearch,
  });
  final List<Booking> bookings;
  final ValueChanged<Booking> onOpen;
  final VoidCallback onSearch;

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final trips = widget.bookings.where(
      (booking) => switch (_filter) {
        1 =>
          booking.status == TripStatus.upcoming ||
              booking.status == TripStatus.confirmed,
        2 => booking.status == TripStatus.completed,
        _ => true,
      },
    );
    final desktop = usesDesktopLayout(context);
    final cards = [
      for (final booking in trips)
        _TripCard(booking: booking, onTap: () => widget.onOpen(booking)),
    ];
    final filters = Segments(
      labels: const ['Todos', 'Próximos', 'Completados'],
      index: _filter,
      onChange: (value) => setState(() => _filter = value),
    );
    return AppPage(
      header: desktop ? null : const PageHeader(back: false),
      children: [
        const Heading(
          'Mis viajes',
          subtitle: 'Consulta tus reservas activas y futuras',
        ),
        const SizedBox(height: 22),
        if (desktop)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: 390, child: filters),
          )
        else
          filters,
        const SizedBox(height: 20),
        if (trips.isEmpty)
          Panel(
            child: Column(
              children: [
                const ArtIcon('briefcase', color: blue, size: 31),
                const SizedBox(height: 8),
                const Heading('Todavía no hay viajes aquí', size: 17),
                const SizedBox(height: 6),
                const Copy(
                  'Cuando tengas reservas en esta categoría, aparecerán aquí.',
                  align: TextAlign.center,
                  color: muted,
                ),
                const SizedBox(height: 11),
                ActionButton('Buscar vuelos', widget.onSearch, outline: true),
              ],
            ),
          ),
        if (desktop)
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980 ? 3 : 2;
              final width =
                  (constraints.maxWidth - 18 * (columns - 1)) / columns;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final card in cards) SizedBox(width: width, child: card),
                ],
              );
            },
          )
        else
          for (final card in cards)
            Padding(padding: const EdgeInsets.only(bottom: 15), child: card),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.booking, required this.onTap});
  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ArtIcon('takeoff', color: navy),
                const SizedBox(width: 8),
                Expanded(
                  child: Copy(
                    booking.outbound.cityRoute,
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right, color: muted, size: 19),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const ArtIcon('calendar', color: muted, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Copy(
                    '${dateLabel(booking.outbound.date, year: true)}'
                    '${booking.inbound == null ? '' : ' - ${dateLabel(booking.inbound!.date, year: true)}'}',
                    size: 12,
                    color: muted,
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: borderColor),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Copy('Código', size: 11, color: muted),
                      Copy(
                        booking.reference,
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(booking.status),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.service,
    required this.account,
  });
  final Booking booking;
  final BookingService service;
  final String account;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Future<void> _cancel() async {
    final confirmed = await askConfirmation(
      context,
      'Cancelar reserva',
      'Se cancelará la reserva y se liberarán sus asientos.',
      'Cancelar reserva',
    );
    if (!mounted || !confirmed) return;
    final canceled = widget.service.cancel(widget.booking, widget.account);
    setState(() {});
    showMessage(
      context,
      canceled
          ? 'Reserva cancelada. Los asientos quedaron disponibles.'
          : 'Esta reserva ya no se puede cancelar.',
    );
  }

  Future<void> _receipt() async {
    final booking = widget.booking;
    final receipt = [
      'UnionAir · Constancia de demostración',
      'Reserva ${booking.reference}',
      'Estado ${booking.status.label}',
      'Pasajero ${booking.passenger.name}',
      for (final flight in booking.flights)
        '${flight.route} · ${dateLabel(flight.date, year: true)} · ${flight.timeRange} · Asiento ${booking.seatFor(flight)}',
      'Tarifa ${booking.fare.label}',
      'Equipaje adicional ${booking.baggage.label}',
      'Total simulado ${money(booking.total)}',
    ].join('\n');
    final copy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Constancia de reserva'),
        content: SingleChildScrollView(child: SelectableText(receipt)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copiar constancia'),
          ),
        ],
      ),
    );
    if (copy != true) return;
    await Clipboard.setData(ClipboardData(text: receipt));
    if (mounted) showMessage(context, 'Constancia copiada.');
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return AppPage(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionButton('Descargar constancia', _receipt, outline: true),
          if (widget.service.canCancel(booking)) ...[
            const SizedBox(height: 9),
            ActionButton(
              'Cancelar reserva',
              _cancel,
              outline: true,
              color: danger,
            ),
          ],
        ],
      ),
      children: [
        Row(
          children: [
            const Expanded(child: Heading('Detalle de reserva', size: 21)),
            const SizedBox(width: 4),
            _StatusBadge(booking.status, detail: true),
          ],
        ),
        const SizedBox(height: 16),
        ...responsiveColumns(
          context,
          firstFlex: 6,
          secondFlex: 4,
          mobileGap: 12,
          first: [
            Panel(
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 22),
                  const SizedBox(width: 8),
                  const Copy('Código', size: 13),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Copy(
                      booking.reference,
                      size: 23,
                      color: blue,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                children: [
                  for (final (index, flight) in booking.flights.indexed) ...[
                    if (index > 0)
                      const Divider(height: 19, color: borderColor),
                    _ItineraryLeg(
                      flight: flight,
                      returning: index > 0,
                      seat: booking.seatFor(flight),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: _LabeledIcon(
                'user',
                booking.passenger.email,
                booking.passenger.name,
                valueFirst: true,
              ),
            ),
          ],
          second: [
            Panel(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _DetailRow('tag', 'Tarifa', booking.fare.label, flat: true),
                  const Divider(height: 10, color: borderColor),
                  _DetailRow(
                    'briefcase',
                    'Equipaje adicional',
                    booking.baggage == Baggage.none
                        ? 'Sin equipaje'
                        : '1 maleta 23 kg',
                    flat: true,
                  ),
                  const SizedBox(height: 7),
                  _Total('Total pagado', booking.total),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status, {this.detail = false});
  final TripStatus status;
  final bool detail;

  @override
  Widget build(BuildContext context) => switch (status) {
    TripStatus.confirmed when detail => const StatusPill(
      '✓ Confirmada',
      background: Color(0xFFDDF3E9),
      color: Color(0xFF176345),
    ),
    TripStatus.confirmed => StatusPill(
      status.label,
      background: blue,
      color: Colors.white,
    ),
    TripStatus.upcoming => StatusPill(status.label),
    TripStatus.completed => StatusPill(
      status.label,
      background: fieldColor,
      color: muted,
    ),
    TripStatus.canceled => StatusPill(
      status.label,
      background: const Color(0xFFFFEBEE),
      color: danger,
    ),
  };
}

class _ItineraryLeg extends StatelessWidget {
  const _ItineraryLeg({
    required this.flight,
    required this.returning,
    this.seat,
  });
  final Flight flight;
  final bool returning;
  final String? seat;

  @override
  Widget build(BuildContext context) {
    final tag = returning ? 'Regreso' : 'Ida';
    final icon = returning ? 'landing' : 'takeoff';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (seat == null) ...[StatusPill(tag), const SizedBox(height: 4)],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ArtIcon(icon, size: 17, color: navy),
              const SizedBox(width: 8),
              Expanded(
                child: Copy(
                  seat == null ? flight.route : tag,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (seat != null) ...[
          const SizedBox(height: 7),
          Copy(flight.route, size: 13, weight: FontWeight.w600),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _IconText(
              'calendar',
              dateLabel(flight.date, weekday: true, year: seat != null),
            ),
            _IconText('clock', flight.timeRange),
            if (seat case final selected?)
              _IconText('seat', 'Asiento $selected'),
          ],
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText(this.icon, this.text);
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ArtIcon(icon, size: 17, color: muted),
      const SizedBox(width: 6),
      Copy(text, size: 11, color: muted),
    ],
  );
}

class _LabeledIcon extends StatelessWidget {
  const _LabeledIcon(
    this.icon,
    this.label,
    this.value, {
    this.valueFirst = false,
  });
  final String icon;
  final String label;
  final String value;
  final bool valueFirst;

  @override
  Widget build(BuildContext context) {
    final labelText = Copy(label, size: 11, color: muted);
    final valueText = Copy(value, size: 14, weight: FontWeight.w600);
    return Row(
      children: [
        ArtIcon(icon, size: 24, color: navy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: valueFirst
                ? [valueText, labelText]
                : [labelText, valueText],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
    this.icon,
    this.label,
    this.value, {
    this.tag,
    this.route = false,
    this.flat = false,
  });
  final String icon;
  final String label;
  final String value;
  final String? tag;
  final bool route;
  final bool flat;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: flat ? Colors.white : fieldColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        ArtIcon(icon, size: 19, color: navy),
        const SizedBox(width: 8),
        if (route)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Copy(label, size: 13, weight: FontWeight.w600),
                Copy(value, size: 11, color: muted),
              ],
            ),
          )
        else ...[
          Expanded(child: Copy(label, size: 12, color: muted)),
          const SizedBox(width: 8),
          Expanded(
            child: Copy(
              value,
              size: 13,
              weight: FontWeight.w600,
              align: TextAlign.end,
            ),
          ),
        ],
        if (tag case final text?) StatusPill(text),
      ],
    ),
  );
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.total);
  final String label;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: paleBlue,
      borderRadius: BorderRadius.circular(8),
    ),
    child: LabelValue(label, money(total), accent: true),
  );
}
