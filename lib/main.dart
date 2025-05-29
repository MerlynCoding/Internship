import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'pages/data_page.dart';
import 'pages/GraphPage.dart';
import 'pages/AboutPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDS0ftP79xhDkbsTdV1dNrLbaS0PtzmOnc",
      authDomain: "aiotapp-da6f5.firebaseapp.com",
      databaseURL:
          "https://aiotapp-da6f5-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "aiotapp-da6f5",
      storageBucket: "aiotapp-da6f5.appspot.com",
      messagingSenderId: "292238255930",
      appId: "1:292238255930:web:6451cca89222504c4f66c5",
    ),
  );
  runApp(SolarTrackerApp());
}

class SolarTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.blueGrey,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _index = 0;

  final _pages = [DashboardScreen(), DataPage(), GraphPage(), AboutPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blueGrey, // Set background color
        child: _pages[_index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.orange[300],
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.blueGrey[900],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Data'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Graph'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("real_data");

  // Helper method to safely convert values to strings
  String _safeValueToString(dynamic value) {
    if (value == null) return 'N/A';
    return value.toString();
  }

  // Helper method to get the latest entry based on timestamp
  Map<String, dynamic> _getLatestEntry(Map rawData) {
    var entries = rawData.entries.toList();

    // Sort entries by timestamp to get the truly latest one
    entries.sort((a, b) {
      var timeA = a.value['time'] ?? '';
      var timeB = b.value['time'] ?? '';
      return timeB.compareTo(timeA); // Descending order (latest first)
    });

    return Map<String, dynamic>.from(entries.first.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset('lib/assets/logo_sun.png', height: 30),
            const SizedBox(width: 10),
            const Text("Solar Tracker"),
          ],
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: dbRef.onValue, // Real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No data available"));
          }

          final rawData = snapshot.data!.snapshot.value as Map;
          final latestEntry = _getLatestEntry(rawData);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade600,
                        Colors.blueGrey.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Current Solar Panel Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last Update: ${latestEntry['time'] ?? 'N/A'} | ${latestEntry['date'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      StatusCard(
                        label: "Voltage",
                        value: _safeValueToString(latestEntry['voltage']),
                        unit: "V",
                        icon: Icons.flash_on,
                        color: Colors.amber,
                      ),
                      StatusCard(
                        label: "Current",
                        value: _safeValueToString(latestEntry['current']),
                        unit: "mA",
                        icon: Icons.electrical_services,
                        color: Colors.blue,
                      ),
                      StatusCard(
                        label: "Power",
                        value: _safeValueToString(latestEntry['power']),
                        unit: "W",
                        icon: Icons.power,
                        color: Colors.green,
                      ),
                      StatusCard(
                        label: "Temperature",
                        value: _safeValueToString(latestEntry['temperature']),
                        unit: "°C",
                        icon: Icons.thermostat,
                        color: Colors.orange,
                      ),
                      StatusCard(
                        label: "Humidity",
                        value: _safeValueToString(latestEntry['humidity']),
                        unit: "%",
                        icon: Icons.water_drop,
                        color: Colors.cyan,
                      ),
                      StatusCard(
                        label: "Charging",
                        value: _safeValueToString(latestEntry['charging']),
                        unit: "",
                        icon: Icons.battery_charging_full,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Debug info to show which entry is being displayed
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Debug Info',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total entries: ${rawData.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        'Latest time: ${latestEntry['time']} on ${latestEntry['date']}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const StatusCard({
    required this.label,
    required this.value,
    this.unit = "",
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blueGrey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}




























/// This file is part of the Internship Flutter App
/// Created by Merlyn (2025)
/// For reference only. Do not reuse or remove credit.