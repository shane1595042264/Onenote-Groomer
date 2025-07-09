import 'package:flutter/material.dart';

class ProcessingStatus extends StatelessWidget {
  final String message;
  final double progress;

  const ProcessingStatus({
    super.key,
    required this.message,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E1E1E),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
          ),
        ],
      ),
    );
  }
}
