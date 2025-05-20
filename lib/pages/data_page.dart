import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  final database = FirebaseDatabase.instance;
  String selectedPath = "real_data";

  List<Map<String, dynamic>> allEntries = [];
  List<Map<String, dynamic>> entries = [];
  List<String> columnKeys = [];

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final dbRef = database.ref(selectedPath);
    final snapshot = await dbRef.get();

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

      if (tempList.isNotEmpty) {
        if (tempList.first.containsKey("Date & Time")) {
          tempList.sort((a, b) => b["Date & Time"].compareTo(a["Date & Time"]));
        } else if (tempList.first.containsKey("date") &&
            tempList.first.containsKey("time")) {
          tempList.sort((a, b) {
            final aDateTime = "${a['date']} ${a['time']}";
            final bDateTime = "${b['date']} ${b['time']}";
            return bDateTime.compareTo(aDateTime);
          });
        }
      }

      setState(() {
        allEntries = tempList;
        entries = tempList;

        if (tempList.isNotEmpty) {
          final keys = tempList.first.keys.toList();

          // Prioritize date/time columns to be shown first
          keys.sort((a, b) {
            const priority = ['date', 'time', 'Date & Time'];
            final ai = priority.contains(a) ? priority.indexOf(a) : 99;
            final bi = priority.contains(b) ? priority.indexOf(b) : 99;
            return ai.compareTo(bi);
          });

          columnKeys = keys;
        } else {
          columnKeys = [];
        }
      });

      if (startDate != null && endDate != null) {
        applyDateRangeFilter();
      }
    } else {
      setState(() {
        entries = [];
        allEntries = [];
        columnKeys = [];
      });
    }
  }

  void changeDataPath(String path) {
    setState(() {
      selectedPath = path;
      startDate = null;
      endDate = null;
    });
    fetchData();
  }

  void pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });

      if (endDate != null) {
        applyDateRangeFilter();
      }
    }
  }

  void pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });

      if (startDate != null) {
        applyDateRangeFilter();
      }
    }
  }

  void applyDateRangeFilter() {
    final df1 = DateFormat('dd-MM-yyyy');
    final df2 = DateFormat('yyyy/MM/dd');

    final filtered =
        allEntries.where((entry) {
          String? dateStr;
          if (entry.containsKey('date')) {
            dateStr = entry['date'];
          } else if (entry.containsKey("Date & Time")) {
            final parts = entry["Date & Time"].toString().split(" ");
            if (parts.isNotEmpty) dateStr = parts[0];
          }

          if (dateStr != null) {
            try {
              DateTime entryDate =
                  dateStr.contains("/")
                      ? df2.parse(dateStr)
                      : df1.parse(dateStr);

              return entryDate.isAfter(
                    startDate!.subtract(const Duration(days: 1)),
                  ) &&
                  entryDate.isBefore(endDate!.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();

    setState(() {
      entries = filtered;
    });
  }

  void clearFilter() {
    setState(() {
      startDate = null;
      endDate = null;
      entries = allEntries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Table'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedPath == 'real_data'
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                onPressed: () => changeDataPath('real_data'),
                child: const Text('Real Data'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedPath == 'data_file_1'
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                onPressed: () => changeDataPath('data_file_1'),
                child: const Text('Data File 1'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedPath == 'data_file_2'
                          ? Colors.orange
                          : Colors.grey[600],
                ),
                onPressed: () => changeDataPath('data_file_2'),
                child: const Text('Data File 2'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  startDate == null
                      ? 'Start Date'
                      : 'From: ${DateFormat('yyyy-MM-dd').format(startDate!)}',
                ),
                onPressed: pickStartDate,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(
                  endDate == null
                      ? 'End Date'
                      : 'To: ${DateFormat('yyyy-MM-dd').format(endDate!)}',
                ),
                onPressed: pickEndDate,
              ),
              if (startDate != null || endDate != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear Filter'),
                  onPressed: clearFilter,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                entries.isEmpty
                    ? const Center(child: Text("No data found"))
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: 12,
                          columns:
                              columnKeys
                                  .map(
                                    (key) => DataColumn(
                                      label: Align(
                                        alignment:
                                            key.toLowerCase().contains('date')
                                                ? Alignment.centerLeft
                                                : Alignment.center,
                                        child: Text(
                                          key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          rows:
                              entries.map((entry) {
                                return DataRow(
                                  cells:
                                      columnKeys.map((key) {
                                        return DataCell(
                                          Align(
                                            alignment:
                                                key.toLowerCase().contains(
                                                      'date',
                                                    )
                                                    ? Alignment.centerLeft
                                                    : Alignment.center,
                                            child: Text(
                                              entry[key]?.toString() ?? '',
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
