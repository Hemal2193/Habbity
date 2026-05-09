import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Habit {
  final String id;
  final String name;
  final String? description;
  final Color color;
  final IconData icon;
  final Map<String, bool> completionDates; // Date string -> completed

  Habit({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    Map<String, bool>? completionDates,
  }) : completionDates = completionDates ?? {};

  int get currentStreak {
    if (completionDates.isEmpty) return 0;

    List<DateTime> completedDates = completionDates.entries
        .where((e) => e.value == true)
        .map((e) => DateTime.parse(e.key))
        .toList()
      ..sort();

    if (completedDates.isEmpty) return 0;

    int streak = 0;
    DateTime date = completedDates.last;

    while (true) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      if (completionDates[dateStr] == true) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int get longestStreak {
    if (completionDates.isEmpty) return 0;

    List<String> sortedDates = completionDates.keys.toList()..sort();
    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (String dateStr in sortedDates) {
      if (completionDates[dateStr] != true) continue;

      DateTime date = DateTime.parse(dateStr);

      if (lastDate == null || date.difference(lastDate).inDays == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 1;
      }
      lastDate = date;
    }

    return maxStreak;
  }

  double get completionRate {
    if (completionDates.isEmpty) return 0.0;
    int completed = completionDates.values.where((v) => v).length;
    return completed / completionDates.length;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'color': color.value,
    'icon': icon.codePoint,
    'completionDates': completionDates,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    color: Color(json['color']),
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    completionDates: Map<String, bool>.from(json['completionDates'] ?? {}),
  );
}
