import 'package:talker/talker.dart';

class LoggerService {
  final Talker _talker = Talker();

  Talker get talker => _talker;

  void logNoteAdded(String noteTitle) {
    _talker.log('Note added: $noteTitle', logLevel: LogLevel.info);
  }

  void logReminderAdded(String reminderTitle) {
    _talker.log('Reminder added: $reminderTitle', logLevel: LogLevel.info);
  }

  void logSuccess(String message) {
    _talker.log(message, logLevel: LogLevel.info);
  }

  void logError(String message, dynamic error, StackTrace? stackTrace) {
    _talker.log(message, logLevel: LogLevel.error, stackTrace: stackTrace);
  }

  void logWarning(String message) {
    _talker.log(message, logLevel: LogLevel.warning);
  }
}
