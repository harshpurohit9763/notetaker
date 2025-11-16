import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/create_reminder_screen.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:note_taker/reminder_provider.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  int _selectedSegment = 0; // 0 for Upcoming, 1 for Completed

  static const Color appGray = Color(0xFF1C1C1E);
  static const Color appGrayLight = Color(0xFF2C2C2E);
  static const Color appBlue = Color(0xFF0A84FF);
  static const Color appGrayText = Color(0xFF8E8E93);
  static const Color appGreen = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSegmentedControl(),
            Expanded(
              child: Consumer<ReminderProvider>(
                builder: (context, provider, child) {
                  final reminders = provider.reminders
                      .where((r) => r.isCompleted == (_selectedSegment == 1))
                      .toList();

                  if (reminders.isEmpty) {
                    return Center(
                        child: Text('No reminders.',
                            style: TextStyle(color: Colors.grey)));
                  }

                  return _buildRemindersList(reminders);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Reminders',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold)),
          Row(
            children: [
              _buildHeaderButton(Icons.search),
              const SizedBox(width: 10),
              _buildHeaderButton(Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: appGrayLight,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      height: 50, // increased height
      decoration: BoxDecoration(
        color: appGrayLight,
        borderRadius: BorderRadius.circular(25), // rounded corners for the whole container
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentItem('Upcoming', 0),
          ),
          Expanded(
            child: _buildSegmentItem('Completed', 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String title, int index) {
    final isSelected = _selectedSegment == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSegment = index;
        });
      },
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              )
            : null,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16, // increased font size
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersList(List<Reminder> reminders) {
    // This is a simplified grouping. A more robust solution would handle more date cases.
    final today = DateTime.now();
    final todayReminders = reminders
        .where((r) =>
            r.dateTime.year == today.year &&
            r.dateTime.month == today.month &&
            r.dateTime.day == today.day)
        .toList();
    final upcomingReminders = reminders.where((r) => !todayReminders.contains(r)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      children: [
        if (todayReminders.isNotEmpty && _selectedSegment == 0)
          _buildReminderGroup('Today', todayReminders),
        if (upcomingReminders.isNotEmpty && _selectedSegment == 0)
          _buildReminderGroup('Upcoming', upcomingReminders),
        if (_selectedSegment == 1)
          _buildReminderGroup('Completed', reminders),
      ],
    );
  }

  Widget _buildReminderGroup(String title, List<Reminder> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: appGray,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderItem(reminders[index]);
              },
              separatorBuilder: (context, index) =>
                  const Divider(color: appGrayLight, height: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderItem(Reminder reminder) {
    final bgColor = reminder.color != null ? Color(reminder.color!) : appGray;
    final textColor = _getContrastingTextColor(bgColor);
    final subtleTextColor = textColor.withOpacity(0.7);

    return Container(
      color: bgColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCheckbox(reminder),
        title: Text(
          reminder.notes,
          style: TextStyle(
            color: reminder.isCompleted ? appGrayText : textColor,
            decoration:
                reminder.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          'From: Meeting Notes', // Mock data
          style: TextStyle(color: reminder.isCompleted ? appGrayText : subtleTextColor, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat.jm().format(reminder.dateTime),
              style: TextStyle(color: textColor, fontSize: 14),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                reminder.isEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                color: reminder.isEnabled ? appBlue : subtleTextColor,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  reminder.isEnabled = !reminder.isEnabled;
                });
                Provider.of<ReminderProvider>(context, listen: false)
                    .updateReminder(reminder);

                Fluttertoast.showToast(
                    msg: reminder.isEnabled
                        ? 'Notification turned on for this reminder.'
                        : 'Notification turned off for this reminder.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.grey[800],
                    textColor: Colors.white,
                    fontSize: 16.0
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReminderScreen(reminder: reminder),
            ),
          );
        },
      ),
    );
  }

  Color _getContrastingTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Widget _buildCheckbox(Reminder reminder) {
    return InkWell(
      onTap: () {
        setState(() {
          reminder.isCompleted = !reminder.isCompleted;
        });
        Provider.of<ReminderProvider>(context, listen: false)
            .updateReminder(reminder);
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reminder.isCompleted ? appGreen : Colors.transparent,
          border: Border.all(
            color: reminder.isCompleted ? appGreen : appGrayText,
            width: 2,
          ),
        ),
        child: reminder.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.black)
            : null,
      ),
    );
  }
}
