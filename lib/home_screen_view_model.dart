import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';
import 'package:note_taker/create_note_screen.dart';
import 'package:note_taker/create_reminder_screen.dart';
import 'package:note_taker/note_model.dart';
import 'package:note_taker/note_provider.dart';
import 'package:note_taker/reminder_model.dart';
import 'package:note_taker/reminder_provider.dart';
import 'package:note_taker/routes/route_manager.dart';
import 'package:note_taker/widgets/note_action_modal.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:note_taker/widgets/reminder_roller.dart';
import 'package:provider/provider.dart';
import 'package:note_taker/routes/note_action_modal_route.dart'; // Import the custom route

class HomeScreenViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  Reminder? rollerReminder;
  bool showRoller = false;
  bool isRollerExpanded = false;
  RollerDirection rollerDirection = RollerDirection.right;

  void onTabTapped(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void fabTapped(BuildContext context) {
    if (_selectedIndex == 0) {
      // Home/Notes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateNoteScreen(),
        ),
      );
    } else if (_selectedIndex == 1) {
      // Reminders
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateReminderScreen(),
        ),
      );
    }
  }

  void checkDueReminders(BuildContext context) {
    final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);
    final dueReminders = reminderProvider.getDueLowPriorityReminders();
    if (dueReminders.isNotEmpty) {
      // Show one by one
      displayRoller(dueReminders.first);
      reminderProvider.disableReminder(dueReminders.first);
    }
  }

  void displayRoller(Reminder reminder) {
    final direction = (_selectedIndex == 0 || _selectedIndex == 1)
        ? RollerDirection.right
        : RollerDirection.left;

    rollerReminder = reminder;
    rollerDirection = direction;
    showRoller = true;
    isRollerExpanded = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 4), () {
      if (showRoller) { // Only collapse if it's still shown
        isRollerExpanded = false;
        notifyListeners();
      }
    });
  }

  void expandRoller() {
    isRollerExpanded = true;
    notifyListeners();
  }

  void hideRoller() {
    showRoller = false;
    isRollerExpanded = false;
    notifyListeners();
  }

  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white), // Placeholder
            ),
          ),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 22, fontFamily: 'Inter'),
              children: [
                TextSpan(
                  text: 'Add ',
                  style: TextStyle(fontWeight: FontWeight.w300),
                ),
                TextSpan(
                  text: 'Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            children: [
              buildGlassyIconButton(Icons.search),
              const SizedBox(width: 10),
              buildGlassyIconButton(Icons.settings),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGlassyIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget buildSegmentTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildSegmentPill('Notes', isSelected: true),
          const SizedBox(width: 10),
          buildSegmentPill('Draw'),
        ],
      ),
    );
  }

  Widget buildSegmentPill(String text, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            isSelected ? Border.all(color: Colors.blue.withOpacity(0.5)) : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget buildTemplates(BuildContext context) {
    final List<NoteTemplate> templates = [
      NoteTemplate(
        title: 'Meeting Notes',
        content: 'Attendees:\n\nAgenda:\n\nAction Items:\n',
        icon: Icons.group,
        gradient:
            const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
      ),
      NoteTemplate(
        title: 'Quick Memo',
        content: '', // No content for a voice memo template
        icon: Icons.mic,
        gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrangeAccent]),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20.0, top: 10.0),
          child: Text(
            'Start with a template',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateNoteScreen(
                        templateTitle: template.title,
                        templateContent: template.content,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: template.gradient,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(template.icon, color: Colors.white, size: 30),
                      const SizedBox(height: 8),
                      Text(
                        template.title,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildNotesGrid() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        if (noteProvider.notes.isEmpty) {
          return const Center(
            child: Text(
              'No notes yet. Tap the + button to create one!',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          padding: const EdgeInsets.all(20),
          itemCount: noteProvider.notes.length,
          itemBuilder: (context, index) {
            final note = noteProvider.notes[index];
            return buildNoteCard(context, note); // Pass context here
          },
        );
      },
    );
  }

  Widget buildNoteCard(BuildContext context, Note note) {
    // Added BuildContext
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          RouteManager.notePreviewScreen,
          arguments: note,
        );
      },
      onLongPress: () {
        Navigator.push(
          context,
          NoteActionModalRoute(
            note: note,
            heroTag: 'note-modal-${note.id}',
          ),
        );
      },
      child: Hero(
        tag: 'note-modal-${note.id}',
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Image preview or text content
              Expanded(
                // Wrap the entire conditional content in Expanded
                child: note.noteType == 'text'
                    ? Builder(
                        builder: (context) {
                          final imageUrl =
                              _getFirstImageUrlFromDelta(note.content);

                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                // Changed from Image.network to Image.file
                                File(imageUrl), // Wrap imageUrl with File()
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.grey),
                              ),
                            );
                          } else {
                            return Text(
                              _getPlainTextFromDelta(note.content),
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                        },
                      )
                    : Text(
                        'Voice Note',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().format(
                    note.lastUpdatedAt ?? note.createdAt ?? DateTime.now()),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(Icons.home, 'Home', 0),
              _buildNavBarItem(
                  Icons.notifications_active_outlined, 'Reminders', 1),
              const SizedBox(width: 40), // Placeholder for FAB
              _buildNavBarItem(Icons.calendar_today, 'Calendar', 2),
              _buildNavBarItem(Icons.person, 'Profile', 3),
            ],
          ),
          Positioned(
            top: -30,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque, // Ensure the entire area is tappable
              onTap: () => fabTapped(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String? _getFirstImageUrlFromDelta(String deltaJson) {
    try {
      final List<dynamic> jsonList = jsonDecode(deltaJson);
      final Document document = Document.fromDelta(Delta.fromJson(jsonList));

      for (final operation in document.toDelta().toList()) {
        if (operation.data is Map &&
            (operation.data as Map).containsKey('image')) {
          return (operation.data as Map)['image'] as String;
        }
      }
    } catch (e) {
      print('Error parsing Delta JSON for image: $e');
    }
    return null;
  }

  String _getPlainTextFromDelta(String deltaJson) {
    try {
      final List<dynamic> jsonList = jsonDecode(deltaJson);
      final Document document = Document.fromDelta(Delta.fromJson(jsonList));
      return document.toPlainText().trim();
    } catch (e) {
      // Handle parsing errors, e.g., if the content is not valid Delta JSON
      print('Error parsing Delta JSON in HomeScreenViewModel: $e');
      return deltaJson; // Return original content if parsing fails
    }
  }
}

class NoteTemplate {
  final String title;
  final String content;
  final IconData icon;
  final Gradient gradient;

  NoteTemplate({
    required this.title,
    required this.content,
    required this.icon,
    required this.gradient,
  });
}
