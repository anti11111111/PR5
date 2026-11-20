import 'package:flutter/material.dart';

class BookingChoice {
  const BookingChoice({required this.days, this.clientId, this.carId});

  final int days;
  final int? clientId;
  final int? carId;
}

/// Форма срока. Если бронь уже есть, введённые дни прибавляются к её дате.
Future<BookingChoice?> askBooking(
  BuildContext context, {
  required String title,
  String? until,
  List<(int, String)>? clients,
  List<(int, String)>? cars,
  String actionLabel = 'Продлить',
}) {
  return showDialog<BookingChoice>(
    context: context,
    builder: (context) => _ExtendDialog(
      title: title,
      until: until,
      clients: clients,
      cars: cars,
      actionLabel: actionLabel,
    ),
  );
}

class _ExtendDialog extends StatefulWidget {
  const _ExtendDialog({
    required this.title,
    required this.until,
    required this.clients,
    required this.cars,
    required this.actionLabel,
  });

  final String title;
  final String? until;
  final List<(int, String)>? clients;
  final List<(int, String)>? cars;
  final String actionLabel;

  @override
  State<_ExtendDialog> createState() => _ExtendDialogState();
}

class _ExtendDialogState extends State<_ExtendDialog> {
  final _days = TextEditingController(text: '7');
  int? _clientId;
  int? _carId;
  String? _error;

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  void _submit() {
    final days = int.tryParse(_days.text.trim());
    if (days == null || days < 1 || days > 365) {
      setState(() => _error = 'Укажите число дней от 1 до 365');
      return;
    }
    if (widget.clients != null && _clientId == null) {
      setState(() => _error = 'Выберите клиента');
      return;
    }
    if (widget.cars != null && _carId == null) {
      setState(() => _error = 'Выберите автомобиль');
      return;
    }
    Navigator.pop(context, BookingChoice(days: days, clientId: _clientId, carId: _carId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.until == null
                  ? 'Укажите срок. Если бронь на эту машину уже открыта, дни прибавятся к её дате, и её можно продлевать ещё.'
                  : 'Сейчас бронь до ${widget.until}. Новые дни прибавятся к этой дате.',
            ),
            const SizedBox(height: 12),
            if (widget.clients != null) ...[
              DropdownButtonFormField<int>(
                initialValue: _clientId,
                decoration: const InputDecoration(labelText: 'Клиент', border: OutlineInputBorder()),
                items: [
                  for (final person in widget.clients!)
                    DropdownMenuItem(value: person.$1, child: Text(person.$2)),
                ],
                onChanged: (value) => setState(() => _clientId = value),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.cars != null) ...[
              DropdownButtonFormField<int>(
                initialValue: _carId,
                decoration: const InputDecoration(labelText: 'Автомобиль', border: OutlineInputBorder()),
                items: [
                  for (final car in widget.cars!)
                    DropdownMenuItem(value: car.$1, child: Text(car.$2)),
                ],
                onChanged: (value) => setState(() => _carId = value),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'На сколько дней',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}
