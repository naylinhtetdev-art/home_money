import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../finance/add_transaction_screen.dart';
import '../finance/budget_screen.dart';
import '../finance/goals_screen.dart';
import '../more/profile_screen.dart';
import '../reports/report_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [
    DashboardScreen(),
    ReportScreen(),
    SizedBox(),
    GoalsScreen(),
    ProfileScreen(),
  ];
  void addMenu() => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_card),
            title: const Text('Add income'),
            onTap: () => _push(const AddTransactionScreen(income: true)),
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Add expense'),
            onTap: () => _push(const AddTransactionScreen(income: false)),
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Add budget'),
            onTap: () => _push(const BudgetScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Add saving goal'),
            onTap: () => _push(const GoalsScreen(addOnOpen: true)),
          ),
        ],
      ),
    ),
  );
  void _push(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: pages[index],
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) {
        if (v == 2) {
          addMenu();
        } else {
          setState(() => index = v);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Add',
        ),
        NavigationDestination(
          icon: Icon(Icons.savings_outlined),
          selectedIcon: Icon(Icons.savings),
          label: 'Goals',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
