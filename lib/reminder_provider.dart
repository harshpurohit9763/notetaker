import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:note_taker/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class ReminderProvider with ChangeNotifier {
  final Box<Reminder> _remindersBox = Hive.box<Reminder>('reminders');
  final _uuid = Uuid();
  final NotificationService _notificationService = NotificationService();

  List<Reminder> get reminders => _remindersBox.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addReminder(Reminder reminder) async {
    reminder.id = _uuid.v4();
    reminder.createdAt = DateTime.now();
    await _remindersBox.put(reminder.id, reminder);

    if (reminder.isEnabled && reminder.priority > 0) {
      _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Reminder',
        body: reminder.notes,
        scheduledDate: reminder.dateTime,
        priority: reminder.priority,
        color: reminder.color != null ? Color(reminder.color!) : null,
      );
    }

    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await reminder.save();

    await _notificationService.cancelNotification(reminder.id.hashCode);

    if (reminder.isEnabled && reminder.priority > 0) {
      _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: 'Reminder',
        body: reminder.notes,
        scheduledDate: reminder.dateTime,
        priority: reminder.priority,
        color: reminder.color != null ? Color(reminder.color!) : null,
      );
    }

    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _notificationService.cancelNotification(id.hashCode);
    await _remindersBox.delete(id);
    notifyListeners();
  }

  List<Reminder> getDueLowPriorityReminders() {
    final now = DateTime.now();
    return _remindersBox.values
        .where((r) =>
            r.isEnabled &&
            !r.isCompleted &&
            r.priority == 0 &&
            r.dateTime.isBefore(now))
        .toList();
  }

  Future<void> disableReminder(Reminder reminder) async {
    reminder.isEnabled = false;
    await updateReminder(reminder);
  }
}
