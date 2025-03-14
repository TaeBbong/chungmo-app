// Mocks generated by Mockito 5.4.5 from annotations
// in chungmo/test/mocks/mocks.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:chungmo/core/services/notification_service.dart' as _i6;
import 'package:chungmo/data/models/schedule/schedule_model.dart' as _i2;
import 'package:chungmo/data/sources/local/schedule_local_source.dart' as _i3;
import 'package:chungmo/data/sources/remote/schedule_remote_source.dart' as _i5;
import 'package:chungmo/domain/entities/schedule.dart' as _i7;
import 'package:mockito/mockito.dart' as _i1;
import 'package:timezone/timezone.dart' as _i8;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeScheduleModel_0 extends _i1.SmartFake implements _i2.ScheduleModel {
  _FakeScheduleModel_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [ScheduleLocalSource].
///
/// See the documentation for Mockito's code generation for more information.
class MockScheduleLocalSource extends _i1.Mock
    implements _i3.ScheduleLocalSource {
  MockScheduleLocalSource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<void> saveSchedule(_i2.ScheduleModel? schedule) =>
      (super.noSuchMethod(
            Invocation.method(#saveSchedule, [schedule]),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<List<_i2.ScheduleModel>> getSchedules() =>
      (super.noSuchMethod(
            Invocation.method(#getSchedules, []),
            returnValue: _i4.Future<List<_i2.ScheduleModel>>.value(
              <_i2.ScheduleModel>[],
            ),
          )
          as _i4.Future<List<_i2.ScheduleModel>>);

  @override
  _i4.Future<List<_i2.ScheduleModel>> searchSchedule(String? query) =>
      (super.noSuchMethod(
            Invocation.method(#searchSchedule, [query]),
            returnValue: _i4.Future<List<_i2.ScheduleModel>>.value(
              <_i2.ScheduleModel>[],
            ),
          )
          as _i4.Future<List<_i2.ScheduleModel>>);

  @override
  _i4.Future<List<_i2.ScheduleModel>> getSchedulesByDate(DateTime? date) =>
      (super.noSuchMethod(
            Invocation.method(#getSchedulesByDate, [date]),
            returnValue: _i4.Future<List<_i2.ScheduleModel>>.value(
              <_i2.ScheduleModel>[],
            ),
          )
          as _i4.Future<List<_i2.ScheduleModel>>);

  @override
  _i4.Future<Map<DateTime, List<_i2.ScheduleModel>>> getSchedulesForMonth(
    DateTime? date,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getSchedulesForMonth, [date]),
            returnValue:
                _i4.Future<Map<DateTime, List<_i2.ScheduleModel>>>.value(
                  <DateTime, List<_i2.ScheduleModel>>{},
                ),
          )
          as _i4.Future<Map<DateTime, List<_i2.ScheduleModel>>>);

  @override
  _i4.Future<void> editSchedule(_i2.ScheduleModel? schedule) =>
      (super.noSuchMethod(
            Invocation.method(#editSchedule, [schedule]),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> deleteScheduleByLink(String? link) =>
      (super.noSuchMethod(
            Invocation.method(#deleteScheduleByLink, [link]),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);
}

/// A class which mocks [ScheduleRemoteSource].
///
/// See the documentation for Mockito's code generation for more information.
class MockScheduleRemoteSource extends _i1.Mock
    implements _i5.ScheduleRemoteSource {
  MockScheduleRemoteSource() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.ScheduleModel> fetchScheduleFromServer(String? url) =>
      (super.noSuchMethod(
            Invocation.method(#fetchScheduleFromServer, [url]),
            returnValue: _i4.Future<_i2.ScheduleModel>.value(
              _FakeScheduleModel_0(
                this,
                Invocation.method(#fetchScheduleFromServer, [url]),
              ),
            ),
          )
          as _i4.Future<_i2.ScheduleModel>);
}

/// A class which mocks [NotificationService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNotificationService extends _i1.Mock
    implements _i6.NotificationService {
  MockNotificationService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<void> getPermissions() =>
      (super.noSuchMethod(
            Invocation.method(#getPermissions, []),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> init() =>
      (super.noSuchMethod(
            Invocation.method(#init, []),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> checkPreviousDayForNotify({
    required _i7.Schedule? schedule,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#checkPreviousDayForNotify, [], {
              #schedule: schedule,
            }),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> addNotifySchedule({
    required int? id,
    required String? appName,
    required String? title,
    required _i8.TZDateTime? scheduleDate,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#addNotifySchedule, [], {
              #id: id,
              #appName: appName,
              #title: title,
              #scheduleDate: scheduleDate,
            }),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> cancelNotifySchedule({required String? link}) =>
      (super.noSuchMethod(
            Invocation.method(#cancelNotifySchedule, [], {#link: link}),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<void> checkScheduledNotifications() =>
      (super.noSuchMethod(
            Invocation.method(#checkScheduledNotifications, []),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);
}
