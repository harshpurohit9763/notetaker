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
      RemindersScreen(highlightedReminderId: viewModel.tappedReminderId),
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
            Consumer<HomeScreenViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.activeRollerReminders.isEmpty) {
                  return const SizedBox.shrink();
                }

                final screenWidth = MediaQuery.of(context).size.width;
                final expandedWidth = screenWidth * 0.40; // 40% of screen width
                final minimizedWidth = screenWidth * 0.08; // 8% of screen width

                return Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: expandedWidth,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Optional: prevents scroll if few items
                      itemCount: viewModel.activeRollerReminders.length,
                      itemBuilder: (context, index) {
                        final reminder = viewModel.activeRollerReminders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ReminderRoller(
                              reminder: reminder,
                              direction: RollerDirection.right,
                              expandedWidth: expandedWidth,
                              minimizedWidth: minimizedWidth,
                              onTap: () {
                                viewModel.setTappedReminderId(reminder.id);
                                viewModel.onTabTapped(1);
                                viewModel.disableReminderAndRemoveFromRoller(
                                    context, reminder);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: viewModel.buildBottomNavBar(context),
    );
  }

  Widget _buildNotesView(BuildContext context, HomeScreenViewModel viewModel) {
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
