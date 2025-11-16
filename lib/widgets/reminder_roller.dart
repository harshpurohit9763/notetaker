import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/reminder_model.dart';

enum RollerDirection { left, right }

class ReminderRoller extends StatelessWidget {
  final Reminder reminder;
  final RollerDirection direction;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onExpand;

  const ReminderRoller({
    super.key,
    required this.reminder,
    required this.direction,
    required this.isExpanded,
    required this.onTap,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExpanded ? onTap : onExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: isExpanded ? 280 : 40,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF), // app-blue
          borderRadius: direction == RollerDirection.right
              ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: isExpanded
            ? _buildExpandedContent()
            : _buildCollapsedContent(),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.notifications_active, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reminder.notes.isNotEmpty ? reminder.notes : 'Untitled Reminder',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.jm().format(reminder.dateTime),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedContent() {
    return const Center(
      child: Icon(Icons.notifications, color: Colors.white, size: 20),
    );
  }
}
