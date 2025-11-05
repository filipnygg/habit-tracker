import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = newMode);
    prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.indigo,
          secondary: Colors.indigoAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

class Habit {
  String name;
  String category;
  DateTime startDate;
  DateTime endDate;
  List<int> activeDays;
  int goalDays;
  List<DateTime> completedDays;
  Map<String, String> notes;

  Habit({
    required this.name,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.activeDays,
    required this.goalDays,
    required this.completedDays,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'activeDays': activeDays,
        'goalDays': goalDays,
        'completedDays':
            completedDays.map((d) => d.toIso8601String()).toList(),
        'notes': notes,
      };

  static Habit fromJson(Map<String, dynamic> json) => Habit(
        name: json['name'],
        category: json['category'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        activeDays: List<int>.from(json['activeDays']),
        goalDays: json['goalDays'],
        completedDays: (json['completedDays'] as List)
            .map((d) => DateTime.parse(d))
            .toList(),
        notes: Map<String, String>.from(json['notes']),
      );
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({super.key, required this.toggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Habit> habits = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('habits') ?? [];
    setState(() {
      habits = data.map((e) => Habit.fromJson(jsonDecode(e))).toList();
      isLoading = false;
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'habits', habits.map((e) => jsonEncode(e.toJson())).toList());
  }

  void _addHabit(Habit habit) {
    setState(() {
      habits.add(habit);
    });
    _saveHabits();
  }

  void _updateHabit(Habit habit) {
    setState(() {});
    _saveHabits();
  }

  void _deleteHabit(Habit habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Delete this habit?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent.shade100,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        habits.remove(habit);
      });
      _saveHabits();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekday = today.weekday;
    final todayHabits = habits.where((h) {
      return h.activeDays.contains(weekday) &&
          !today.isBefore(h.startDate) &&
          !today.isAfter(h.endDate);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Habit Tracker v1.0"),
                content: const Text("Made by Filip Nygren"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Habits"),
            Text(DateFormat('EEEE, MMMM d').format(today),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : todayHabits.isEmpty
              ? const Center(child: Text("No habits for today"))
              : ListView(
                  children: todayHabits.map((habit) {
                    final done = habit.completedDays
                        .any((d) => DateUtils.isSameDay(d, today));
                    return ListTile(
                      title: Text(habit.name),
                      subtitle: Text(habit.category),
                      trailing: Checkbox(
                        value: done,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              habit.completedDays.add(today);
                            } else {
                              habit.completedDays.removeWhere(
                                (d) => DateUtils.isSameDay(d, today),
                              );
                            }
                            _saveHabits();
                          });
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HabitDetailPage(
                              habit: habit,
                              onDelete: _deleteHabit,
                              onUpdate: _updateHabit,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllHabitsPage(
                        habits: habits,
                        onUpdate: _updateHabit,
                        onDelete: _deleteHabit,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.list, size: 24),
                  label: const Text(
                    "All Habits",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final newHabit = await Navigator.push<Habit>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddHabitPage(),
                      ),
                    );
                    if (newHabit != null) _addHabit(newHabit);
                  },
                  icon: const Icon(Icons.add, size: 26),
                  label: const Text(
                    "New Habit",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  List<int> selectedDays = [];
  int goalDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Habit")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Habit name"),
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text("Start Date"),
              subtitle: Text(DateFormat.yMMMd().format(startDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: startDate,
                );
                if (picked != null) {
                  setState(() {
                    startDate = picked;
                    endDate = startDate.add(Duration(days: goalDays));
                  });
                }
              },
            ),
            ListTile(
              title: const Text("End Date"),
              subtitle: Text(DateFormat.yMMMd().format(endDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: startDate,
                  lastDate: DateTime(2100),
                  initialDate: endDate,
                );
                if (picked != null) setState(() => endDate = picked);
              },
            ),
            const SizedBox(height: 12),
            const Text("Active Days"),
            Wrap(
              spacing: 4,
              children: List.generate(7, (i) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final selected = selectedDays.contains(i + 1);
                return FilterChip(
                  label: Text(days[i]),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedDays.add(i + 1);
                      } else {
                        selectedDays.remove(i + 1);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: goalDays,
              decoration: const InputDecoration(labelText: "Goal Duration"),
              items: const [
                DropdownMenuItem(value: 30, child: Text("30 days")),
                DropdownMenuItem(value: 60, child: Text("60 days")),
                DropdownMenuItem(value: 90, child: Text("90 days")),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    goalDays = v;
                    endDate = startDate.add(Duration(days: goalDays));
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                final habit = Habit(
                  name: nameCtrl.text,
                  category: categoryCtrl.text,
                  startDate: startDate,
                  endDate: endDate,
                  activeDays: selectedDays.isEmpty
                      ? [1, 2, 3, 4, 5, 6, 7]
                      : selectedDays,
                  goalDays: goalDays,
                  completedDays: [],
                  notes: {},
                );
                Navigator.pop(context, habit);
              },
              child: const Text("Add Habit"),
            ),
          ],
        ),
      ),
    );
  }
}

class AllHabitsPage extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit) onUpdate;
  final Function(Habit) onDelete;

  const AllHabitsPage({
    super.key,
    required this.habits,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Habits")),
      body: ListView(
        children: habits
            .map(
              (h) => ListTile(
                title: Text(h.name),
                subtitle: Text(h.category),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HabitDetailPage(
                        habit: h,
                        onDelete: onDelete,
                        onUpdate: onUpdate,
                      ),
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class HabitDetailPage extends StatefulWidget {
  final Habit habit;
  final Function(Habit) onUpdate;
  final Function(Habit) onDelete;

  const HabitDetailPage({
    super.key,
    required this.habit,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  @override
  Widget build(BuildContext context) {
    final completedCount = widget.habit.completedDays.length;
    final progress =
        (completedCount / widget.habit.goalDays).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Category: ${widget.habit.category}"),
            Text(
                "Start Date: ${DateFormat.yMMMd().format(widget.habit.startDate)}"),
            Text(
                "End Date: ${DateFormat.yMMMd().format(widget.habit.endDate)}"),
            const SizedBox(height: 10),
            Text(
              "Active Days: ${widget.habit.activeDays.map((d) => DateFormat.E().format(DateTime(2023, 1, d + 1))).join(', ')}",
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: progress),
            Text("$completedCount / ${widget.habit.goalDays} days completed"),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade100,
              ),
              onPressed: () => widget.onDelete(widget.habit),
              child: const Text("Delete Habit"),
            ),
          ],
        ),
      ),
    );
  }
}
