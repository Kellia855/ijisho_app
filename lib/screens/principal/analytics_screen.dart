import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flag.dart';
import '../../providers/stream_providers.dart';
import '../../theme/app_theme.dart';

/// Matches the Analytics screen (stats, Attendance Trend, Dropout Risk
/// pie, Issue Breakdown, At-Risk Categories, Geographic Distribution).
///
/// Dropout Risk and Issue Breakdown are computed from real flag data.
/// Attendance Trend and Geographic Distribution have no data source yet
/// (no attendance-taking feature exists) so they use clearly-labeled
/// sample data — swap these once that pipeline exists.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  // Sample data — see note above.
  static const _sampleAttendance = [98.2, 94.5, 91.0, 92.5, 93.8, 90.1, 96.0];
  static const _sampleDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(allFlagsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.principalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('Analytics',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  const Icon(Icons.translate, color: Colors.white, size: 20),
                ],
              ),
            ),
            Expanded(
              child: flagsAsync.when(
                data: (flags) {
                  final totalStudents = flags.map((f) => f.studentName).toSet().length;
                  final atRisk = flags
                      .where((f) => f.severity != FlagSeverity.fine)
                      .map((f) => f.studentName)
                      .toSet()
                      .length;

                  final urgent =
                      flags.where((f) => f.severity == FlagSeverity.urgent).length;
                  final warning =
                      flags.where((f) => f.severity == FlagSeverity.warning).length;
                  final fine = flags.where((f) => f.severity == FlagSeverity.fine).length;
                  final total = (urgent + warning + fine).clamp(1, 1 << 30);

                  final byCategory = <FlagCategory, int>{};
                  for (final f in flags) {
                    byCategory[f.category] = (byCategory[f.category] ?? 0) + 1;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(label: 'Total Students', value: '$totalStudents'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'At Risk',
                              value: '$atRisk',
                              valueColor: AppColors.urgentRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionCard(
                        title: 'Attendance Trend',
                        trailingNote: 'sample data',
                        footer: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatFooterItem(label: 'Peak', value: '98.2%'),
                            _StatFooterItem(label: 'Average', value: '94.5%'),
                            _StatFooterItem(label: 'Lowest', value: '89.1%'),
                          ],
                        ),
                        child: SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final i = value.toInt();
                                      if (i < 0 || i >= _sampleDays.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Text(_sampleDays[i],
                                          style: const TextStyle(
                                              fontSize: 10, color: AppColors.textMuted));
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    _sampleAttendance.length,
                                    (i) => FlSpot(i.toDouble(), _sampleAttendance[i]),
                                  ),
                                  isCurved: true,
                                  color: AppColors.principalPurple,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.principalPurpleLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Dropout Risk',
                        child: SizedBox(
                          height: 160,
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 36,
                                    sections: [
                                      PieChartSectionData(
                                        value: urgent.toDouble(),
                                        color: AppColors.urgentRed,
                                        title: '',
                                        radius: 22,
                                      ),
                                      PieChartSectionData(
                                        value: warning.toDouble(),
                                        color: AppColors.warningOrange,
                                        title: '',
                                        radius: 22,
                                      ),
                                      PieChartSectionData(
                                        value: fine.toDouble(),
                                        color: AppColors.fineGreen,
                                        title: '',
                                        radius: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _LegendRow(
                                      color: AppColors.urgentRed,
                                      label: 'Urgent',
                                      value:
                                          '${(urgent / total * 100).round()}%',
                                    ),
                                    const SizedBox(height: 8),
                                    _LegendRow(
                                      color: AppColors.warningOrange,
                                      label: 'Warning',
                                      value:
                                          '${(warning / total * 100).round()}%',
                                    ),
                                    const SizedBox(height: 8),
                                    _LegendRow(
                                      color: AppColors.fineGreen,
                                      label: 'Fine',
                                      value: '${(fine / total * 100).round()}%',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Issue Breakdown',
                        child: byCategory.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('No flags logged yet.',
                                    style: TextStyle(color: AppColors.textMuted)),
                              )
                            : SizedBox(
                                height: 160,
                                child: BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final categories = byCategory.keys.toList();
                                            final i = value.toInt();
                                            if (i < 0 || i >= categories.length) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                categories[i].label.split(' ').first,
                                                style: const TextStyle(
                                                    fontSize: 9, color: AppColors.textMuted),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barGroups: List.generate(byCategory.length, (i) {
                                      final category = byCategory.keys.elementAt(i);
                                      final count = byCategory[category]!;
                                      return BarChartGroupData(x: i, barRods: [
                                        BarChartRodData(
                                          toY: count.toDouble(),
                                          color: category.accent,
                                          width: 18,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ]);
                                    }),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'At-Risk Categories',
                        child: Column(
                          children: byCategory.entries
                              .map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: e.key.bg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(e.key.icon,
                                              size: 16, color: e.key.accent),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(e.key.label,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600, fontSize: 13)),
                                        ),
                                        Text('${e.value} Students',
                                            style: const TextStyle(
                                                fontSize: 12, color: AppColors.textMuted)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.chevron_right,
                                            size: 16, color: AppColors.textMuted),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Geographic Distribution',
                        trailingNote: 'sample data',
                        child: Container(
                          height: 100,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, color: AppColors.textMuted),
                              SizedBox(height: 6),
                              Text('Hotspot: Sector 4 \u00b7 15% Dropout Risk Increase',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Could not load analytics: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatBox({
    required this.label,
    required this.value,
    this.valueColor = AppColors.principalPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final String? trailingNote;

  const _SectionCard({
    required this.title,
    this.footer,
    this.trailingNote,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (trailingNote != null)
                Text(trailingNote!,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 12),
          child,
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _StatFooterItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatFooterItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
