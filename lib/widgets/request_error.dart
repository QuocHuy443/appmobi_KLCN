import 'package:flutter/material.dart';

class RequestError extends StatelessWidget {
  const RequestError({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(message.replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]),
  );
}
