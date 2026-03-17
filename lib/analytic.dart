import 'package:flutter/material.dart';

class AnalyticPage extends StatefulWidget {
  const AnalyticPage({super.key});

  @override
  State<AnalyticPage> createState() => _AnalyticPageState();
}

class _AnalyticPageState extends State<AnalyticPage> {
  bool isHourly = true;

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
          _analyticsHeader(),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _stat('Avg Noise', '45 dB', Colors.blue),
            _stat('Avg Temp', '22°C', Colors.purple),
            _stat('Avg Light', '400 lux', Colors.orange),
          ]),
          const SizedBox(height: 24),
          const Text('Combined Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: Icon(Icons.show_chart, size: 50, color: Colors.grey))),
          const SizedBox(height: 24),
          const Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _insightsBox(),
          const SizedBox(height: 24),
          _btn('Download Weekly Report', Icons.calendar_today, const Color(0xFFF3E5F5), Colors.purple),
          const SizedBox(height: 8),
          _btn('Export Chart Data', Icons.show_chart, const Color(0xFFE3F2FD), Colors.blue),
        ],
      ),
    );
  }

  Widget _analyticsHeader() {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundColor: Colors.blue[50], child: const Icon(Icons.analytics, color: Colors.blue)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Sensory trends and patterns', style: TextStyle(color: Colors.grey))]),
        ]),
        const SizedBox(height: 16),
        ToggleButtons(
          borderRadius: BorderRadius.circular(12),
          isSelected: [isHourly, !isHourly],
          onPressed: (i) => setState(() => isHourly = i == 0),
          children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Hourly')), Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Daily'))],
        )
      ]),
    );
  }

  Widget _stat(String l, String v, Color c) {
    return Container(
      width: 100, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Column(children: [Text(l, style: TextStyle(fontSize: 10, color: c)), Text(v, style: TextStyle(fontWeight: FontWeight.bold, color: c))]),
    );
  }

  Widget _insightsBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('💡 Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
        SizedBox(height: 8),
        Text('• Noise levels peak around mid-morning (11:00)'),
        Text('• Temperature remains stable throughout the day'),
      ]),
    );
  }

  Widget _btn(String t, IconData i, Color b, Color tc) {
    return SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(i, size: 18), label: Text(t), style: ElevatedButton.styleFrom(backgroundColor: b, foregroundColor: tc)));
  }
}