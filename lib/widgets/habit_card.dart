import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool isCompleted = habit.completionDates[today] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            habit.color.withOpacity(0.3),
            habit.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? habit.color : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isCompleted
            ? [
                BoxShadow(
                  color: habit.color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [habit.color, habit.color.withOpacity(0.6)],
                          )
                        : null,
                    color: isCompleted ? null : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: habit.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : habit.icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (habit.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: habit.currentStreak > 0
                                ? Colors.orange
                                : Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Habit'),
                            content: Text('Are you sure you want to delete "${habit.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}