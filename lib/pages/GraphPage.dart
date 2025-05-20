import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final database = FirebaseDatabase.instance;
  String selectedPath = 'real_data';

  List<Map<String, dynamic>> entries = [];
  List<String> availableKeys = [];
  Set<String> selectedKeys = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void changePath(String path) {
    setState(() {
      selectedPath = path;
      selectedKeys.clear();
      entries = [];
      availableKeys = [];
    });
    fetchData();
  }

  Future<void> fetchData() async {
    final snapshot = await database.ref(selectedPath).get();

    if (snapshot.exists) {
      final data = snapshot.value;
      List<Map<String, dynamic>> tempList = [];

      if (data is List) {
        tempList =
            data
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
      } else if (data is Map) {
        data.forEach((key, value) {
          final entry = Map<String, dynamic>.from(value);
          tempList.add(entry);
        });
      }

      tempList.sort((a, b) {
        final aTime = a['time'] ?? a['Date & Time'] ?? '';
        final bTime = b['time'] ?? b['Date & Time'] ?? '';
        return aTime.compareTo(bTime);
      });

      setState(() {
        entries = tempList;
        availableKeys =
            tempList.isNotEmpty
                ? tempList.first.keys
                    .where(
                      (k) => k != 'time' && k != 'date' && k != 'Date & Time',
                    )
                    .toList()
                : [];
      });
    }
  }

  List<FlSpot> buildSpots(String key) {
    final List<FlSpot> spots = [];

    for (int i = 0; i < entries.length; i++) {
      final value = entries[i][key];
      if (value != null) {
        final num? parsed = num.tryParse(
          value.toString().replaceAll(RegExp(r'[^\d.-]'), ''),
        );
        if (parsed != null) {
          spots.add(FlSpot(i.toDouble(), parsed.toDouble()));
        }
      }
    }

    return spots;
  }

  List<LineChartBarData> buildChartData() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.cyan,
    ];

    int colorIndex = 0;

    return selectedKeys.map((key) {
      final spots = buildSpots(key);
      final chart = LineChartBarData(
        isCurved: true,
        color: colors[colorIndex % colors.length],
        spots: spots,
        dotData: FlDotData(show: false),
        barWidth: 2,
        isStrokeCapRound: true,
      );
      colorIndex++;
      return chart;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int maxX = entries.length > 0 ? entries.length - 1 : 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph View'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPath == 'real_data'
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  onPressed: () => changePath('real_data'),
                  child: const Text('Real Data'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPath == 'data_file_1'
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  onPressed: () => changePath('data_file_1'),
                  child: const Text('Data File 1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPath == 'data_file_2'
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  onPressed: () => changePath('data_file_2'),
                  child: const Text('Data File 2'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (availableKeys.isNotEmpty)
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children:
                    availableKeys.map((key) {
                      return FilterChip(
                        selected: selectedKeys.contains(key),
                        label: Text(key),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedKeys.add(key);
                            } else {
                              selectedKeys.remove(key);
                            }
                          });
                        },
                        selectedColor: Colors.orange,
                      );
                    }).toList(),
              ),
            const SizedBox(height: 20),
            if (selectedKeys.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: entries.length * 60.0,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: maxX.toDouble(),
                        titlesData: FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                        ),
                        lineBarsData: buildChartData(),
                      ),
                    ),
                  ),
                ),
              ),
            if (selectedKeys.isEmpty)
              const Text("Please select at least one key to show graph."),
          ],
        ),
      ),
    );
  }
}
