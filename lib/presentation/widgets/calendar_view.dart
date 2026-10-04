import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/calendar/calendar_bloc.dart';
import '../bloc/calendar/calendar_event.dart';
import '../bloc/calendar/calendar_state.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';
import 'adaptive_body.dart';
import 'schedule_list_tile.dart';

/// The month grid alone.
///
/// Its row height follows the space it is given: in a column the height is
/// unbounded and the rows stay at the phone size, while in a pane of a
/// two-pane layout they grow to fill it, which is what keeps a tablet from
/// showing a phone-sized month above half a screen of nothing.
class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({super.key});

  static const double _daysOfWeekHeight = 40;

  /// table_calendar's header: 8dp of padding above and below, around chevron
  /// buttons that are a 24dp icon in 12dp of padding — 16 + 48. Measured,
  /// not guessed: a header assumed 4dp shorter than this made the grid
  /// overflow its own box by exactly 4px, but only in the months that run to
  /// six week rows.
  static const double _headerHeight = 64;

  /// Everything above the week rows, which share whatever is left.
  static const double _chromeHeight = _headerHeight + _daysOfWeekHeight;
  static const double _minRowHeight = 52;
  static const double _maxRowHeight = 96;

  /// What the grid needs at the phone row height, and what it can use at
  /// the largest one. A caller that bounds the grid has to stay between
  /// them, or the rows clamp and the grid overflows its own box.
  static const double preferredHeight = _chromeHeight + _minRowHeight * 6;
  static const double tallestHeight = _chromeHeight + _maxRowHeight * 6;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(builder: (context, state) {
      final eventCounts = state.currentMonthSchedules;
      return LayoutBuilder(builder: (context, constraints) {
        final double rowHeight = constraints.maxHeight.isFinite
            ? ((constraints.maxHeight - _chromeHeight) / 6)
                .clamp(_minRowHeight, _maxRowHeight)
            : _minRowHeight;
        // No key on purpose: a per-emission ValueKey(eventCounts.hashCode)
        // used to force marker refreshes, but every bloc emission builds a
        // new map, so each month swipe/day tap REMOUNTED the calendar —
        // its PageView state died mid-gesture and the settle animation
        // snapped. Markers refresh through plain rebuilds anyway: the
        // markerBuilder closure captures the fresh map each build.
        return TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime(2000, 1, 1),
          lastDay: DateTime(2100, 12, 31),
          focusedDay: state.focusedDay,
          rowHeight: rowHeight,
          selectedDayPredicate: (day) => isSameDay(state.selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            context
                .read<CalendarBloc>()
                .add(DaySelected(selectedDay, focusedDay));
          },
          onPageChanged: (focusedDay) {
            context.read<CalendarBloc>().add(PageChanged(focusedDay));
          },
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          daysOfWeekHeight: _daysOfWeekHeight,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: Palette.burgundy50,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Palette.burgundy,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: const TextStyle(fontSize: 16),
            selectedTextStyle: TextStyle(fontSize: 16, color: Palette.white),
            todayTextStyle: TextStyle(fontSize: 16, color: Palette.burgundy),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, events) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(date.day.toString()),
                  const SizedBox(height: 4),
                ],
              );
            },
            markerBuilder: (context, date, events) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final eventCount = eventCounts[normalizedDate]?.length ?? 0;
              // Burgundy dots vanish if they overlap the burgundy
              // selection circle, so selected days get a contrasting dot.
              final Color markerColor = isSameDay(state.selectedDay, date)
                  ? Palette.white
                  : Palette.burgundy;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: eventCount > 0
                    ? List.generate(
                        eventCount > 5 ? 5 : eventCount,
                        (index) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : [const SizedBox(height: 6)],
              );
            },
          ),
        );
      });
    });
  }
}

/// The schedules on the selected day.
///
/// [withHeading] names the day, which a column under the month does not need
/// — the selection is visible right above it — but a separate pane does.
/// [scrollable] is false when a scroll view above already handles it, in
/// which case this lays out at its intrinsic height.
class CalendarDayView extends StatelessWidget {
  final bool withHeading;
  final bool scrollable;

  const CalendarDayView({
    super.key,
    this.withHeading = false,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(builder: (context, state) {
      final normalized = DateTime(state.selectedDay.year,
          state.selectedDay.month, state.selectedDay.day);
      final schedules = state.currentMonthSchedules[normalized] ?? const [];
      final Widget? heading = withHeading
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                  Dimens.md, Dimens.md, Dimens.md, Dimens.sm),
              child: Text(
                DateFormat('M월 d일 (E)', 'ko_KR').format(state.selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : null;
      // A pane that would otherwise sit blank says why it is blank; a column
      // under the month does not, because the month is the answer.
      final Widget? empty = withHeading
          ? Padding(
              padding: const EdgeInsets.all(Dimens.lg),
              child: Center(
                child: Text(
                  '이 날에는 일정이 없습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : null;

      if (!scrollable) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (heading != null) heading,
            if (schedules.isEmpty && empty != null) empty,
            for (final schedule in schedules)
              ScheduleListTile(schedule: schedule),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) heading,
          Expanded(
            child: schedules.isEmpty
                ? (empty ?? const SizedBox.shrink())
                : ListView.builder(
                    itemCount: schedules.length,
                    itemBuilder: (context, index) =>
                        ScheduleListTile(schedule: schedules[index]),
                  ),
          ),
        ],
      );
    });
  }
}

/// Month above, the selected day's schedules below — the phone layout.
///
/// A month grid needs about 410dp, which a landscape phone or a split-screen
/// window does not have once the list is allowed its share. Below
/// [_scrollThreshold] the whole screen scrolls instead of being squeezed.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  static const double _scrollThreshold = 520;

  /// Share of a tall window the month may take before the list gets the rest.
  static const double _monthShare = 0.55;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight >= _scrollThreshold) {
        // An unbounded month keeps its phone height whatever the window, so
        // on a tall one — an iPad in portrait, which is 834dp wide and so
        // still a single pane — it sat small above a long gap. Bounding it
        // lets its rows grow into the space instead; a phone is barely over
        // the floor, so it keeps the height it had.
        final double monthHeight = (constraints.maxHeight * _monthShare).clamp(
          CalendarMonthView.preferredHeight,
          CalendarMonthView.tallestHeight,
        );
        return Column(
          children: [
            SizedBox(height: monthHeight, child: const CalendarMonthView()),
            const SizedBox(height: 10),
            const Expanded(child: CalendarDayView()),
          ],
        );
      }
      return ListView(
        children: const [
          CalendarMonthView(),
          SizedBox(height: 10),
          CalendarDayView(scrollable: false),
        ],
      );
    });
  }
}

/// Month beside the selected day's schedules — the layout for a window with
/// room for two panes.
///
/// Stacked, the month leaves most of a tablet empty; side by side, the space
/// under it becomes the day it is pointing at.
class CalendarSplitView extends StatelessWidget {
  const CalendarSplitView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AdaptiveBody(
            alignment: Alignment.topRight,
            child: CalendarMonthView(),
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          child: AdaptiveBody(
            alignment: Alignment.topLeft,
            child: CalendarDayView(withHeading: true),
          ),
        ),
      ],
    );
  }
}
