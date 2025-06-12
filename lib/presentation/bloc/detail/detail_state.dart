part of 'detail_cubit.dart';

class DetailState extends Equatable {
  final Schedule? schedule;

  const DetailState({this.schedule});

  DetailState copyWith({Schedule? schedule}) {
    return DetailState(schedule: schedule ?? this.schedule);
  }

  @override
  List<Object?> get props => [schedule];
}
