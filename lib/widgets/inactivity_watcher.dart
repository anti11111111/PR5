import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';

/// Следит за действиями человека. За 30 секунд до выхода показывает предупреждение.
class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.enabled,
    required this.onTimeout,
    required this.onLimit,
    required this.onWarning,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onTimeout;
  final VoidCallback onLimit;
  final VoidCallback onWarning;
  final Widget child;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _idle;
  Timer? _warn;
  Timer? _limit;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _arm();
  }

  @override
  void didUpdateWidget(InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _arm();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancel();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _arm() {
    _cancel();
    if (!widget.enabled) {
      return;
    }
    _restart();
    _limit = Timer(sessionLimit, widget.onLimit);
  }

  void _restart() {
    if (!widget.enabled) {
      return;
    }
    _idle?.cancel();
    _warn?.cancel();
    final warnAfter = idleTimeout - idleWarning;
    _warn = Timer(warnAfter.isNegative ? Duration.zero : warnAfter, widget.onWarning);
    _idle = Timer(idleTimeout, widget.onTimeout);
  }

  void _cancel() {
    _idle?.cancel();
    _warn?.cancel();
    _limit?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}

class IdleWarning extends StatelessWidget {
  const IdleWarning({super.key, required this.onContinue});

  final VoidCallback onContinue;

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
                    Text('Сессия скоро завершится', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text(
                      'Вы ничего не делали почти три минуты. Через 30 секунд сессия закроется и нужно будет войти снова.',
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(onPressed: onContinue, child: const Text('Продолжить')),
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
