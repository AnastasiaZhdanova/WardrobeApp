import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock_controller.dart';

/// Covers the whole app until the owner is verified. The app underneath
/// stays mounted, so navigation state survives a lock.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;

  /// True while the app is not in the foreground. Covers the content so the
  /// iOS app switcher snapshot, taken while inactive, shows nothing private.
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _obscured = true),
      onResume: () => setState(() => _obscured = false),
      // Lock on `hidden`, not `inactive`: the Face ID sheet makes the app
      // inactive, and locking then would loop forever.
      onHide: () => ref.read(appLockControllerProvider.notifier).lock(),
      onShow: _unlock,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  void _unlock() => ref.read(appLockControllerProvider.notifier).unlock();

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appLockControllerProvider);
    return Stack(
      children: [
        // Hidden from screen readers and hit testing while locked.
        ExcludeSemantics(excluding: !state.isOpen, child: widget.child),
        if (!state.isOpen || _obscured)
          _LockScreen(state: state, onUnlock: _unlock),
        if (state is LockUnavailable) const _UnavailableBanner(),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.state, required this.onUnlock});

  final AppLockState state;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  Text('WardrobeApp', style: theme.textTheme.headlineMedium),
                  Text(
                    'Your wardrobe is private.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (state case Locked(message: final message?))
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  if (!state.isOpen)
                    FilledButton.icon(
                      key: const ValueKey('lock-unlock'),
                      onPressed: state is Authenticating ? null : onUnlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: scheme.errorContainer,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'App lock is off: this device has no passcode, Face ID or '
              'fingerprint set up. Add one in your device settings to turn '
              'it on.',
              key: const ValueKey('lock-unavailable'),
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ),
      ),
    );
  }
}
