import 'package:flutter/material.dart';
class ServerDownWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const ServerDownWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text('Server is down', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text('Please try again later', style: TextStyle(fontFamily: 'Arial Narrow', fontSize: 14, color: isDark ? Colors.white54 : Colors.black45), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(fontFamily: 'Arial Narrow', color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
