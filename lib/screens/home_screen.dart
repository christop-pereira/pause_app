import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/pending_provider.dart';
import '../widgets/pending_debrief_banner.dart';
import 'dashboard_screen.dart';
import 'triggers_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _index = 0; // 0=Progrès, 1=Triggers, 2=Profil

  final _pages = const [
    DashboardScreen(),
    TriggersScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // À chaque ouverture du HomeScreen, on recharge les pendings et on
    // bascule sur l'onglet Progrès si un débrief est dû — comme ça il est
    // visible en premier.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = context.read<PendingProvider>();
      await pending.refresh();
      if (mounted && pending.hasDue && _index != 0) {
        setState(() => _index = 0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quand l'app revient au premier plan, on recharge les pendings
    // (un dueAt a peut-être été atteint pendant que l'app était en arrière-plan)
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PendingProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: const PendingDebriefBanner(),
          ),
          Expanded(
            child: IndexedStack(index: _index, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Progrès',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt_rounded),
              label: 'Triggers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}