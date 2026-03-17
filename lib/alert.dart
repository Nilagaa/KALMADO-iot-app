import 'package:flutter/material.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  bool noise = true; bool temp = true; bool light = true;

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
          _header(),
          const SizedBox(height: 16),
          _activeAlertsBox(),
          const SizedBox(height: 24),
          const Text('Notification Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          _toggle(Icons.volume_up, 'Noise Alerts', noise, (v) => setState(() => noise = v)),
          _toggle(Icons.thermostat, 'Temperature Alerts', temp, (v) => setState(() => temp = v)),
          _toggle(Icons.wb_sunny, 'Light Alerts', light, (v) => setState(() => light = v)),
          const SizedBox(height: 24),
          const Text('Recent Alert History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _historyItem('Noise Level', 'Approaching warning threshold', '2h ago', Colors.orange, Icons.volume_up),
          _historyItem('Temperature', 'Returned to comfortable range', '3h ago', Colors.blue, Icons.thermostat),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        CircleAvatar(backgroundColor: Colors.purple[50], child: const Icon(Icons.notifications_active, color: Colors.purple)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Alerts & Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Sensory threshold notifications', style: TextStyle(color: Colors.grey))]),
      ]),
    );
  }

  Widget _activeAlertsBox() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: const [
        Icon(Icons.check_circle, color: Colors.green, size: 50),
        SizedBox(height: 12),
        Text('No active alerts', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('All sensory levels are within safe ranges', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _toggle(IconData i, String l, bool v, Function(bool) c) {
    return SwitchListTile(secondary: Icon(i, color: Colors.blue), title: Text(l), value: v, activeColor: Colors.purple, onChanged: c);
  }

  Widget _historyItem(String t, String d, String tm, Color c, IconData i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: c.withOpacity(0.1))),
      child: Row(children: [
        Icon(i, color: c), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: c)), Text(d, style: const TextStyle(fontSize: 12))])),
        Text(tm, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }
}