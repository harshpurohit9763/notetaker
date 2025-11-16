import 'package:hive/hive.dart';

part 'reminder_model.g.dart';

@HiveType(typeId: 1)
class Reminder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String notes;

  @HiveField(2)
  late DateTime dateTime;

  @HiveField(3)
  late String repeat;

  @HiveField(4)
  late int priority;

  @HiveField(5)
  late bool isEnabled;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late bool isCompleted = false;

  @HiveField(8)
  int? color;

  @HiveField(9)
  String? tone;
}
