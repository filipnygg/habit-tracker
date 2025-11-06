import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const HabitTrackerApp());
}

/// ----------------------------
/// APP ROOT & THEME
/// ----------------------------
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
    // Zen Mint palette
    const mint = Color(0xFFA8E6CF);
    const aqua = Color(0xFFAEFFFF);
    const ivory = Color(0xFFFAFAFA);
    const softGraphite = Color(0xFF1E1E22);
    const graphiteCard = Color(0xFF26272B);

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        primary: mint,
        secondary: aqua,
        surface: ivory, // modern replacement for background
      ),
      scaffoldBackgroundColor: ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        brightness: Brightness.dark,
        primary: mint,
        secondary: aqua,
        surface: softGraphite,
      ),
      scaffoldBackgroundColor: const Color(0xFF202125), // softer than black
      cardColor: graphiteCard.withValues(alpha: 0.9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white70,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
      cardTheme: CardThemeData(
        color: graphiteCard.withValues(alpha: 0.9),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );

    return MaterialApp(
      title: 'Habits',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: HomePage(toggleTheme: _toggleTheme),
    );
  }
}

/// ----------------------------
/// MODEL
/// ----------------------------
class Habit {
  String name;
  String category;
  DateTime startDate;
  DateTime endDate;
  List<int> activeDays; // 1=Mon..7=Sun
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

/// ----------------------------
/// ANIMATED BACKGROUND
/// ----------------------------
class ZenAnimatedBackground extends StatefulWidget {
  final Widget child;
  const ZenAnimatedBackground({super.key, required this.child});

  @override
  State<ZenAnimatedBackground> createState() => _ZenAnimatedBackgroundState();
}

class _ZenAnimatedBackgroundState extends State<ZenAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Alignment> _begin;
  late final Animation<Alignment> _end;

  @override
  void initState() {
    super.initState();
    // softer, slower motion
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat(reverse: true);
    _begin = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _end = AlignmentTween(
      begin: Alignment(0.8, -0.8),
      end: Alignment(-0.8, 0.8),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? [const Color(0xFF1E1E22), const Color(0xFF2B2C31), const Color(0xFFA8E6CF)]
        : [const Color(0xFFA8E6CF), const Color(0xFFAEFFFF), const Color(0xFFFFFFFF)];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: _begin.value,
                  end: _end.value,
                  colors: colors,
                  transform: const GradientRotation(0.1),
                ),
              ),
            ),
            // soft veil
            Container(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.15),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

/// ----------------------------
/// ANIMATED BUTTON
/// ----------------------------
class ZenGradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ZenGradientButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<ZenGradientButton> createState() => _ZenGradientButtonState();
}

class _ZenGradientButtonState extends State<ZenGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Alignment> _begin;
  late final Animation<Alignment> _end;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14), // slower
    )..repeat(reverse: true);

    _begin = AlignmentTween(
      begin: Alignment.topLeft,
      end: Alignment.centerRight, // smaller travel
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _end = AlignmentTween(
      begin: const Alignment(0.6, -0.6),
      end: const Alignment(-0.4, 0.6),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? [const Color(0xFF3A3B40), const Color(0xFFA8E6CF)]
        : [const Color(0xFFA8E6CF), const Color(0xFFAEFFFF)];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _begin.value,
              end: _end.value,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon,
                        size: 24,
                        color: isDark ? Colors.white : Colors.black87),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ----------------------------
/// HOME PAGE (grouped, centered, bubbly)
/// ----------------------------
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
      'habits',
      habits.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void _addHabit(Habit habit) {
    setState(() => habits.add(habit));
    _saveHabits();
  }

  void _updateHabit(Habit habit) {
    setState(() {}); // mutated in place
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
      if (mounted) Navigator.pop(context);
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

    // Categories for AddHabit dropdown
    final categories = habits
        .map((h) => h.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final secondaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

    return ZenAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 86, // breathing room
          leading: IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Habits v2.3 Zen Mint"),
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
          title: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                const Text("Today's Habits", textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(today),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          centerTitle: true,
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: grouped.entries.map((entry) {
                      final cat = entry.key;
                      final list = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Centered category title, same tone as headers
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                cat,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: secondaryTextColor,
                                      letterSpacing: 0.3,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...list.map((habit) {
                              final done = habit.completedDays.any(
                                (d) => DateUtils.isSameDay(d, today),
                              );
                              return Card(
                                elevation: 4,
                                shadowColor:
                                    Colors.black.withValues(alpha: 0.08),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        habit.name,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FilledButton.tonalIcon(
                                            onPressed: () =>
                                                _editNoteFor(habit, today),
                                            icon: const Icon(
                                                Icons.note_add_outlined),
                                            label: const Text("Note"),
                                            style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Check button matches Note style
                                          FilledButton.tonalIcon(
                                            onPressed: () {
                                              setState(() {
                                                if (done) {
                                                  habit.completedDays
                                                      .removeWhere((d) =>
                                                          DateUtils.isSameDay(
                                                              d, today));
                                                } else {
                                                  final exists = habit
                                                      .completedDays
                                                      .any((d) => DateUtils
                                                          .isSameDay(
                                                              d, today));
                                                  if (!exists) {
                                                    habit.completedDays
                                                        .add(today);
                                                  }
                                                }
                                                _saveHabits();
                                              });
                                            },
                                            icon: Icon(done
                                                ? Icons.check_circle
                                                : Icons
                                                    .radio_button_unchecked),
                                            label: Text(
                                                done ? "Checked" : "Check"),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.25),
                                              foregroundColor:
                                                  secondaryTextColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        habit.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: secondaryTextColor),
                                      ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () {
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
                                        child: Text(
                                          "Details",
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
        // Floating gradient buttons (no container), lifted higher
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: ZenGradientButton(
                  icon: Icons.list,
                  label: "All Habits",
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
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ZenGradientButton(
                  icon: Icons.add,
                  label: "New Habit",
                  onPressed: () async {
                    final newHabit = await Navigator.push<Habit>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddHabitPage(
                          existingCategories: categories,
                        ),
                      ),
                    );
                    if (newHabit != null) _addHabit(newHabit);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// ADD HABIT PAGE (with categories)
/// ----------------------------
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
    return ZenAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("New Habit")),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Habit name"),
            ),
            const SizedBox(height: 12),
            if (widget.existingCategories.isNotEmpty)
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
                labelText: widget.existingCategories.isNotEmpty
                    ? "Or create new category"
                    : "Category",
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
              spacing: 6,
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
            ZenGradientButton(
              icon: Icons.check_rounded,
              label: "Add Habit",
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final category = finalCategory;
                final active = selectedDays.isEmpty
                    ? [1, 2, 3, 4, 5, 6, 7]
                    : selectedDays;

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
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// ALL HABITS LIST
/// ----------------------------
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
    final secondaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

    return ZenAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("All Habits")),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: habits.length,
          itemBuilder: (_, i) {
            final h = habits[i];
            return Card(
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: Text(h.name, textAlign: TextAlign.center),
                subtitle:
                    Text(h.category, textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor)),
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
            );
          },
        ),
      ),
    );
  }
}

/// ----------------------------
/// HABIT DETAIL (progress, history, notes)
/// ----------------------------
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
    final dates = <DateTime>[];
    DateTime d = DateTime(widget.habit.startDate.year,
        widget.habit.startDate.month, widget.habit.startDate.day);
    final end = DateTime(widget.habit.endDate.year, widget.habit.endDate.month,
        widget.habit.endDate.day);
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
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(5),
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

    final secondaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

    return ZenAnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(widget.habit.name)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Category: ${widget.habit.category}",
                textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 6),
            Text("Start: ${DateFormat.yMMMd().format(widget.habit.startDate)}",
                textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor)),
            Text("End: ${DateFormat.yMMMd().format(widget.habit.endDate)}",
                textAlign: TextAlign.center, style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 14),
            const Text("Progress", textAlign: TextAlign.center),
            _segmentedProgressBar(dates),
            Text(
              "$completedCount / ${widget.habit.goalDays} days completed",
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 18),
            const Text("History", textAlign: TextAlign.center),
            const SizedBox(height: 10),
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
                tileColor = Colors.grey.withValues(alpha: 0.08);
                icon = Icons.lock_outline;
                iconColor = Colors.grey;
                style = style.copyWith(color: Colors.grey);
              } else if (done) {
                tileColor =
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);
                icon = Icons.check_circle_rounded;
                iconColor = Theme.of(context).colorScheme.primary;
                style = style.copyWith(fontWeight: FontWeight.w700);
              } else {
                tileColor = Colors.redAccent.withValues(alpha: 0.08);
                icon = unlocked
                    ? Icons.radio_button_unchecked
                    : Icons.cancel_outlined;
                iconColor = unlocked ? Colors.grey : Colors.redAccent;
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(DateFormat.yMMMMd().format(d), style: style),
                  subtitle: widget.habit.notes.containsKey(key)
                      ? Text(widget.habit.notes[key]!)
                      : null,
                  onTap: () {
                    if (isFuture) return;
                    if (done) {
                      _toggleComplete(d);
                    } else {
                      if (unlocked) _toggleComplete(d);
                    }
                  },
                  onLongPress: () {
                    if (!isFuture && !done && !unlocked) {
                      setState(() => _unlockedDays.add(key));
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
            ZenGradientButton(
              icon: Icons.delete_outline,
              label: "Delete Habit",
              onPressed: () => widget.onDelete(widget.habit),
            ),
          ],
        ),
      ),
    );
  }
}
