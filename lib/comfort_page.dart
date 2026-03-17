import 'package:flutter/material.dart';

class ComfortPage extends StatelessWidget {
  const ComfortPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KALMADO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const Text('Sensory Environment Monitor', style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildIndicators(),
          const SizedBox(height: 24),
          const Text('Current Status by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildCategory('Noise Level', 'Quiet and comfortable', ['Ideal for focused learning', 'Students can concentrate']),
          _buildCategory('Temperature', 'Comfortable temperature', ['Optimal room heat', 'No adjustments needed']),
          const SizedBox(height: 24),
          _actionBtn('Adjust Thresholds', const Color(0xFFF3E5F5), Colors.purple),
          const SizedBox(height: 8),
          _actionBtn('View History', const Color(0xFFE3F2FD), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
      child: Column(children: const [
        CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Text('✨')),
        SizedBox(height: 16),
        Text('Overall Comfort Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('All sensory indicators are within comfortable ranges', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildIndicators() {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _row(Icons.check_circle_outline, Colors.green, 'Calm', 'Optimal environment'),
        _row(Icons.warning_amber_rounded, Colors.orange, 'Warning', 'Approaching limits'),
      ]),
    );
  }

  Widget _row(IconData i, Color c, String t, String s) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(i, color: c), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), Text(s, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
    ]));
  }

  Widget _buildCategory(String t, String s, List<String> tips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('✓ $t', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        Text(s, style: const TextStyle(color: Colors.green, fontSize: 12)),
        const Divider(color: Colors.white),
        ...tips.map((tip) => Text('• $tip', style: const TextStyle(fontSize: 11, color: Colors.green))),
      ]),
    );
  }

  Widget _actionBtn(String t, Color b, Color tc) {
    return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: b), child: Text(t, style: TextStyle(color: tc))));
  }
}