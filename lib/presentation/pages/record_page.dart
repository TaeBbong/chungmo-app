import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/date_extension.dart';
import '../../core/utils/int_extension.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/pay_recommendation.dart';
import '../../domain/entities/relation.dart';
import '../../domain/entities/schedule.dart';
import '../bloc/record/record_cubit.dart';
import '../theme/palette.dart';
import '../widgets/selectable_chip.dart';

/// Records the user's side of a schedule: attendance, relationship and
/// gift amount, with the AI recommendation as the centerpiece.
///
/// Split out of the detail page's edit form so each screen carries one
/// task; pops with the edited [Schedule] once saved. The recommendation
/// and save flows live in [RecordCubit]; this page only renders them.
class RecordPage extends StatefulWidget {
  final Schedule schedule;

  const RecordPage({super.key, required this.schedule});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late final RecordCubit cubit;
  final TextEditingController payController = TextEditingController();
  final TextEditingController relationNoteController = TextEditingController();
  late Attendance selectedAttendance;
  late Relation selectedRelation;

  /// The record handed to the cubit on save; popped back to the detail
  /// page once the save succeeds.
  Schedule? _pendingSave;

  /// The amounts people actually give, offered as one-tap presets that fill
  /// [payController].
  static const List<int> payPresets = [50000, 100000, 200000, 300000];

  /// True once '직접 입력' is picked; until then the amount field is read-only
  /// and only the presets can fill it.
  late bool customPay;

  /// Rotating examples for the relation note, doubling as a nudge about the
  /// kind of nuance worth writing down.
  static const List<String> relationNoteHints = [
    '예) 한참 연락 안하던 중학교 동창',
    '예) 인사만 해본 옆팀 동료',
    '예) 매주 보는 절친',
    '예) 1년에 한 번 보는 대학 동기',
    '예) 옆자리 상사',
    '예) 대학교 때 만났던 전애인',
  ];

  @override
  void initState() {
    super.initState();
    cubit = RecordCubit();
    selectedAttendance = widget.schedule.attendance;
    selectedRelation = widget.schedule.relation;
    relationNoteController.text = widget.schedule.relationNote;

    final int pay = widget.schedule.pay;
    customPay = pay > 0 && !payPresets.contains(pay);
    payController.text = pay > 0 ? pay.toString() : '';
  }

  @override
  void dispose() {
    payController.dispose();
    relationNoteController.dispose();
    cubit.close();
    super.dispose();
  }

  /// The relation-note hint, stable per schedule so it doesn't flicker on
  /// rebuilds but still varies across schedules. Relies on String.hashCode
  /// being stable within a run (true on the Dart VM, though not a language
  /// guarantee) — an off-by-one hint would be harmless anyway.
  String get _relationNoteHint =>
      relationNoteHints[widget.schedule.link.hashCode.abs() %
          relationNoteHints.length];

  /// The schedule with the form's current values applied.
  Schedule get _editedSchedule => widget.schedule.copyWith(
        attendance: selectedAttendance,
        relation: selectedRelation,
        relationNote: relationNoteController.text.trim(),
        // The field is the single source of truth: presets write into it.
        pay: int.tryParse(payController.text.trim()) ?? 0,
      );

  void _save() {
    final Schedule edited = _editedSchedule;
    _pendingSave = edited;
    cubit.save(edited);
  }

  void _applyRecommendation() {
    final PayRecommendation? applied =
        cubit.applyRecommendation(selectedRelation);
    if (applied == null) return;
    setState(() {
      // The amount usually isn't a preset, so unlock the field.
      customPay = !payPresets.contains(applied.amount);
      payController.text = applied.amount.toString();
    });
  }

  void _onRecordStateChanged(BuildContext context, RecordState state) {
    _autofillRecommendationIfEmpty(state);
    switch (state.saveStatus) {
      case RecordSaveStatus.success:
        // Physical confirmation as the page closes on a saved record.
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(_pendingSave);
      case RecordSaveStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했어요. 다시 시도해주세요.')),
        );
      case RecordSaveStatus.idle || RecordSaveStatus.saving:
        break;
    }
  }

  /// The recommendation the autofill last reacted to, so it fires only on
  /// arrival — not on every later emission. Without the edge check, the
  /// save-status emissions would re-run the fill and resurrect an amount
  /// the user deliberately cleared after the autofill.
  PayRecommendation? _autofilledRecommendation;

  /// Fills an empty amount field with a freshly arrived recommendation.
  ///
  /// Without this, a user who requests a suggestion on a blank form, sees
  /// the amount and taps 저장 records 0원 — the card looks like part of the
  /// form, so "shown but not applied" reads as a lost save. An amount the
  /// user already entered is never overwritten; the explicit '이 금액 적용'
  /// button stays the way to replace one.
  void _autofillRecommendationIfEmpty(RecordState state) {
    final PayRecommendation? recommendation = state.recommendation;
    if (recommendation == null) {
      // Invalidation clears the marker too: fallback recommendations are
      // canonicalized consts, so a re-request after invalidation can hand
      // back the identical instance and must still count as an arrival.
      _autofilledRecommendation = null;
      return;
    }
    if (state.recommending) return;
    if (identical(recommendation, _autofilledRecommendation)) return;
    _autofilledRecommendation = recommendation;
    if (payController.text.trim().isNotEmpty) return;
    setState(() {
      customPay = !payPresets.contains(recommendation.amount);
      payController.text = recommendation.amount.toString();
    });
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Schedule schedule = widget.schedule;
    // Manually added schedules may have no names; drop the empty side (or
    // the whole line) instead of rendering a lone heart.
    final String couple = [schedule.groom, schedule.bride]
        .where((name) => name.isNotEmpty)
        .join(' ♥ ');

    return BlocProvider<RecordCubit>.value(
      value: cubit,
      child: BlocConsumer<RecordCubit, RecordState>(
        listener: _onRecordStateChanged,
        builder: (context, state) => SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(title: const Text('참석·축의금 기록')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Whose wedding this record belongs to.
                  if (couple.isNotEmpty) ...[
                    Text(
                      couple,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    schedule.date.krDate,
                    style: TextStyle(fontSize: 13, color: Palette.grey500),
                  ),
                  const SizedBox(height: 24),

                  const _SectionLabel('참석 여부'),
                  Wrap(
                    spacing: 8,
                    children: Attendance.values
                        .map(
                          (attendance) => SelectableChip(
                            label: attendance.label,
                            selected: selectedAttendance == attendance,
                            onSelected: () => setState(() {
                              selectedAttendance = attendance;
                              cubit.invalidateRecommendation();
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  const _SectionLabel('신랑·신부와의 관계'),
                  Wrap(
                    spacing: 8,
                    children: Relation.values
                        .where((relation) => relation != Relation.unset)
                        .map(
                          (relation) => SelectableChip(
                            label: relation.label,
                            selected: selectedRelation == relation,
                            onSelected: () => setState(() {
                              selectedRelation = relation;
                              cubit.invalidateRecommendation();
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('relation-note-field'),
                    controller: relationNoteController,
                    onChanged: (_) => cubit.invalidateRecommendation(),
                    decoration: _inputDecoration().copyWith(
                      hintText: _relationNoteHint,
                      helperText: '어떤 사이인지 적어주시면 AI 추천이 더 정확해져요 (선택)',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  const _SectionLabel('축의금'),
                  TextField(
                    key: const ValueKey('pay-field'),
                    controller: payController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    // Right-aligned so the amount sits next to the '원'
                    // suffix.
                    textAlign: TextAlign.right,
                    // Presets fill this field; typing into it needs
                    // '직접 입력' first.
                    enabled: customPay,
                    decoration: _inputDecoration().copyWith(
                      hintText: '0',
                      suffixText: '원',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Shortcuts under the field, deliberately small: they feed
                  // the field above rather than being the primary control.
                  Wrap(
                    spacing: 6,
                    children: [
                      ...payPresets.map(
                        (amount) => SelectableChip(
                          label: '${amount ~/ 10000}만원',
                          selected: !customPay &&
                              int.tryParse(payController.text.trim()) ==
                                  amount,
                          onSelected: () => setState(() {
                            customPay = false;
                            payController.text = amount.toString();
                          }),
                        ),
                      ),
                      SelectableChip(
                        label: '직접 입력',
                        selected: customPay,
                        onSelected: () => setState(() => customPay = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendationSection(state),
                ],
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                key: const ValueKey('record-save'),
                // Disabled while saving, so a double tap can't pop twice.
                onPressed: state.isSaving ? null : _save,
                child: const Text('저장'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The AI-recommendation area: a request button until a suggestion
  /// exists, then a card with the amount, range and rationale.
  Widget _buildRecommendationSection(RecordState state) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final Color accent = isLight ? Palette.burgundy : Palette.burgundy100;

    if (state.recommendation == null) {
      return OutlinedButton.icon(
        key: const ValueKey('recommend-button'),
        onPressed:
            state.recommending ? null : () => cubit.recommend(_editedSchedule),
        icon: state.recommending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 18),
        label:
            Text(state.recommending ? '얼마가 좋을지 고민하는 중...' : 'AI에게 축의금 추천받기'),
      );
    }

    final PayRecommendation shown = state.recommendation!;
    return Container(
      key: const ValueKey('recommendation-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight ? Palette.burgundy50 : Palette.grey800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                state.recommendationFromFallback ? '기본 가이드' : 'AI 추천',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
              const Spacer(),
              Text(
                '${shown.minAmount.krCurrency}~${shown.maxAmount.krCurrency}',
                style: TextStyle(fontSize: 12, color: Palette.grey500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            shown.amount.krCurrency,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            shown.reason,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isLight ? Palette.grey700 : Palette.grey400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: state.recommending
                    ? null
                    : () => cubit.recommend(_editedSchedule),
                child: const Text('다시 추천'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                key: const ValueKey('apply-recommendation'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _applyRecommendation,
                child: const Text('이 금액 적용'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A section heading strong enough to anchor each group of controls.
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
