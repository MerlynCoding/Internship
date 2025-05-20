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
      body: FutureBuilder<DataSnapshot>(
        future: dbRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.value == null) {
            return const Center(child: Text("No data available"));
          }

          final rawData = snapshot.data!.value as Map;
          final latestEntry = rawData.entries.last.value as Map;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 189, 208, 218),
                    borderRadius: BorderRadius.circular(20), // more rounded
                  ),
                  child: const Center(
                    child: Text(
                      'Current Solar Panel Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
                        value: latestEntry['voltage'],
                      ),
                      StatusCard(
                        label: "Current",
                        value: latestEntry['current'],
                      ),
                      StatusCard(label: "Power", value: latestEntry['power']),
                      StatusCard(
                        label: "Temperature",
                        value: latestEntry['temperature'],
                      ),
                      StatusCard(
                        label: "Humidity",
                        value: latestEntry['humidity'],
                      ),
                      StatusCard(
                        label: "Charging",
                        value: latestEntry['charging'],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => Home(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
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

  const StatusCard({required this.label, required this.value});

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
            color: Colors.blueGrey,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
