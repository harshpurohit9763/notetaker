import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime? createdAt;

  @HiveField(4)
  late String noteType; // "text" or "voice"

  @HiveField(5)
  late DateTime? lastUpdatedAt;

  @HiveField(6)
  late bool? isArchived = false;

  @HiveField(7)
  late bool? isLocked = false;
}
