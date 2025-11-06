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
      title: 'Habits',
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
  List<int> activeDays; // 1=Mon ... 7=Sun
  int goalDays;
  List<DateTime> completedDays; // unique dates
  Map<String, String> notes; // yyyy-MM-dd -> note

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
    setState(() {}); // mutate in place
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

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _editNoteFor(Habit habit, DateTime day) async {
    final key = _dateKey(day);
    final controller = TextEditingController(text: habit.notes[key] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Note • ${DateFormat.yMMMd().format(day)}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add a note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      setState(() {
        final txt = controller.text.trim();
        if (txt.isEmpty) {
          habit.notes.remove(key);
        } else {
          habit.notes[key] = txt;
        }
      });
      _saveHabits();
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

    // Group by category
    final grouped = <String, List<Habit>>{};
    for (final h in todayHabits) {
      final cat = h.category.trim().isEmpty ? "Other" : h.category;
      grouped.putIfAbsent(cat, () => []).add(h);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Habits v2.1"),
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
                  padding: const EdgeInsets.only(bottom: 80),
                  children: grouped.entries.map((entry) {
                    final cat = entry.key;
                    final list = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...list.map((habit) {
                            final done = habit.completedDays
                                .any((d) => DateUtils.isSameDay(d, today));
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(habit.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Add note',
                                      icon: const Icon(Icons.note_add_outlined),
                                      onPressed: () => _editNoteFor(habit, today),
                                    ),
                                    Checkbox(
                                      value: done,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            final exists = habit.completedDays.any(
                                              (d) => DateUtils.isSameDay(d, today),
                                            );
                                            if (!exists) {
                                              habit.completedDays.add(today);
                                            }
                                          } else {
                                            habit.completedDays.removeWhere(
                                              (d) => DateUtils.isSameDay(d, today),
                                            );
                                          }
                                          _saveHabits();
                                        });
                                      },
                                    ),
                                  ],
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
                              ),
                            );
                          }).toList(),
                        ],
                      ),
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
                  label: const Text("All Habits", style: TextStyle(fontSize: 18)),
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
                    final categories = habits
                        .map((h) => h.category.trim())
                        .where((c) => c.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                    final newHabit = await Navigator.push<Habit>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddHabitPage(existingCategories: categories),
                      ),
                    );
                    if (newHabit != null) _addHabit(newHabit);
                  },
                  icon: const Icon(Icons.add, size: 26),
                  label: const Text("New Habit", style: TextStyle(fontSize: 18)),
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
  final List<String> existingCategories;
  const AddHabitPage({super.key, required this.existingCategories});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final nameCtrl = TextEditingController();
  final newCategoryCtrl = TextEditingController();
  String? selectedCategory;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  List<int> selectedDays = [];
  int goalDays = 30;

  String get finalCategory {
    final picked = (selectedCategory ?? '').trim();
    final typed = newCategoryCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = widget.existingCategories.isNotEmpty;

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
            const SizedBox(height: 12),
            if (hasCategories)
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: "Pick a category"),
                items: widget.existingCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCategory = v),
              ),
            TextField(
              controller: newCategoryCtrl,
              decoration: InputDecoration(
                labelText: hasCategories ? "Or create new category" : "Category",
              ),
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
                if (nameCtrl.text.trim().isEmpty) return;
                final category = finalCategory;
                final active =
                    selectedDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : selectedDays;

                final habit = Habit(
                  name: nameCtrl.text.trim(),
                  category: category,
                  startDate: startDate,
                  endDate: endDate,
                  activeDays: active,
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
  final Set<String> _unlockedDays = {}; // yyyy-MM-dd keys (long-press unlock)
  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  bool _isCompleted(DateTime day) =>
      widget.habit.completedDays.any((d) => DateUtils.isSameDay(d, day));

  void _toggleComplete(DateTime day) {
    setState(() {
      final idx = widget.habit.completedDays.indexWhere(
          (d) => DateUtils.isSameDay(d, day));
      if (idx >= 0) {
        widget.habit.completedDays.removeAt(idx);
      } else {
        widget.habit.completedDays.add(day);
      }
    });
    widget.onUpdate(widget.habit);
  }

  Future<void> _editNote(DateTime day) async {
    final key = _dateKey(day);
    final controller = TextEditingController(text: widget.habit.notes[key] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Note • ${DateFormat.yMMMd().format(day)}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Add a note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      setState(() {
        final txt = controller.text.trim();
        if (txt.isEmpty) {
          widget.habit.notes.remove(key);
        } else {
          widget.habit.notes[key] = txt;
        }
      });
      widget.onUpdate(widget.habit);
    }
  }

  List<DateTime> _activeDateRange() {
    // Only include dates on the habit's active weekdays.
    final dates = <DateTime>[];
    DateTime d = DateTime(widget.habit.startDate.year, widget.habit.startDate.month, widget.habit.startDate.day);
    final end = DateTime(widget.habit.endDate.year, widget.habit.endDate.month, widget.habit.endDate.day);
    while (!d.isAfter(end)) {
      if (widget.habit.activeDays.contains(d.weekday)) {
        dates.add(d);
      }
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  Widget _segmentedProgressBar(List<DateTime> days) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return Row(
      children: days.map((d) {
        final isFuture = d.isAfter(todayDate);
        final isDone = _isCompleted(d);
        Color c;
        if (isFuture) {
          c = Colors.grey.shade400;
        } else if (isDone) {
          c = Theme.of(context).colorScheme.primary;
        } else {
          c = Colors.redAccent; // missed
        }
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 6),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _activeDateRange();
    final completedCount = widget.habit.completedDays.length;
    final clampedTotal = widget.habit.goalDays > 0 ? widget.habit.goalDays : dates.length;
    final progressRatio =
        (completedCount / clampedTotal).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Category: ${widget.habit.category}"),
            Text("Start: ${DateFormat.yMMMd().format(widget.habit.startDate)}"),
            Text("End: ${DateFormat.yMMMd().format(widget.habit.endDate)}"),
            const SizedBox(height: 10),
            const Text("Progress"),
            _segmentedProgressBar(dates),
            Text("$completedCount / ${widget.habit.goalDays} days completed"),
            const SizedBox(height: 16),
            const Text("History"),
            const SizedBox(height: 8),
            ...dates.map((d) {
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              final isFuture = d.isAfter(todayDate);
              final done = _isCompleted(d);
              final key = _dateKey(d);
              final unlocked = _unlockedDays.contains(key);

              Color tileColor;
              IconData icon;
              Color iconColor;
              TextStyle style = Theme.of(context).textTheme.bodyMedium!;
              if (isFuture) {
                tileColor = Colors.grey.withOpacity(0.08);
                icon = Icons.lock_outline;
                iconColor = Colors.grey;
                style = style.copyWith(color: Colors.grey);
              } else if (done) {
                tileColor = Theme.of(context).colorScheme.primary.withOpacity(0.10);
                icon = Icons.check_circle_rounded;
                iconColor = Theme.of(context).colorScheme.primary;
                style = style.copyWith(fontWeight: FontWeight.w600);
              } else {
                tileColor = Colors.redAccent.withOpacity(0.08);
                icon = unlocked ? Icons.radio_button_unchecked : Icons.cancel_outlined;
                iconColor = unlocked ? Colors.grey : Colors.redAccent;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(DateFormat.yMMMMd().format(d), style: style),
                  subtitle: widget.habit.notes.containsKey(key)
                      ? Text(widget.habit.notes[key]!)
                      : null,
                  onTap: () {
                    if (isFuture) return; // cannot modify future
                    if (done) {
                      _toggleComplete(d);
                    } else {
                      if (unlocked) {
                        _toggleComplete(d);
                      }
                    }
                  },
                  onLongPress: () {
                    if (!isFuture && !done && !unlocked) {
                      setState(() {
                        _unlockedDays.add(key);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Day unlocked. Tap to mark as done.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  trailing: IconButton(
                    tooltip: "Add / Edit note",
                    icon: const Icon(Icons.note_add_outlined),
                    onPressed: () => _editNote(d),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
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
