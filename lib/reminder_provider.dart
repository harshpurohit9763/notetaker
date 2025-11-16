import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:uuid/uuid.dart';

class ReminderProvider with ChangeNotifier {
  final Box<Reminder> _remindersBox = Hive.box<Reminder>('reminders');
  final _uuid = Uuid();

  List<Reminder> get reminders => _remindersBox.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addReminder(Reminder reminder) async {
    reminder.id = _uuid.v4();
    reminder.createdAt = DateTime.now();
    await _remindersBox.put(reminder.id, reminder);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await reminder.save();
    notifyListeners();
  }

  Future<void> deleteReminder(String id) async {
    await _remindersBox.delete(id);
    notifyListeners();
  }
}
