import 'package:flutter/material.dart';
import 'comfort_page.dart';
import 'alert.dart';
import 'analytic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KALMADO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF635BFF)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'KALMADO Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Connecting the 4 separate files
  final List<Widget> _screens = [
    const DashboardView(), // Defined below
    const ComfortPage(),   // From comfort_page.dart
    const AlertPage(),     // From alert.dart
    const AnalyticPage(),  // From analythic.dart
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9C27B0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Comfort'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

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
          _buildInfoCard('Current Classroom', 'Room 3B - Foundation Class', 'Last updated: Just now'),
          const SizedBox(height: 16),
          _buildStatusBanner(),
          const SizedBox(height: 24),
          const Text('Sensory Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildLevel('Noise Level', '45', 'dB', 0.45, Colors.blueAccent, ['Quiet (0-40)', 'Moderate (40-60)', 'Loud (60+)']),
          _buildLevel('Temperature', '22', '°C', 0.5, Colors.purpleAccent, ['Cool (16-19)', 'Comfortable (19-24)', 'Warm (24+)']),
          _buildLevel('Light Level', '350', 'lux', 0.4, Colors.orangeAccent, ['Dim (0-200)', 'Moderate (200-500)', 'Bright (500+)']),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
      child: Column(children: const [
        Text('😊', style: TextStyle(fontSize: 30)),
        Text('Environment is Calm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        Text('All sensory levels are comfortable', style: TextStyle(color: Colors.green, fontSize: 12)),
      ]),
    );
  }

  Widget _buildLevel(String t, String v, String u, double p, Color c, List<String> labs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)), child: const Text('Calm', style: TextStyle(color: Colors.green, fontSize: 12))),
        ]),
        Row(children: [Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(u, style: const TextStyle(color: Colors.grey))]),
        LinearProgressIndicator(value: p, color: c, backgroundColor: Colors.grey[100]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: labs.map((l) => Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey))).toList()),
      ]),
    );
  }
}