import 'package:flutter/material.dart';
import 'package:note_taker/home_screen_view_model.dart';
import 'package:note_taker/reminders_screen.dart';
import 'package:note_taker/widgets/reminder_roller.dart';
import 'package:provider/provider.dart';

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeScreenViewModel(),
      child: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeScreenViewModel>(context, listen: false)
          .checkDueReminders(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeScreenViewModel>(context);

    final List<Widget> screens = [
      _buildNotesView(context, viewModel),
      RemindersScreen(highlightedReminderId: viewModel.rollerReminder?.id),
      const Center(
          child: Text('Calendar Screen',
              style: TextStyle(color: Colors.white))), // Placeholder
      const Center(
          child: Text('Profile Screen',
              style: TextStyle(color: Colors.white))), // Placeholder
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: viewModel.selectedIndex,
              children: screens,
            ),
            Align(
              alignment: viewModel.rollerDirection == RollerDirection.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(
                  viewModel.showRoller
                      ? 0
                      : (viewModel.rollerDirection == RollerDirection.right
                          ? 300
                          : -300),
                  0,
                  0,
                ),
                child: viewModel.rollerReminder != null
                    ? ReminderRoller(
                        reminder: viewModel.rollerReminder!,
                        direction: viewModel.rollerDirection,
                        isExpanded: viewModel.isRollerExpanded,
                        onTap: () {
                          viewModel.onTabTapped(1); // Go to reminders tab
                          viewModel.hideRoller();
                        },
                        onExpand: () {
                          viewModel.expandRoller();
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: viewModel.buildBottomNavBar(context),
    );
  }

  Widget _buildNotesView(
      BuildContext context, HomeScreenViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        viewModel.buildTopBar(),
        viewModel.buildSegmentTabs(),
        viewModel.buildTemplates(context),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Divider(color: Color(0xFF2a2a2a)),
        ),
        Expanded(child: viewModel.buildNotesGrid()),
      ],
    );
  }
}
