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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DateTime dateToday = DateTime.now();
  final String dateTodayString = DateFormat('MMMM d, yyyy').format(DateTime.now());
  String? _currentDate; // DateFormat('MMMM d, yyyy')
  int _journalMode = 0;
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
    Task(name: "Insert Task Name", date: DateTime(2025, 12, 12),  status: false),
    Task(name: "Insert Perm Task", status: true),
    Task(name: "Work on that long project", date: DateTime(2025, 12, 10), status: false),
  ];
  
  
  // ####################
  // ##### CALENDAR #####
  // ####################
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _onDayTapped(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _handleDaySelection(selectedDay);
  }

  void _handleDaySelection(DateTime day) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected day: ${day.day}/${day.month}/${day.year}'),
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
                child: Text(_currentDate ?? DateFormat('MMMM d, yyyy').format(DateTime.now()))
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
                    firstDay: DateTime.utc(2020, 1, 1), // Start of the calendar range
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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getDayFile(DateTime date) async {
    var day = DateFormat('yyyy-mm-dd').format(date);
    // change _currentDate into yyyy-mm-dd,
    final path = await _localPath;
    return File('$path/$day.json');
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

  void saveDay() async {
    final Map<String, dynamic> dayData = {
      'journal': _markdownController.text,
      'tasks': taskList.map((task) => task.toJson()).toList(),
      'date': _currentDate,
    };
    String jsonString = jsonEncode(dayData);
    final file = await _getDayFile(DateTime.now());
    await file.writeAsString(jsonString);
  }

  void loadDay() async {
    // using path provider, somehow.
  }
}


