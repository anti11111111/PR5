import 'package:flutter/material.dart';

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Удалить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// То же окно, что и у [confirmAction], но сразу в дереве виджетов.
class NoticePanel extends StatelessWidget {
  const NoticePanel({
    super.key,
    required this.title,
    required this.message,
    this.confirm = 'Понятно',
    this.cancel,
  });

  final String title;
  final String message;
  final String confirm;
  final String? cancel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x8A000000)),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text(message),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (cancel != null)
                          TextButton(onPressed: () {}, child: Text(cancel!)),
                        const SizedBox(width: 8),
                        FilledButton(onPressed: () {}, child: Text(confirm)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showNotice(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      );
    },
  );
}
