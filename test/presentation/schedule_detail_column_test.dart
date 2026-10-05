import 'package:chungmo/core/utils/date_extension.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/widgets/schedule_detail_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Schedule _schedule({
  String groom = '김민준',
  String bride = '이서연',
  String location = '라온컨벤션 3층 그랜드홀',
}) =>
    Schedule(
      link: 'https://invite.test/a',
      thumbnail: 'https://vendor.test/main.jpg',
      groom: groom,
      bride: bride,
      date: DateTime(2026, 10, 17, 13, 30),
      location: location,
      venue: '라온컨벤션',
      groomAccounts: const [],
      brideAccounts: const [],
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  // The thumbnail is a network image; in a test it never resolves, which is
  // fine — pump rather than pumpAndSettle so the frame is not waited on.
  await tester.pump();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  testWidgets('shows the couple, the date and the venue', (tester) async {
    final schedule = _schedule();

    await _pump(tester, ScheduleDetailColumn(schedule: schedule));

    expect(find.textContaining('김민준'), findsOneWidget);
    expect(find.textContaining('이서연'), findsOneWidget);
    expect(find.textContaining(schedule.date.krDate), findsOneWidget);
    expect(find.textContaining('라온컨벤션 3층 그랜드홀'), findsOneWidget);
  });

  testWidgets('keeps a long venue to two lines rather than overflowing',
      (tester) async {
    // Parsed locations run long — hall, floor and address in one string.
    await _pump(
      tester,
      ScheduleDetailColumn(
        schedule:
            _schedule(location: '서울특별시 강남구 테헤란로 123 라온컨벤션 웨딩홀 3층 그랜드볼룸 제1연회장'),
      ),
    );

    final text = tester.widget<Text>(find.textContaining('테헤란로'));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('appends what the caller adds below the schedule',
      (tester) async {
    // The result screen hangs its own line under this; the detail page does
    // not pass anything.
    await _pump(
      tester,
      ScheduleDetailColumn(
        schedule: _schedule(),
        extraChildren: const [Text('분석 결과를 일정에 추가할게요.')],
      ),
    );

    expect(find.text('분석 결과를 일정에 추가할게요.'), findsOneWidget);
  });

  testWidgets('renders without extras', (tester) async {
    await _pump(tester, ScheduleDetailColumn(schedule: _schedule()));

    expect(find.byType(ScheduleDetailColumn), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a phone-width viewport', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    await _pump(tester, ScheduleDetailColumn(schedule: _schedule()));

    expect(tester.takeException(), isNull);
  });
}
