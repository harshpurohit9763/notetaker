import 'package:flutter/material.dart';
import 'package:note_taker/home_screen_view_model.dart';
import 'package:note_taker/reminders_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeScreenViewModel(),
      child: Consumer<HomeScreenViewModel>(
        builder: (context, viewModel, _) {
          final List<Widget> screens = [
            _buildNotesView(context, viewModel),
            const RemindersScreen(),
            const Center(
                child: Text('Calendar Screen',
                    style: TextStyle(color: Colors.white))), // Placeholder
            const Center(
                child: Text('Profile Screen',
                    style: TextStyle(color: Colors.white))), // Placeholder
          ];

          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: viewModel.selectedIndex,
                children: screens,
              ),
            ),
            bottomNavigationBar: viewModel.buildBottomNavBar(context),
          );
        },
      ),
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
