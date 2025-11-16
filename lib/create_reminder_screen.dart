import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:note_taker/reminder_provider.dart';
import 'package:note_taker/utils/assets_manager.dart';
import 'package:provider/provider.dart';

class CreateReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const CreateReminderScreen({super.key, this.reminder});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  late bool _dateEnabled;
  late int _priority;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _repeatValue;
  late final TextEditingController _notesController;
  int? _selectedColorValue;
  String? _selectedTone;

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Color> _crayonColors = [
    const Color(0xFFFF6961), // Red
    const Color(0xFFFFB447), // Orange
    const Color(0xFFFDFD96), // Yellow
    const Color(0xFF77DD77), // Green
    const Color(0xFFAEC6CF), // Blue
    const Color(0xFFC3B1E1), // Purple
    const Color(0xFFF49AC2), // Pink
    const Color(0xFFDEA5A4), // Brown
  ];

  // Colors from mockup
  static const Color appBlack = Color(0xFF000000);
  static const Color appGray = Color(0xFF1C1C1E);
  static const Color appGrayLight = Color(0xFF2C2C2E);
  static const Color appGrayText = Color(0xFF8E8E93);
  static const Color appBlue = Color(0xFF0A84FF);
  static const Color appGreen = Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _dateEnabled = reminder.isEnabled;
      _priority = reminder.priority;
      _selectedDate = reminder.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(reminder.dateTime);
      _repeatValue = reminder.repeat;
      _notesController = TextEditingController(text: reminder.notes);
      _selectedColorValue = reminder.color;
      _selectedTone = reminder.tone;
    } else {
      _dateEnabled = true;
      _priority = 1;
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _repeatValue = 'Never';
      _notesController = TextEditingController();
      _selectedColorValue = null;
      _selectedTone = AssetsManager.notificationTones.keys.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showRepeatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appGray,
          title: const Text('Repeat', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Never', 'Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map((String value) {
                return RadioListTile<String>(
                  title: Text(value, style: const TextStyle(color: Colors.white)),
                  value: value,
                  groupValue: _repeatValue,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _repeatValue = newValue;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: appBlue,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showToneDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appGray,
          title: const Text('Notification Tone', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AssetsManager.notificationTones.keys.map((String name) {
                return RadioListTile<String>(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  value: name,
                  groupValue: _selectedTone,
                  secondary: IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: () {
                      _audioPlayer.play(AssetSource(AssetsManager.notificationTones[name]!));
                    },
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTone = newValue;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: appBlue,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _getPriorityDescription() {
    switch (_priority) {
      case 0:
        return 'A notification will appear inside the app when you open it.';
      case 1:
        return 'A standard notification will appear in your device\'s notification panel.';
      case 2:
        return 'A full-screen notification will appear with all the details.';
      default:
        return '';
    }
  }

  void _saveReminder() {
    final notes = _notesController.text;
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (widget.reminder != null) {
      // Update existing reminder
      final reminder = widget.reminder!;
      reminder.notes = notes;
      reminder.dateTime = dateTime;
      reminder.repeat = _repeatValue;
      reminder.priority = _priority;
      reminder.isEnabled = _dateEnabled;
      reminder.color = _selectedColorValue;
      reminder.tone = _selectedTone;
      Provider.of<ReminderProvider>(context, listen: false)
          .updateReminder(reminder);
    } else {
      // Add new reminder
      final newReminder = Reminder()
        ..notes = notes
        ..dateTime = dateTime
        ..repeat = _repeatValue
        ..priority = _priority
        ..isEnabled = _dateEnabled
        ..color = _selectedColorValue
        ..tone = _selectedTone;
      Provider.of<ReminderProvider>(context, listen: false)
          .addReminder(newReminder);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBlack,
      appBar: AppBar(
        backgroundColor: appBlack,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: appBlue, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text(widget.reminder == null ? 'Set Reminder' : 'Edit Reminder',
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text('Done',
                style: TextStyle(
                    color: appBlue, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: appGrayLight,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateTimeSection(),
            const SizedBox(height: 24),
            _buildRepeatSection(),
            const SizedBox(height: 24),
            _buildToneSection(),
            const SizedBox(height: 24),
            _buildPrioritySection(),
            const SizedBox(height: 24),
            _buildColorSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              Switch(
                value: _dateEnabled,
                onChanged: (value) {
                  setState(() {
                    _dateEnabled = value;
                  });
                },
                activeColor: appGreen,
              ),
            ],
          ),
          const Divider(color: appGrayLight, height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _dateEnabled ? _selectDate : null,
                  child: _buildPickerMock(Icons.calendar_today,
                      DateFormat.yMMMd().format(_selectedDate)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _dateEnabled ? _selectTime : null,
                  child: _buildPickerMock(
                      Icons.access_time, _selectedTime.format(context)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPickerMock(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: appGrayLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(color: Colors.white)),
            ],
          ),
          const Icon(Icons.chevron_right, color: appGrayText, size: 20),
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    return GestureDetector(
      onTap: _showRepeatDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Repeat',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(_repeatValue,
                    style: const TextStyle(color: appGrayText, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: appGrayText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneSection() {
    return GestureDetector(
      onTap: _showToneDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notification Tone',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            Row(
              children: [
                Text(_selectedTone ?? 'Default',
                    style: const TextStyle(color: appGrayText, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: appGrayText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          CupertinoSlidingSegmentedControl<int>(
            children: const {
              0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Low')),
              1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Medium')),
              2: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('High')),
            },
            groupValue: _priority,
            onValueChanged: (value) {
              if (value != null) {
                setState(() {
                  _priority = value;
                });
              }
            },
            backgroundColor: appGrayLight,
            thumbColor: appBlue,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _getPriorityDescription(),
              style: const TextStyle(color: appGrayText, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _crayonColors.map((color) {
              final isSelected = _selectedColorValue == color.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorValue = color.value;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a note to your reminder...',
              hintStyle: const TextStyle(color: appGrayText),
              filled: true,
              fillColor: appGrayLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

