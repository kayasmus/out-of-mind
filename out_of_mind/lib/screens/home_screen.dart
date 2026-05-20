import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Screen")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: null,
          child: const Text("Add Purchase"),
          ),
          ),
        Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: null, child: const Text("Planned"))),
              Expanded(child: ElevatedButton(onPressed: null, child: const Text("Locations"))),
            ],
          ),
          DataTable(
    columns: const [
    DataColumn(label: Text('Mood')),
    DataColumn(label: Text('Amount')),
    DataColumn(label: Text('Location')),
    DataColumn(label: Text('Date & Time')),
  ],
  rows: const [],
)
        ]
      ),),
    );
  }
}
