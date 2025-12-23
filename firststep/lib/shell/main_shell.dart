import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/checklist/checklist_screen.dart';
import '../features/guide/guide_screen.dart';
import '../features/interview/interview_screen.dart';
import '../theme/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _controller = PageController();
  int _index = 0;

  void _onTap(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(), // 탭바로만 이동(원하면 제거)
        children: const [
          HomeScreen(),
          CheckListScreen(),
          GuideScreen(),
          InterviewScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.textGray,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_outlined), label: 'CheckList'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.mic_none), label: 'Interview'),
        ],
      ),
    );
  }
}