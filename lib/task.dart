import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_serializable/json_serializable.dart';

class Task extends StatefulWidget {
  final String name;
  final DateTime? date;
  final bool status;
  final Function(bool?)? checkboxCallback;

  const Task({super.key, required this.name, this.date, required this.status, this.checkboxCallback});

  factory Task.fromJson(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    final bool status = json['status'] as bool;
    final DateTime? date = json['date'] != null
      ? DateTime.parse(json['date'] as String)
      : null;
    return Task(
      name: name,
      date: date,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'status': status, 'date': date};


  Task copyWith({String? name, bool? status, DateTime? date}){
    return Task(
      name: name ?? this.name,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }

  @override
  State<Task> createState() => _TaskState();

}

class _TaskState extends State<Task> {
  late String name;
  late DateTime? date;
  late bool status;
  late Function(bool?)? checkboxCallback;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    date = widget.date;
    status = widget.status;
    checkboxCallback = widget.checkboxCallback;
  }

  String _displayDate() {
    if(date != null){
      return DateFormat('Until MMMM d, yyyy').format(date ?? DateTime.now());
      // technically it shouldn't ever get here while being null
    }
    return 'Permanent';
  }

  @override
  Widget build(BuildContext context){
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: Color.fromRGBO(215,201,245, 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(15, 10, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    _displayDate(),
                   style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Transform.scale(
                  scale: 1.25,
                  child: Checkbox(
                    value: status,
                    onChanged: (bool? newValue) {
                      setState(() {
                        status = newValue ?? false;
                      });
                      checkboxCallback;
                    },
                )
              )
            )
          )
        ],
      ),

    );
  }
}

class AddTaskDialog extends StatefulWidget{
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if(picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                hintText: 'Do homework',
                icon: Icon(Icons.edit),
              )
            ),
            const SizedBox(height:16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate == null
                  ? 'Select Due Date'
                  : DateFormat.yMMMd().format(_selectedDate!),
              ),
              onTap: _pickDate,
              trailing: _selectedDate == null
                ? null
                : IconButton(
                  icon: const Icon(Icons.clear, size:20),
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });

                }
              )
            ),
          ]
        )
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // close dialog
          child: const Text ('Cancel'),
        ),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () {
            // SAVE LOGIC HERE
            final newTask = Task(
              name: _taskController.text,
              date: _selectedDate,
              status: false
            );
            Navigator.of(context).pop(newTask);
          }
        ),
      ]
    );
  }
}