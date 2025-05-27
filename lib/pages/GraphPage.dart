import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

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

  // Get formatted timestamp for X-axis (time with minutes, handle duplicates)
  String getFormattedTime(int index) {
    if (index >= 0 && index < entries.length) {
      final timeValue =
          entries[index]['time'] ??
          entries[index]['Date & Time'] ??
          entries[index]['date'] ??
          '';

      final dateValue = entries[index]['date'] ?? '';

      if (timeValue.toString().isNotEmpty) {
        final timeStr = timeValue.toString();

        try {
          // Your Firebase data has time in "HH:mm:ss" format like "08:00:00"
          if (timeStr.contains(':')) {
            final parts = timeStr.split(':');
            if (parts.length >= 2) {
              final hour = parts[0].padLeft(2, '0');
              final minute = parts[1].padLeft(2, '0');

              // Check if we have date information to make labels unique
              if (dateValue.toString().isNotEmpty) {
                final dateStr = dateValue.toString();
                if (dateStr.contains('-')) {
                  // Extract day from date like "08-05-2025"
                  final dateParts = dateStr.split('-');
                  if (dateParts.length >= 2) {
                    final day = dateParts[1]; // Get day part
                    return '$hour:$minute\n$day/${dateParts[0]}'; // Show time and short date
                  }
                }
              }

              // If multiple entries have same time, add sequence number
              int sameTimeCount = 0;
              for (int i = 0; i < index; i++) {
                final prevTime = entries[i]['time'] ?? '';
                if (prevTime.toString() == timeStr) {
                  sameTimeCount++;
                }
              }

              if (sameTimeCount > 0) {
                return '$hour:$minute\n(${sameTimeCount + 1})'; // Add sequence number for duplicates
              }

              return '$hour:$minute'; // Return HH:mm format
            }
          }

          // Fallback: try to parse as DateTime if above doesn't work
          DateTime? dateTime;

          if (timeStr.contains('T')) {
            dateTime = DateTime.tryParse(timeStr);
          } else if (timeStr.contains('/')) {
            dateTime =
                DateFormat('MM/dd/yyyy HH:mm:ss').tryParse(timeStr) ??
                DateFormat('dd/MM/yyyy HH:mm:ss').tryParse(timeStr) ??
                DateFormat('MM/dd/yyyy HH:mm').tryParse(timeStr);
          } else if (timeStr.contains('-')) {
            dateTime =
                DateFormat('yyyy-MM-dd HH:mm:ss').tryParse(timeStr) ??
                DateFormat('yyyy-MM-dd HH:mm').tryParse(timeStr);
          }

          if (dateTime != null) {
            return DateFormat('HH:mm').format(dateTime);
          }
        } catch (e) {
          // If parsing fails, try regex to extract time
          final timeRegex = RegExp(r'(\d{1,2}):(\d{2})');
          final match = timeRegex.firstMatch(timeStr);

          if (match != null) {
            final hour = match.group(1)!.padLeft(2, '0');
            final minute = match.group(2)!;
            return '$hour:$minute';
          }
        }
      }
    }
    return 'P${index + 1}'; // Fallback with point number
  }

  // Calculate min and max Y values from all selected data
  Map<String, double> getMinMaxY() {
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (String key in selectedKeys) {
      final spots = buildSpots(key);
      for (var spot in spots) {
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
      }
    }

    // Add some padding (10% of the range)
    if (minY != double.infinity && maxY != double.negativeInfinity) {
      final range = maxY - minY;

      // Handle case where all values are the same (range = 0)
      if (range == 0) {
        // If all values are the same, create a small range around that value
        final value = minY;
        minY =
            value -
            (value.abs() * 0.1 + 1); // Add padding based on value magnitude
        maxY = value + (value.abs() * 0.1 + 1);
      } else {
        final padding = range * 0.1;
        minY -= padding;
        maxY += padding;
      }
    } else {
      // Default values if no data
      minY = 0;
      maxY = 100;
    }

    return {'minY': minY, 'maxY': maxY};
  }

  // Calculate safe horizontal interval for grid lines
  double getSafeHorizontalInterval(double minY, double maxY) {
    final range = maxY - minY;

    if (range <= 0) {
      return 1.0; // Default interval if range is zero or negative
    }

    // Calculate interval to have about 5-8 grid lines
    double interval = range / 5;

    // Ensure minimum interval
    if (interval <= 0) {
      return 1.0;
    }

    // Round to a nice number
    if (interval < 1) {
      // For small ranges, use decimal intervals
      if (interval < 0.01) {
        interval = 0.01;
      } else if (interval < 0.1) {
        interval = 0.1;
      } else if (interval < 0.5) {
        interval = 0.5;
      } else {
        interval = 1.0;
      }
    } else {
      // For larger ranges, round to nearest integer or nice number
      interval = interval.ceilToDouble();
    }

    return interval;
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
    final minMaxY = getMinMaxY();
    final horizontalInterval = getSafeHorizontalInterval(
      minMaxY['minY']!,
      minMaxY['maxY']!,
    );

    // Debug: Ensure we have valid values
    assert(horizontalInterval > 0, 'horizontalInterval must be greater than 0');
    assert(minMaxY['minY']! < minMaxY['maxY']!, 'minY must be less than maxY');

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
                        selectedPath == 'real_data1'
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  onPressed: () => changePath('real_data1'),
                  child: const Text('real data 1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedPath == 'real_data2'
                            ? Colors.orange
                            : Colors.grey[600],
                  ),
                  onPressed: () => changePath('real_data2'),
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
                child: Row(
                  children: [
                    // Fixed Y-axis on the left
                    SizedBox(
                      width: 50,
                      child: LineChart(
                        LineChartData(
                          minY: minMaxY['minY'],
                          maxY: minMaxY['maxY'],
                          minX: 0,
                          maxX: 1,
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(color: Colors.grey),
                              bottom: BorderSide(color: Colors.grey),
                            ),
                          ),
                          lineBarsData: [],
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                horizontalInterval > 0
                                    ? horizontalInterval
                                    : 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Scrollable chart area
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width:
                              entries.length *
                              70.0, // Adjusted width for time-only labels
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: maxX.toDouble(),
                              minY: minMaxY['minY'],
                              maxY: minMaxY['maxY'],
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize:
                                        50, // Increased for potential two-line labels
                                    interval:
                                        maxX > 15
                                            ? (maxX / 8).ceilToDouble()
                                            : (maxX > 5
                                                ? 2
                                                : 1), // Dynamic interval
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= entries.length) {
                                        return const SizedBox.shrink();
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          getFormattedTime(index),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  right: BorderSide(color: Colors.grey),
                                  bottom: BorderSide(color: Colors.grey),
                                ),
                              ),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final timestamp = getFormattedTime(
                                        spot.x.toInt(),
                                      );
                                      return LineTooltipItem(
                                        '$timestamp\n${spot.y.toStringAsFixed(2)}',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: buildChartData(),
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: false,
                                verticalInterval: maxX > 10 ? maxX / 10 : 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
