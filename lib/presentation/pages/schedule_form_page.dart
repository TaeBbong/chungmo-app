/// Step 8:
/// Pages(widget)
///
/// Presentation layer connected with controller
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/date_extension.dart';
import '../../domain/entities/schedule_draft.dart';
import '../bloc/schedule_form/schedule_form_cubit.dart';
import '../theme/dimens.dart';

/// Manual schedule entry, shared by two flows:
///
/// - '직접 입력': every field starts empty and the schedule is keyed by a
///   synthetic `manual://` link.
/// - parse fallback: an [ScheduleDraft] prefills whatever the AI could
///   extract, so the user only completes the missing fields.
class ScheduleFormPage extends StatefulWidget {
  final ScheduleDraft? draft;

  const ScheduleFormPage({super.key, this.draft});

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  late final ScheduleFormCubit cubit;
  late final TextEditingController _groomController;
  late final TextEditingController _brideController;
  late final TextEditingController _locationController;
  DateTime? _date;

  bool get _isFallback => widget.draft != null;

  @override
  void initState() {
    super.initState();
    cubit = ScheduleFormCubit();
    final ScheduleDraft? draft = widget.draft;
    _groomController = TextEditingController(text: draft?.groom ?? '');
    _brideController = TextEditingController(text: draft?.bride ?? '');
    _locationController = TextEditingController(text: draft?.location ?? '');
    _date = draft?.date;
  }

  @override
  void dispose() {
    _groomController.dispose();
    _brideController.dispose();
    _locationController.dispose();
    cubit.close();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date ?? now),
    );
    if (pickedTime == null) return;

    setState(() {
      _date = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute);
    });
  }

  void _save() {
    final DateTime? date = _date;
    if (date == null) return;
    cubit.save(
      draft: widget.draft,
      groom: _groomController.text,
      bride: _brideController.text,
      date: date,
      location: _locationController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return BlocProvider<ScheduleFormCubit>.value(
      value: cubit,
      child: BlocConsumer<ScheduleFormCubit, ScheduleFormState>(
        listener: (context, state) {
          switch (state.status) {
            case ScheduleFormStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정을 캘린더에 저장했습니다.')),
              );
              Navigator.of(context).pop();
              break;
            case ScheduleFormStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('저장하지 못했어요. 다시 시도해주세요.')),
              );
              break;
            default:
              break;
          }
        },
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isFallback ? '일정 완성하기' : '일정 직접 추가'),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Dimens.screenPadding,
                    Dimens.sm, Dimens.screenPadding, Dimens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isFallback) ...[
                      Text(
                        '청첩장에서 읽은 내용을 채워뒀어요.\n비어 있는 정보만 확인해주세요.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: Dimens.lg),
                    ],
                    const _FieldLabel('신랑 & 신부'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _groomController,
                            decoration:
                                const InputDecoration(hintText: '신랑 이름'),
                          ),
                        ),
                        const SizedBox(width: Dimens.sm),
                        Expanded(
                          child: TextField(
                            controller: _brideController,
                            decoration:
                                const InputDecoration(hintText: '신부 이름'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.lg),
                    const _FieldLabel('예식 일시 (필수)'),
                    _DateTimeField(date: _date, onTap: _pickDateTime),
                    const SizedBox(height: Dimens.lg),
                    const _FieldLabel('예식장'),
                    TextField(
                      controller: _locationController,
                      decoration:
                          const InputDecoration(hintText: '예식장 이름 또는 주소'),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(Dimens.screenPadding,
                    Dimens.sm, Dimens.screenPadding, Dimens.md),
                child: ElevatedButton(
                  onPressed: _date == null || state.isSaving ? null : _save,
                  child: Text(_date == null ? '예식 일시를 선택해주세요' : '저장'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.sm),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Input-styled row that opens the date/time pickers.
class _DateTimeField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateTimeField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusMd),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date == null ? '날짜와 시간 선택' : date!.krDate,
                style: date == null
                    ? theme.inputDecorationTheme.hintStyle
                    : theme.textTheme.bodyLarge,
              ),
            ),
            Icon(Icons.calendar_month_outlined,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
