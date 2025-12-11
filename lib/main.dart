import 'package:daily_app/task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:json_serializable/json_serializable.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final DateTime dateToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime _currentDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day); // Used as a reference for the currently selected date

  int _journalMode = 0; // Toggle for journal mode (0 = editor, 1 = preview)
  bool editable = true; // Set to false if it's not the current day

  // ###################
  // ##### Journal #####
  // ###################
  String _markdownContent = '';
  final TextEditingController _markdownController = TextEditingController();

  void _toggleJournal() {
    if(_journalMode == 0){
      setState((){_journalMode = 1;});
    } else {
      setState((){_journalMode = 0;});
    }
  }

  @override
  void initState() {
    super.initState();
    _markdownController.addListener(_updateContent);
    WidgetsBinding.instance!.addObserver(this);
    loadCurrentDay();
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state) {
      case AppLifecycleState.resumed:
      // widget is resumed
        break;
      case AppLifecycleState.inactive:
      // widget is inactive
        break;
      case AppLifecycleState.paused:
      saveDay();
        break;
      case AppLifecycleState.detached:
      saveDay();
        break;
      case AppLifecycleState.hidden:

        break;
    }
  }

  void _updateContent() {
    setState((){
      _markdownContent = _markdownController.text;
    });
  }

  Widget _displayJournal() {
    if(_journalMode == 0) {
      // Editor Panel (Takes half the width)
      return Expanded(
        child: _buildEditor(),
      );
    } else {
      // Preview Panel (Takes the other half)
      return Expanded(
      child: _buildPreview(),
      );
    }
  }

  Widget _showContent() {
    if(_markdownContent.isEmpty){
      return Text(
        'Preview will appear here. Try typing # Hello World',
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      return MarkdownWidget(
        data: _markdownContent, // fetch data from String?, which is updated by controller
        config: MarkdownConfig(
          configs: [ // Styles are put here
            PConfig(
              textStyle: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );
    }
  }

  // ####################
  // #### TO-DO LIST ####
  // ####################
  List<Task> taskList = [
    // for Testing
    // Task(name: "Insert Task Name", date: DateTime(2025, 12, 12),  status: false),
    // Task(name: "Insert Perm Task", status: true),
    // Task(name: "Work on that long project", date: DateTime(2025, 12, 10), status: false),
  ];
  
  
  // ####################
  // ##### CALENDAR #####
  // ####################
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _onDayTapped(DateTime selectedDay, DateTime focusedDay) {
    saveDay(); // save before changing _currentDate
    setState(() {
      _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      _focusedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      _currentDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    });
    final now = DateTime.now();
    loadDay(_selectedDay);
    _handleDaySelection(selectedDay); // unused
  }

  void _handleDaySelection(DateTime day) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected day: ${day.month}/${day.day}/${day.year}'),
        duration: const Duration(milliseconds: 1500),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Center(
                child: Text(DateFormat('MMMM d, yyyy').format(_currentDate))
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Journal'),
                Tab(text: 'To-Do List'),
                Tab(text: 'Calendar')
              ],
              labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold
              ),
              unselectedLabelStyle: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          body: TabBarView(
            children: [
              Scaffold( // JOURNAL  ################################################################
                body: _displayJournal(),
                floatingActionButton: FloatingActionButton(
                  onPressed: _toggleJournal,
                  tooltip: 'Toggle Journal Mode',
                  child: Icon(Icons.remove_red_eye),
                )
              ),

              Scaffold( // TO-DO LIST ################################################################
                body: ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: taskList.length,
                  itemBuilder: (context, index) {
                    var currentTask = taskList[index];
                    return Task(key: ValueKey(currentTask.name),
                      name: currentTask.name,
                      date: currentTask.date,
                      status: currentTask.status,
                      checkboxCallback: (bool? checkboxState) {
                        bool newState = checkboxState ?? false;
                        int num=0;
                        for (int i=0; i < taskList.length; i++){
                          if(taskList[i].name == currentTask.name){
                            num = i;
                            break;
                          }
                        }
                        setState(() {
                          taskList[num] = taskList[num].copyWith(
                            status: checkboxState
                          );
                        });
                      },
                      deleteCallback: () {
                      setState(() {
                        setState(() {
                          taskList.removeAt(index);
                        });
                      });
                    }
                    );
                  },
                  separatorBuilder: (context,index) => const SizedBox(height:10),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    final newTask = await showDialog<Task>(
                      context: context,
                      builder: (context) => const AddTaskDialog(),
                    );

                    if (newTask != null) {
                      setState(() {
                        taskList.add(newTask);
                      });
                    }
                  },
                  tooltip: 'Add New Task',
                  child: Icon(Icons.add),
                )
              ),
              Scaffold( // CALENDAR #########################################################################
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    // --- Configuration ---
                    focusedDay: _focusedDay,
                    firstDay: DateTime(2020, 1, 1), // Start of the calendar range
                    lastDay: DateTime.now(), // End of the calendar range
                    calendarFormat: CalendarFormat.month, // Show month view
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false, // Hide the format switcher
                      titleCentered: true,
                    ),

                    // --- Selection Logic ---
                    selectedDayPredicate: (day) {
                      // Use `isSameDay` to check if the current day in the builder
                      // is the same as the stored selected day.
                      return isSameDay(_selectedDay, day);
                    },

                    // **This is the main callback you need**
                    onDaySelected: _onDayTapped,

                    // Optional: Custom styling for the selected day
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha:0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _markdownController,
        decoration: const InputDecoration(
          hintText: 'Start writing your note here...',
          border: InputBorder.none, // Removes the default border
        ),
        maxLines: null, // Allows for unlimited lines
        expands: true, // Takes up all available space in its parent
        keyboardType: TextInputType.multiline,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: Colors.grey[50], // Slightly different background for preview
      padding: const EdgeInsets.all(16.0),
      child: _showContent(),
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getDayFile(DateTime date) async {
    var day = DateFormat('yyyy-MM-dd').format(date);
    final path = await _localPath;
    return File('$path/daily-$day.json');
  }

  void saveDay() async {
    final Map<String, dynamic> dayData = {
      'journal': _markdownController.text,
      'tasks': taskList.map((task) => task.toJson()).toList(),
      'date': DateFormat('yyyy-MM-dd').format(_currentDate),
    };
    String jsonString = jsonEncode(dayData);
    final file = await _getDayFile(_currentDate);
    await file.writeAsString(jsonString);
  }

  void loadDay(DateTime targetDate) async {
    try {
      final file = await _getDayFile(targetDate);
      if (await file.exists()){
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        final contents = await file.readAsString();
        final Map<String, dynamic> dayData = jsonDecode(contents);
        setState(() {
          _markdownController.text = dayData['journal'];
          _currentDate = formatter.parse(dayData['date']);

          final List<dynamic> taskData = dayData['tasks'];
          List<Task> newTasks = taskData.map<Task>((task) => Task.fromJson(task)).toList();
          taskList = newTasks;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error decoding or reading JSON file: $e'),
            duration: const Duration(milliseconds: 1500),
          )
      );
    }
  }
  void loadCurrentDay() async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    try {
      final file = await _getDayFile(_currentDate);
      if (await file.exists()){
        final contents = await file.readAsString();
        final Map<String, dynamic> dayData = jsonDecode(contents);
        setState(() {
          _markdownController.text = dayData['journal'];
          _currentDate = formatter.parse(dayData['date']);

          final List<dynamic> taskData = dayData['tasks'];
          List<Task> newTasks = taskData.map<Task>((task) => Task.fromJson(task)).toList();
          taskList = newTasks;
        });
      } else {
        loadPreviousDay();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error decoding or reading JSON file: $e'),
            duration: const Duration(milliseconds: 1500),
          ),
      );
    }
  }

  void loadPreviousDay() async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    int daysPast = 1;
    try {
      var file = await _getDayFile(_currentDate.subtract(const Duration(days: 1)));
      while(file.existsSync() == false) {
        file = await _getDayFile(_currentDate.subtract(Duration(days: daysPast)));
        daysPast--;
      }
      if(await file.exists()){
        final contents = await file.readAsString();
        final Map<String, dynamic> dayData = jsonDecode(contents);

        setState(() {
          _currentDate = formatter.parse(dayData['date']);

          final List<dynamic> taskData = dayData['tasks'];
          List<Task> newTasks = taskData.map<Task>((task) => Task.fromJson(task)).toList();
          // drop tasks that have exceeded the current date
          for(int i=0; i < newTasks.length; i++){
            if(newTasks[i].date != null && newTasks[i].date!.isAfter(dateToday)){
              newTasks.removeAt(i);
            }
          }
          taskList = newTasks;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error decoding or reading JSON file: $e'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }
}


