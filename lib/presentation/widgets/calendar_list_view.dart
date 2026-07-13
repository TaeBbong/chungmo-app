import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/int_extension.dart';
import '../bloc/calendar/calendar_bloc.dart';
import '../bloc/calendar/calendar_state.dart';
import '../theme/palette.dart';
import 'schedule_list_tile.dart';

class CalendarListView extends StatelessWidget {
  const CalendarListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(builder: (context, state) {
      if (state.allSchedules.isEmpty) {
        return const Center(child: Text("일정이 없습니다."));
      }

      final now = DateTime.now();

      // The nearest wedding first; past ones from the most recent backwards.
      final upcomingSchedules = state.allSchedules
          .where((s) => !s.date.isBefore(now))
          .sorted((a, b) => a.date.compareTo(b.date));

      final pastSchedules = state.allSchedules
          .where((s) => s.date.isBefore(now))
          .sorted((a, b) => b.date.compareTo(a.date));

      // Only weddings that already happened count as money actually given;
      // an amount noted on an upcoming one is a plan, not a payment.
      final int paidThisYear = pastSchedules
          .where((s) => s.date.year == now.year)
          .fold(0, (sum, s) => sum + s.pay);

      return ListView(
        children: [
          if (paidThisYear > 0)
            _YearlyTotal(total: paidThisYear, year: now.year),
          if (upcomingSchedules.isNotEmpty) ...[
            const _SectionTitle('앞으로의 일정'),
            ...upcomingSchedules
                .map((schedule) => ScheduleListTile(schedule: schedule)),
          ],
          if (pastSchedules.isNotEmpty) ...[
            const _SectionTitle('지난 일정'),
            ...pastSchedules
                .map((schedule) => ScheduleListTile(schedule: schedule)),
          ],
        ],
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 축의금 recorded on this year's schedules.
class _YearlyTotal extends StatelessWidget {
  final int total;
  final int year;

  const _YearlyTotal({required this.total, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.beige100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 20, color: Palette.grey600),
          const SizedBox(width: 12),
          Text(
            '$year년에 낸 축의금',
            style: TextStyle(fontSize: 13, color: Palette.grey600),
          ),
          const Spacer(),
          Text(
            total.krCurrency,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Palette.burgundy,
            ),
          ),
        ],
      ),
    );
  }
}
