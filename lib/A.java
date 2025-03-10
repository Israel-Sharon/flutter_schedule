import 'package:flutter/material.dart';

void main() {
  runApp(SchoolScheduleApp());
}

class SchoolScheduleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SchoolScheduleScreen(),
    );
  }
}

class SchoolScheduleScreen extends StatefulWidget {
  @override
  _SchoolScheduleScreenState createState() => _SchoolScheduleScreenState();
}

class _SchoolScheduleScreenState extends State<SchoolScheduleScreen> {
  final List<String> subjects = ["English", "Mathematics", "Language", "Physical Education"];
  final List<String> times = ["08:00-08:45", "09:00-09:45"];
  final List<String> teachers = ["Orit Sharon", "Rachel Levy", "David Israeli", "Noa Bicycle"];
  final List<String> children = ["Avi Levy", "Yehuda Levy", "Yaakov Levy", "Menashe Noy"];

  Map<String, String> schedule = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("School Schedule")),
      body: Row(
        children: [
          _buildList("Children", children, Colors.blue[100]!),
          Expanded(child: _buildTimeTable()),
          _buildList("Teachers", teachers, Colors.green[100]!),
        ],
      ),
    );
  }

  Widget _buildList(String title, List<String> items, Color color) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(8),
      color: color,
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ...items.map((item) => Draggable<String>(
                data: item,
                feedback: Material(
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.white,
                    child: Text(item, style: TextStyle(fontSize: 16)),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.all(8),
                  color: Colors.white,
                  child: Text(item),
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildTimeTable() {
    return Column(
      children: [
        Row(
          children: [Container(width: 100), ...subjects.map((s) => _buildTableHeader(s))],
        ),
        ...times.map((time) => Row(
              children: [
                _buildTimeCell(time),
                ...subjects.map((subject) => _buildDropTarget(time, subject)),
              ],
            )),
      ],
    );
  }

  Widget _buildTableHeader(String subject) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey[300],
        child: Text(subject, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTimeCell(String time) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Text(time, textAlign: TextAlign.center),
    );
  }

  Widget _buildDropTarget(String time, String subject) {
    String key = "$time-$subject";
    return Expanded(
      child: DragTarget<String>(
        onAccept: (value) => setState(() => schedule[key] = value),
        builder: (context, candidateData, rejectedData) => Container(
          height: 50,
          margin: EdgeInsets.all(4),
          padding: EdgeInsets.all(8),
          color: Colors.white,
          alignment: Alignment.center,
          child: Text(schedule[key] ?? ""),
        ),
      ),
    );
  }
}
