import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../providers/app_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => context.read<DashboardProvider>().load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.hasUser ? 'Bravo ${app.userName} 🙌' : 'Tes progrès',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Continue comme ça !',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Stat cards
                      Row(children: [
                        StatCard(
                          title: 'TAUX DE RÉUSSITE',
                          value: '${dash.rate.toStringAsFixed(0)}%',
                          color: dash.rate >= 50 ? AppTheme.success : AppTheme.danger,
                          icon: Icons.emoji_events_rounded,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: 'TOTAL ÉVÉNEMENTS',
                          value: '${dash.total}',
                          color: AppTheme.primary,
                          icon: Icons.bolt_rounded,
                          subtitle: '${dash.successCount} réussites',
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        StatCard(
                          title: 'RÉUSSITES',
                          value: '${dash.successCount}',
                          color: AppTheme.success,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        const SizedBox(width: 12),
                        StatCard(
                          title: 'DIFFICULTÉS',
                          value: '${dash.failCount}',
                          color: AppTheme.danger,
                          icon: Icons.close_rounded,
                        ),
                      ]),
                      const SizedBox(height: 28),

                      // Weekly chart
                      _sectionTitle('7 DERNIERS JOURS'),
                      const SizedBox(height: 14),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                        child: dash.total == 0
                            ? _emptyChart()
                            : SizedBox(
                                height: 180,
                                child: BarChart(_buildBarData(dash)),
                              ),
                      ),
                      const SizedBox(height: 28),

                      // Fail reasons
                      if (dash.failCount > 0) ...[
                        _sectionTitle('CAUSES DES DIFFICULTÉS'),
                        const SizedBox(height: 14),
                        GlassCard(
                          child: dash.reasonCounts.isEmpty
                              ? const Text('Aucune donnée', style: TextStyle(color: AppTheme.textSecondary))
                              : Column(
                                  children: dash.reasonCounts.entries
                                      .toList()
                                      .sorted((a, b) => b.value.compareTo(a.value))
                                      .take(5)
                                      .map((e) => _reasonRow(e.key, e.value, dash.failCount))
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Motivation message
                      if (dash.total > 0) _motivationCard(dash),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
  );

  Widget _emptyChart() {
    return const SizedBox(
      height: 80,
      child: Center(
        child: Text(
          'Les données apparaîtront après tes premiers triggers',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  BarChartData _buildBarData(DashboardProvider dash) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: dash.weekStats.map((d) => d.total.toDouble()).fold(0.0, (a, b) => a > b ? a : b) + 1,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, _) {
              final i = val.toInt();
              if (i < 0 || i >= dash.weekStats.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dash.weekStats[i].label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(dash.weekStats.length, (i) {
        final d = dash.weekStats[i];
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: d.total.toDouble(),
              width: 20,
              borderRadius: BorderRadius.circular(6),
              rodStackItems: d.total == 0
                  ? [BarChartRodStackItem(0, 0, Colors.transparent)]
                  : [
                      BarChartRodStackItem(0, d.fail.toDouble(), AppTheme.danger.withOpacity(0.7)),
                      BarChartRodStackItem(d.fail.toDouble(), d.total.toDouble(), AppTheme.success.withOpacity(0.8)),
                    ],
            ),
          ],
        );
      }),
    );
  }

  Widget _reasonRow(String reason, int count, int total) {
    final pct = total == 0 ? 0.0 : count / total;
    final emoji = AppConstants.failReasonsEmoji[
      AppConstants.failReasons.indexOf(reason) != -1
          ? AppConstants.failReasons.indexOf(reason)
          : 0
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reason, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('$count', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surfaceHigh,
                    color: AppTheme.danger.withOpacity(0.7),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _motivationCard(DashboardProvider dash) {
    String msg;
    String emoji;
    Color color;

    if (dash.rate >= 80) {
      msg = 'Incroyable ! Tu es sur une excellente lancée.';
      emoji = '🔥';
      color = AppTheme.success;
    } else if (dash.rate >= 50) {
      msg = 'Tu progresses bien ! Chaque effort compte.';
      emoji = '💪';
      color = AppTheme.primary;
    } else {
      msg = 'C\'est dur, mais tu es là. Continue à essayer.';
      emoji = '❤️';
      color = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

extension SortedExtension<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    final copy = List<T>.from(this);
    copy.sort(compare);
    return copy;
  }
}