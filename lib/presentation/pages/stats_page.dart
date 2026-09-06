import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/utils/int_extension.dart';
import '../../domain/entities/pay_statistics.dart';
import '../../domain/entities/relation.dart';
import '../bloc/stats/stats_cubit.dart';
import '../theme/motions.dart';
import '../theme/palette.dart';

/// Gift-money statistics dashboard: headline totals, yearly spending and
/// a per-relation breakdown, aggregated from the local records.
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final StatsCubit cubit;

  @override
  void initState() {
    super.initState();
    getIt<AnalyticsService>().logEvent(AnalyticsEvents.statsViewed);
    cubit = StatsCubit();
    cubit.watchStatistics();
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatsCubit>.value(
      value: cubit,
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('축의금 통계')),
          body: BlocBuilder<StatsCubit, StatsState>(
            builder: (context, state) {
              if (!state.loaded) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.statistics.isEmpty) {
                return const _EmptyState();
              }
              return _Dashboard(statistics: state.statistics);
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.savings_outlined, size: 48, color: Palette.grey400),
          const SizedBox(height: 12),
          const Text(
            '아직 기록한 축의금이 없어요',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '일정에서 축의금을 기록하면 통계가 쌓여요.',
            style: TextStyle(fontSize: 13, color: Palette.grey500),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final PayStatistics statistics;

  const _Dashboard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            _SummaryTile(
                label: '총 축의금',
                value: statistics.totalAmount,
                format: (int v) => v.krCurrency),
            const SizedBox(width: 8),
            _SummaryTile(
                label: '기록 수',
                value: statistics.recordCount,
                format: (int v) => '$v건'),
            const SizedBox(width: 8),
            _SummaryTile(
                label: '평균',
                value: statistics.averageAmount,
                format: (int v) => v.krCurrency),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionLabel('연도별 지출'),
        _ChartCard(
            child: _YearlyBarChart(yearlyTotals: statistics.yearlyTotals)),
        const SizedBox(height: 24),
        const _SectionLabel('관계별 지출'),
        _ChartCard(
          child: _RelationBreakdown(relationTotals: statistics.relationTotals),
        ),
      ],
    );
  }
}

/// One-shot entrance driver for the dashboard: 0 → 1 with the emphasized
/// curve, multiplied into count-ups, bar heights and fill fractions so the
/// numbers and charts draw in together instead of appearing fully formed.
class _Entrance extends StatelessWidget {
  final Widget Function(BuildContext context, double t) builder;

  const _Entrance({required this.builder});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Motions.emphasized,
      curve: Motions.emphasizedEase,
      builder: (BuildContext context, double t, _) => builder(context, t),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final String Function(int) format;

  const _SummaryTile(
      {required this.label, required this.value, required this.format});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isLight ? Palette.surfaceMuted : Palette.grey850,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Palette.grey500)),
            const SizedBox(height: 6),
            // Amounts can outgrow a third of the screen; scale down
            // instead of wrapping. The number counts up on entrance.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _Entrance(
                builder: (BuildContext context, double t) => Text(
                  format((value * t).round()),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;

  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Palette.surfaceMuted : Palette.grey850,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Yearly totals as a single-hue bar chart; identity lives in the axis
/// labels, amounts surface through the touch tooltip.
class _YearlyBarChart extends StatelessWidget {
  final Map<int, int> yearlyTotals;

  const _YearlyBarChart({required this.yearlyTotals});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color barColor = isLight ? Palette.burgundy : Palette.burgundy200;
    final Color gridColor = isLight ? Palette.grey250 : Palette.grey800;

    final List<int> years = yearlyTotals.keys.toList()..sort();
    final int maxTotal = yearlyTotals.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: _Entrance(
        builder: (BuildContext context, double t) => BarChart(
          // fl_chart lerps data changes itself (150ms, linear); zeroed so it
          // doesn't smear the _Entrance curve driving toY every frame.
          duration: Duration.zero,
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxTotal * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                  rod.toY.toInt().krCurrency,
                  const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${value.toInt()}년',
                      style: TextStyle(fontSize: 12, color: Palette.grey500),
                    ),
                  ),
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: gridColor, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (final int year in years)
                BarChartGroupData(
                  x: year,
                  barRods: [
                    BarChartRodData(
                      // Grows from the baseline on entrance.
                      toY: yearlyTotals[year]!.toDouble() * t,
                      color: barColor,
                      width: 18,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-relation totals as labeled horizontal bars — with this few
/// categories, direct labels beat a donut for comparison.
class _RelationBreakdown extends StatelessWidget {
  final Map<Relation, int> relationTotals;

  const _RelationBreakdown({required this.relationTotals});

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color barColor = isLight ? Palette.burgundy : Palette.burgundy200;
    final Color trackColor = isLight ? Palette.grey200 : Palette.grey800;

    final List<MapEntry<Relation, int>> entries = relationTotals.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final int maxTotal = entries.first.value;

    return Column(
      children: [
        for (final entry in entries) ...[
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  entry.key.label,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _Entrance(
                    builder: (BuildContext context, double t) =>
                        LinearProgressIndicator(
                      // Fills to its share on entrance.
                      value: entry.value / maxTotal * t,
                      minHeight: 8,
                      color: barColor,
                      backgroundColor: trackColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 88,
                child: Text(
                  entry.value.krCurrency,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (entry != entries.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
