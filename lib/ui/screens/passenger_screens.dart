import 'package:material_ui/material_ui.dart';

import '../../data/booking_service.dart';
import '../../domain/travel.dart';
import '../design.dart';
import '../motion.dart';

class SeatScreen extends StatefulWidget {
  const SeatScreen({
    super.key,
    required this.service,
    required this.draft,
    required this.onContinue,
  });
  final BookingService service;
  final BookingDraft draft;
  final VoidCallback onContinue;

  @override
  State<SeatScreen> createState() => _SeatScreenState();
}

class _SeatScreenState extends State<SeatScreen> {
  int _leg = 0;

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final flight = draft.flights[_leg];
    final selected = draft.seats[flight.inventoryKey];

    void proceed() {
      final missingLeg = draft.flights.indexWhere(
        (option) => draft.seats[option.inventoryKey] == null,
      );
      if (missingLeg != -1) {
        setState(() => _leg = missingLeg);
      } else {
        widget.onContinue();
      }
    }

    return AppPage(
      footer: ActionButton('Continuar', selected == null ? null : proceed),
      children: responsiveColumns(
        context,
        firstFlex: 4,
        secondFlex: 6,
        mobileGap: 12,
        first: [
          Panel(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                InfoTile(
                  _leg == 0 ? 'Ida' : 'Regreso',
                  flight.route,
                  icon: _leg == 0 ? 'takeoff' : 'landing',
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InfoTile(
                        'Fecha',
                        dateLabel(flight.date, weekday: true, year: true),
                        icon: 'calendar',
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      flex: 2,
                      child: InfoTile('Tarifa', draft.fare!.label, icon: 'tag'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          const Heading('Selecciona tu asiento', size: 20),
          const SizedBox(height: 10),
          if (draft.flights.length > 1) ...[
            Segments(
              labels: const ['Ida', 'Regreso'],
              index: _leg,
              onChange: (value) => setState(() => _leg = value),
            ),
            const SizedBox(height: 10),
          ],
          const Panel(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            radius: 14,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 6,
              spacing: 8,
              children: [
                _Legend('Disponible', Colors.white, ' '),
                _Legend('Ocupado', Color(0xFFBDC7D4), '×'),
                _Legend('Seleccionado', blue, '✓'),
              ],
            ),
          ),
        ],
        second: [
          Panel(
            child: Align(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: usesDesktopLayout(context) ? 420 : 282,
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Copy('A', size: 11, align: TextAlign.center),
                        ),
                        Expanded(
                          child: Copy('B', size: 11, align: TextAlign.center),
                        ),
                        SizedBox(width: 29),
                        Expanded(
                          child: Copy('C', size: 11, align: TextAlign.center),
                        ),
                        Expanded(
                          child: Copy('D', size: 11, align: TextAlign.center),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (var row = 1; row <= BookingService.cabinRows; row++)
                      Row(
                        children: [
                          for (final (index, letter)
                              in BookingService.cabinColumns.indexed) ...[
                            if (index == 2)
                              SizedBox(
                                width: 29,
                                child: Copy(
                                  '$row',
                                  size: 10,
                                  align: TextAlign.center,
                                  color: muted,
                                ),
                              ),
                            Expanded(
                              child: _Seat(
                                seat: '$row$letter',
                                selected: selected == '$row$letter',
                                available: widget.service.isSeatAvailable(
                                  flight,
                                  '$row$letter',
                                ),
                                onSelect: () => setState(
                                  () => draft.seats[flight.inventoryKey] =
                                      '$row$letter',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ArtIcon('seat'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Copy('Asiento elegido', size: 11, color: muted),
                      Copy(
                        selected ?? '—',
                        size: 21,
                        color: blue,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                if (selected != null)
                  StatusPill(
                    selected.endsWith('B') || selected.endsWith('C')
                        ? 'Pasillo'
                        : 'Ventana',
                    color: muted,
                    background: fieldColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color, this.mark);
  final String label;
  final Color color;
  final String mark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: color == Colors.white ? const Color(0xFFA6B6CB) : color,
          ),
        ),
        alignment: Alignment.center,
        child: Copy(mark, size: 10, color: Colors.white),
      ),
      const SizedBox(width: 5),
      Copy(label, size: 10, color: muted),
    ],
  );
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.seat,
    required this.selected,
    required this.available,
    required this.onSelect,
  });
  final String seat;
  final bool selected;
  final bool available;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? blue
        : available
        ? Colors.white
        : const Color(0xFFBDC7D4);
    return Semantics(
      button: true,
      enabled: available,
      selected: selected,
      label:
          'Asiento $seat, ${selected
              ? 'seleccionado'
              : available
              ? 'disponible'
              : 'ocupado'}',
      child: Material(
        color: Colors.transparent,
        child: PressFeedback(
          builder: (states) => InkWell(
            statesController: states,
            borderRadius: BorderRadius.circular(6),
            onTap: available ? onSelect : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: AnimatedContainer(
                duration: motionDuration(context, motionQuick),
                curve: motionEase,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: available && !selected
                        ? const Color(0xFFA6B6CB)
                        : color,
                  ),
                ),
                child: Center(
                  child: ExcludeSemantics(
                    child: Copy(
                      selected
                          ? seat
                          : available
                          ? ''
                          : '×',
                      size: 12,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({
    super.key,
    required this.draft,
    required this.onContinue,
  });
  final BookingDraft draft;
  final VoidCallback onContinue;

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  bool _validationAttempted = false;
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(
    text: widget.draft.passenger?.firstName,
  );
  late final _last = TextEditingController(
    text: widget.draft.passenger?.lastName,
  );
  late final _document = TextEditingController(
    text: widget.draft.passenger?.document,
  );
  late final _email = TextEditingController(
    text: widget.draft.passenger?.email,
  );
  late final _phone = TextEditingController(
    text: widget.draft.passenger?.phone,
  );

  @override
  void dispose() {
    for (final controller in [_first, _last, _document, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.draft.passenger = Passenger(
      _first.text.trim(),
      _last.text.trim(),
      _document.text.trim(),
      _email.text.trim(),
      _phone.text.trim(),
    );
  }

  void _onFormChanged() {
    _save();
    if (_validationAttempted) setState(() {});
  }

  void _proceed() {
    if (!_form.currentState!.validate()) {
      setState(() => _validationAttempted = true);
      return;
    }
    FocusScope.of(context).unfocus();
    _save();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return AppPage(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_validationAttempted && draft.passenger?.isValid != true) ...[
            Semantics(
              liveRegion: true,
              child: const Copy(
                'Revisa los datos del pasajero.',
                size: 12,
                color: danger,
              ),
            ),
            const SizedBox(height: 6),
          ],
          ActionButton('Continuar', _proceed),
        ],
      ),
      children: responsiveColumns(
        context,
        firstFlex: 6,
        secondFlex: 5,
        mobileGap: 23,
        first: [
          const Heading(
            'Datos del pasajero',
            subtitle: 'Completa la información para tu reserva',
          ),
          const SizedBox(height: 16),
          Panel(
            child: Form(
              key: _form,
              onChanged: _onFormChanged,
              autovalidateMode: _validationAttempted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  _field(
                    'Nombres',
                    'Ana',
                    _first,
                    (value) => value.length >= 2,
                    'Ingresa los nombres.',
                  ),
                  _field(
                    'Apellidos',
                    'Torres',
                    _last,
                    (value) => value.length >= 2,
                    'Ingresa los apellidos.',
                  ),
                  _field(
                    'Documento',
                    'Número de documento',
                    _document,
                    Passenger.validDocument,
                    'Ingresa entre 5 y 20 letras o números.',
                  ),
                  _field(
                    'Correo electrónico',
                    'nombre@correo.com',
                    _email,
                    Passenger.validEmail,
                    'Ingresa un correo válido.',
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    'Teléfono',
                    '+57 300 555 0100',
                    _phone,
                    Passenger.validPhone,
                    'Ingresa un teléfono válido.',
                    keyboard: TextInputType.phone,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
        second: [
          const Heading('Equipaje adicional', size: 21),
          const SizedBox(height: 13),
          Panel(
            padding: const EdgeInsets.all(11),
            child: Column(
              children: [
                for (final baggage in Baggage.values)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: baggage == Baggage.none ? 8 : 0,
                    ),
                    child: _BaggageOption(
                      baggage: baggage,
                      selected: draft.baggage == baggage,
                      onSelect: () => setState(() => draft.baggage = baggage),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: LabelValue(
              'Total parcial',
              money(draft.faresTotal + draft.baggage.price),
              accent: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String placeholder,
    TextEditingController controller,
    bool Function(String) valid,
    String error, {
    TextInputType? keyboard,
    bool last = false,
  }) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Copy(label, size: 12),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: navy),
            keyboardType: keyboard,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: last ? (_) => _proceed() : null,
            validator: (value) => valid(value?.trim() ?? '') ? null : error,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(fontSize: 13, color: muted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BaggageOption extends StatelessWidget {
  const _BaggageOption({
    required this.baggage,
    required this.selected,
    required this.onSelect,
  });
  final Baggage baggage;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: selected ? Colors.white : fieldColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? blue : Colors.transparent),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: selected ? blue : muted,
              ),
              const SizedBox(width: 8),
              Expanded(child: Copy(baggage.label, size: 12)),
              Copy(money(baggage.price), size: 14, weight: FontWeight.w600),
            ],
          ),
        ),
      ),
    ),
  );
}
