import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/schedule.dart';
import '../../core/utils/date_extension.dart';
import '../../core/utils/int_extension.dart';
import '../../core/utils/map_link.dart';
import '../bloc/detail/detail_cubit.dart';
import '../../core/navigation/app_navigation.dart';
import '../theme/palette.dart';
import '../widgets/account_section.dart';
import '../widgets/info_row.dart';
import '../widgets/dday_badge.dart';

class DetailPage extends StatefulWidget {
  final Schedule schedule;
  const DetailPage({super.key, required this.schedule});

  @override
  // ignore: library_private_types_in_public_api
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool editMode = false;

  late final DetailCubit cubit;
  final TextEditingController groomController = TextEditingController();
  final TextEditingController brideController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController payController = TextEditingController();
  DateTime? selectedDate;
  late Attendance selectedAttendance;

  /// The amounts people actually give, offered as one-tap presets that fill
  /// [payController].
  static const List<int> payPresets = [50000, 100000, 200000, 300000];

  /// True once '직접 입력' is picked; until then the amount field is read-only
  /// and only the presets can fill it.
  late bool customPay;

  @override
  void initState() {
    super.initState();
    cubit = DetailCubit();
    cubit.setSchedule(widget.schedule);
    groomController.text = widget.schedule.groom;
    brideController.text = widget.schedule.bride;
    locationController.text = widget.schedule.location;
    linkController.text = widget.schedule.link;
    selectedDate = widget.schedule.date;
    selectedAttendance = widget.schedule.attendance;

    final int pay = widget.schedule.pay;
    customPay = pay > 0 && !payPresets.contains(pay);
    payController.text = pay > 0 ? pay.toString() : '';
  }

  @override
  void dispose() {
    groomController.dispose();
    brideController.dispose();
    locationController.dispose();
    linkController.dispose();
    payController.dispose();
    cubit.close();
    super.dispose();
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  void saveChanges() {
    setState(() {
      final Schedule editedSchedule = cubit.state.schedule!.copyWith(
        groom: groomController.text,
        bride: brideController.text,
        date: selectedDate!,
        location: locationController.text,
        attendance: selectedAttendance,
        // The field is the single source of truth: presets write into it.
        pay: int.tryParse(payController.text.trim()) ?? 0,
      );
      cubit.editSchedule(editedSchedule);
      editMode = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일정이 변경되었습니다.')),
      );
    });
  }

  InputDecoration customInputDecoration({required String labelText}) {
    return InputDecoration(
      filled: true,
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _openLink() async {
    final Uri url = Uri.parse(cubit.state.schedule!.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    final String location = cubit.state.schedule!.location;
    if (location.isEmpty) return;

    final Uri url = mapSearchUri(location);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("삭제 확인"),
          ],
        ),
        content: const Text(
          "일정을 삭제하시겠습니까?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              cubit.deleteSchedule(cubit.state.schedule!.link);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정이 삭제되었습니다.')),
              );
              navigatorKey.currentState
                  ?.popUntil((route) => route.settings.name == '/calendar');
            },
            child: const Text("삭제", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Schedule schedule = cubit.state.schedule!;

    return BlocProvider<DetailCubit>.value(
      value: cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          navigatorKey.currentState
              ?.popUntil((route) => route.settings.name == '/calendar');
        },
        child: SafeArea(
          top: false,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  tooltip: editMode ? '저장' : '수정',
                  icon: Icon(editMode ? Icons.save : Icons.edit),
                  onPressed: editMode ? saveChanges : toggleEditMode,
                ),
                editMode
                    ? Container()
                    : IconButton(
                        tooltip: '삭제',
                        icon: const Icon(Icons.delete),
                        onPressed: _showDeleteDialog,
                      ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroHeader(schedule: schedule, showCouple: !editMode),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: editMode ? _buildEditForm() : _buildInfoCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final Schedule schedule = cubit.state.schedule!;

    return _Card(
      children: [
        InfoRow(
          icon: Icons.event,
          label: '날짜',
          value: schedule.date.krDate,
          hint: schedule.date.ddayDescription,
        ),
        const _RowDivider(),
        InfoRow(
          icon: Icons.place_outlined,
          label: '장소',
          value: schedule.location,
          hint: '탭하면 지도로 열려요',
          onTap: _openMap,
        ),
        const _RowDivider(),
        InfoRow(
          icon: Icons.link,
          label: '청첩장',
          value: '링크 열기',
          valueColor: Colors.blue,
          onTap: _openLink,
        ),
        const _RowDivider(),
        InfoRow(
          icon: Icons.how_to_reg_outlined,
          label: '참석',
          value: schedule.attendance.label,
        ),
        const _RowDivider(),
        InfoRow(
          icon: Icons.payments_outlined,
          label: '축의금',
          value: schedule.pay > 0 ? schedule.pay.krCurrency : '아직 기록하지 않았어요',
          valueColor: schedule.pay > 0 ? null : Palette.grey500,
        ),

        // Accounts row; renders nothing when none were parsed.
        if (schedule.groomAccounts.isNotEmpty ||
            schedule.brideAccounts.isNotEmpty) ...[
          const _RowDivider(),
          AccountSection(
            groomAccounts: schedule.groomAccounts,
            brideAccounts: schedule.brideAccounts,
          ),
        ],
      ],
    );
  }

  Widget _buildEditForm() {
    return _Card(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: groomController,
                decoration: customInputDecoration(labelText: '신랑'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: brideController,
                decoration: customInputDecoration(labelText: '신부'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          readOnly: true,
          onTap: () => _selectDateTime(context),
          controller: TextEditingController(text: selectedDate!.krDate),
          decoration: customInputDecoration(labelText: '날짜'),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: locationController,
          decoration: customInputDecoration(labelText: '장소'),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('참석 여부'),
        Wrap(
          spacing: 8,
          children: Attendance.values
              .map(
                (attendance) => _choiceChip(
                  label: attendance.label,
                  selected: selectedAttendance == attendance,
                  onSelected: () =>
                      setState(() => selectedAttendance = attendance),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('축의금'),
        TextField(
          key: const ValueKey('pay-field'),
          controller: payController,
          keyboardType: TextInputType.number,
          // Right-aligned so the amount sits next to the '원' suffix.
          textAlign: TextAlign.right,
          // Presets fill this field; typing into it needs '직접 입력' first.
          enabled: customPay,
          // The '축의금' label already sits above, so the field only needs a hint.
          decoration: InputDecoration(
            filled: true,
            hintText: '0',
            suffixText: '원',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Shortcuts under the field, deliberately small: they feed the field
        // above rather than being the primary control.
        Wrap(
          spacing: 6,
          children: [
            ...payPresets.map(
              (amount) => _choiceChip(
                label: '${amount ~/ 10000}만원',
                selected: !customPay &&
                    int.tryParse(payController.text.trim()) == amount,
                onSelected: () => setState(() {
                  customPay = false;
                  payController.text = amount.toString();
                }),
              ),
            ),
            _choiceChip(
              label: '직접 입력',
              selected: customPay,
              onSelected: () => setState(() => customPay = true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      // The default selected color comes from the theme's secondaryContainer,
      // which is purple and off-palette.
      selectedColor: Palette.beige,
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? Palette.burgundy : Palette.grey700,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onSelected(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Palette.grey600),
      ),
    );
  }
}

/// Full-width thumbnail with the D-day badge and the couple's names on top.
class _HeroHeader extends StatelessWidget {
  final Schedule schedule;
  final bool showCouple;

  const _HeroHeader({required this.schedule, required this.showCouple});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: schedule.thumbnail,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: Palette.beige),
          ),

          // Darken the bottom only, so the names stay readable over the photo.
          if (showCouple)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 16,
            right: 16,
            child: DDayBadge(date: schedule.date),
          ),

          if (showCouple)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Text(
                '🤵‍♂️ ${schedule.groom} & 👰‍♀️ ${schedule.bride}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Palette.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;

  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.beige, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Palette.grey200);
  }
}
