import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_stats_card.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/edit_habit_dialog.dart';

class HabitTrackerHome extends StatefulWidget {
  const HabitTrackerHome({super.key});

  @override
  State<HabitTrackerHome> createState() => _HabitTrackerHomeState();
}

class _HabitTrackerHomeState extends State<HabitTrackerHome>
    with TickerProviderStateMixin {
  List<Habit> habits = [];
  int _selectedIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward(); // 👈 start animation immediately

    // Start animation after first frame is built to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    _loadHabits();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? habitsJson = prefs.getString('habits');

    if (habitsJson != null) {
      final List<dynamic> decoded = json.decode(habitsJson);
      setState(() {
        habits = decoded.map((h) => Habit.fromJson(h)).toList();
      });
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(habits.map((h) => h.toJson()).toList());
    await prefs.setString('habits', encoded);
  }

  void _toggleHabitCompletion(Habit habit) {
    setState(() {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      habit.completionDates[today] = !(habit.completionDates[today] ?? false);
      _saveHabits();
    });
  }

  void _addHabit(Habit habit) {
    setState(() {
      habits.add(habit);
      _saveHabits();
    });
  }

  void _deleteHabit(Habit habit) {
    setState(() {
      habits.remove(habit);
      _saveHabits();
    });
  }

  void _editHabit(Habit updatedHabit) {
    setState(() {
      int index = habits.indexWhere((h) => h.id == updatedHabit.id);
      if (index != -1) {
        habits[index] = updatedHabit;
        _saveHabits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade900,
                Colors.blue.shade900,
                Colors.purple.shade900,
              ],
            ),
          ),
          child: SafeArea(
            child: _selectedIndex == 0 ? _buildHabitsView() : _buildStatsView(),
          ),
        ),
        floatingActionButton: _selectedIndex == 0
            ? ScaleTransition(
                scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _fabController,
                    curve: Curves.easeOut,
                  ),
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddHabitDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Habit'),
                  backgroundColor: Colors.purple.shade600,
                ),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade900.withOpacity(0.9),
                Colors.blue.shade900.withOpacity(0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: NavigationBar(
              height: 50,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
                if (index == 0) {
                  _fabController.forward(from: 0.0);
                } else {
                  _fabController.reverse();
                }
              },
              backgroundColor: Colors.transparent,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  selectedIcon: Icon(Icons.check_circle),
                  label: 'Habits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  selectedIcon: Icon(Icons.analytics),
                  label: 'Statistics',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsView() {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 100,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'No habits yet',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the button below to add your first habit',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Habits',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              _buildTodayProgress(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              return HabitCard(
                habit: habits[index],
                onToggle: () => _toggleHabitCompletion(habits[index]),
                onDelete: () => _deleteHabit(habits[index]),
                onEdit: () => _showEditHabitDialog(habits[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodayProgress() {
    if (habits.isEmpty) return const SizedBox.shrink();

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int completed = habits
        .where((h) => h.completionDates[today] == true)
        .length;
    double progress = completed / habits.length;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  strokeCap: StrokeCap.round,
                  value: value,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$completed/${habits.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Today',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildOverallStats(),
          const SizedBox(height: 20),
          const Text(
            'Habit Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          if (habits.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 60,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'No habit data available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some habits to see detailed statistics',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...habits.map((habit) => HabitStatsCard(habit: habit)),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    int totalHabits = habits.length;
    int totalCompletions = habits.fold(
      0,
      (sum, h) => sum + h.completionDates.values.where((v) => v).length,
    );

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int todayCompleted = habits
        .where((h) => h.completionDates[today] == true)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700.withOpacity(0.5),
            Colors.blue.shade700.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Habits', '$totalHabits', Icons.list),
              _buildStatItem(
                'Total Completions',
                '$totalCompletions',
                Icons.check,
              ),
              _buildStatItem(
                'Today',
                '$todayCompleted/$totalHabits',
                Icons.today,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHabitDialog(onAdd: _addHabit),
    );
  }

  void _showEditHabitDialog(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => EditHabitDialog(habit: habit, onEdit: _editHabit),
    );
  }
}
