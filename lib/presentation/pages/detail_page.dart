import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/schedule.dart';
import '../../core/utils/date_extension.dart';
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
  DateTime? selectedDate;

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
  }

  @override
  void dispose() {
    groomController.dispose();
    brideController.dispose();
    locationController.dispose();
    linkController.dispose();
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
                  icon: Icon(editMode ? Icons.save : Icons.edit),
                  onPressed: editMode ? saveChanges : toggleEditMode,
                ),
                editMode
                    ? Container()
                    : IconButton(
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
                    padding: const EdgeInsets.all(16),
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
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
