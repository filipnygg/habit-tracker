import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HabitPage(),
    );
  }
}

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  List<Map<String, dynamic>> habits = [];
  late String todayKey;
  late DateTime today;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    todayKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('habits');
    if (saved != null) {
      setState(() {
        habits = List<Map<String, dynamic>>.from(json.decode(saved));
      });
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('habits', json.encode(habits));
  }

  void _addHabit() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    int duration = 30;
    bool useEndDate = false;
    DateTime? selectedEndDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('New Habit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Habit name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g. Fitness, Mindset)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Set specific end date'),
                      value: useEndDate,
                      onChanged: (value) {
                        setStateDialog(() {
                          useEndDate = value;
                        });
                      },
                    ),
                    if (useEndDate)
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedEndDate = picked;
                            });
                          }
                        },
                        child: Text(
                          selectedEndDate == null
                              ? 'Select end date'
                              : 'End: ${selectedEndDate!.toLocal().toString().split(" ")[0]}',
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: duration,
                        decoration: const InputDecoration(
                          labelText: 'Goal Duration',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(value: 60, child: Text('60 days')),
                          DropdownMenuItem(value: 90, child: Text('90 days')),
                        ],
                        onChanged: (val) {
                          setStateDialog(() {
                            duration = val!;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;

                    final startDate = DateTime.now();
                    final endDate = useEndDate && selectedEndDate != null
                        ? selectedEndDate!
                        : startDate.add(Duration(days: duration));

                    final durationDays =
                        endDate.difference(startDate).inDays.clamp(1, 9999);

                    setState(() {
                      habits.add({
                        'name': nameController.text.trim(),
                        'category': categoryController.text.trim().isEmpty
                            ? 'General'
                            : categoryController.text.trim(),
                        'startDate': startDate.toIso8601String(),
                        'endDate': endDate.toIso8601String(),
                        'duration': durationDays,
                        'done': {},
                        'notes': {},
                      });
                    });
                    _saveHabits();
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isHabitActive(Map<String, dynamic> habit) {
    final startDate = DateTime.parse(habit['startDate']);
    final endDate = DateTime.parse(habit['endDate']);
    return today.isAfter(startDate.subtract(const Duration(days: 1))) &&
        today.isBefore(endDate.add(const Duration(days: 1)));
  }

  void _toggleHabit(int index) {
    final habit = habits[index];
    final doneMap = habit['done'] ?? {};
    final currentState = doneMap[todayKey] ?? false;
    setState(() {
      doneMap[todayKey] = !currentState;
      habit['done'] = doneMap;
    });
    _saveHabits();
  }

  void _openNotesDialog(int index) {
    final habit = habits[index];
    final notesMap = habit['notes'] ?? {};
    final currentNote = notesMap[todayKey] ?? '';
    final controller = TextEditingController(text: currentNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notes for ${habit['name']} (${todayKey})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Write your note for today...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    if (controller.text.trim().isNotEmpty) {
                      notesMap[todayKey] = controller.text.trim();
                    } else {
                      notesMap.remove(todayKey);
                    }
                    habit['notes'] = notesMap;
                  });
                  _saveHabits();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHabitDetails(Map<String, dynamic> habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailPage(habit: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeHabits =
        habits.where((habit) => _isHabitActive(habit)).toList();

    // Group habits by category
    final Map<String, List<Map<String, dynamic>>> groupedHabits = {};
    for (var habit in activeHabits) {
      final category = habit['category'] ?? 'General';
      groupedHabits.putIfAbsent(category, () => []).add(habit);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today’s Habits'),
        centerTitle: true,
        elevation: 1,
      ),
      body: groupedHabits.isEmpty
          ? const Center(
              child: Text(
                "No active habits today.\nTap + to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: groupedHabits.entries.map((entry) {
                final category = entry.key;
                final habits = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Text(
                        category,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...habits.map((habit) {
                      final doneMap = habit['done'] ?? {};
                      final notesMap = habit['notes'] ?? {};
                      final isDone = doneMap[todayKey] ?? false;
                      final hasNote = notesMap[todayKey] != null;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0.5,
                        child: ListTile(
                          leading: Checkbox(
                            shape: const CircleBorder(),
                            value: isDone,
                            onChanged: (_) =>
                                _toggleHabit(this.habits.indexOf(habit)),
                          ),
                          title: GestureDetector(
                            onTap: () => _openHabitDetails(habit),
                            child: Text(
                              habit['name'],
                              style: TextStyle(
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isDone
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                          ),
                          subtitle: hasNote
                              ? Text(
                                  '📝 ${notesMap[todayKey]}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(color: Colors.black54),
                                )
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.note_alt_outlined),
                            onPressed: () =>
                                _openNotesDialog(this.habits.indexOf(habit)),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHabit,
        icon: const Icon(Icons.add),
        label: const Text('New Habit'),
      ),
    );
  }
}

class HabitDetailPage extends StatelessWidget {
  final Map<String, dynamic> habit;

  const HabitDetailPage({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final doneMap = Map<String, dynamic>.from(habit['done'] ?? {});
    final notesMap = Map<String, dynamic>.from(habit['notes'] ?? {});
    final startDate = DateTime.parse(habit['startDate']);
    final endDate = DateTime.parse(habit['endDate']);
    final duration = habit['duration'] as int;

    final completedDays = doneMap.keys.length;
    final progress = (completedDays / duration).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Progress: $completedDays / $duration days',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 20),
            Text(
              'Category: ${habit['category'] ?? 'General'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Text(
              'Start: ${startDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              'End: ${endDate.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Completed Days:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (doneMap.isEmpty)
              const Text('No days completed yet.'),
            for (final date in doneMap.keys)
              ListTile(
                title: Text(date),
                subtitle: notesMap[date] != null
                    ? Text('📝 ${notesMap[date]}')
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

