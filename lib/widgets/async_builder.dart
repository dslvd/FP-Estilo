import 'package:flutter/material.dart';

import '../services/plant_api.dart';

/// Reusable wrapper for the three states an API-backed screen can be in:
/// loading, error, or loaded.
///
/// Plant Search and Species Details both depend on a network call, so instead
/// of each screen re-implementing a spinner + error text + retry button, they
/// both hand their [Future] to this widget.
///
/// It also distinguishes "you are offline" from "the server said no" by
/// reading [ApiException.isOffline], and offers a retry in both cases.
class AsyncBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;

  /// Called when the user taps "Try again".
  final VoidCallback? onRetry;

  /// Shown while the future is in flight.
  final String loadingLabel;

  const AsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.loadingLabel = 'Loading\u2026',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(loadingLabel),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error!, onRetry: onRetry);
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Nothing to show.'));
        }
        return builder(context, data);
      },
    );
  }
}

/// The error half of [AsyncBuilder].
class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const _ErrorState({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offline = error is ApiException && (error as ApiException).isOffline;
    final message = error is ApiException
        ? (error as ApiException).message
        : 'Something went wrong. Please try again.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              offline ? 'You are offline' : 'That did not work',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
