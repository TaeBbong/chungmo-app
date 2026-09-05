import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/relation.dart';
import '../../domain/entities/schedule.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/services/calendar_service.dart';
import '../../core/utils/date_extension.dart';
import '../../core/utils/int_extension.dart';
import '../../core/utils/map_link.dart';
import '../bloc/detail/detail_cubit.dart';
import '../../core/navigation/app_navigation.dart';
import '../theme/palette.dart';
import '../widgets/account_section.dart';
import '../widgets/info_row.dart';
import '../../core/utils/string_extension.dart';
import '../widgets/dday_badge.dart';
import '../widgets/fade_slide_in.dart';

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

  /// Expanded height of the hero header behind the sliver app bar.
  static const double _heroHeight = 280;

  final ScrollController _scrollController = ScrollController();

  /// True once the hero header has collapsed under the toolbar; drives the
  /// title fade-in and the toolbar color switch.
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    getIt<AnalyticsService>().logEvent(AnalyticsEvents.scheduleOpened);
    cubit = DetailCubit();
    cubit.setSchedule(widget.schedule);
    groomController.text = widget.schedule.groom;
    brideController.text = widget.schedule.bride;
    locationController.text = widget.schedule.location;
    linkController.text = widget.schedule.link;
    selectedDate = widget.schedule.date;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    groomController.dispose();
    brideController.dispose();
    locationController.dispose();
    linkController.dispose();
    _scrollController.dispose();
    cubit.close();
    super.dispose();
  }

  void _onScroll() {
    // The header counts as collapsed once only the toolbar strip remains.
    final double threshold = _heroHeight -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;
    final bool collapsed = _scrollController.offset >= threshold;
    if (collapsed != _collapsed) {
      setState(() => _collapsed = collapsed);
    }
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

  /// Opens the attendance/gift record page and reflects its result.
  Future<void> _openRecordPage() async {
    final Object? result = await navigatorKey.currentState
        ?.pushNamed('/schedule/record', arguments: cubit.state.schedule!);
    if (result is Schedule && mounted) {
      // The record page already persisted the change; only the local
      // state needs to catch up.
      setState(() => cubit.setSchedule(result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록했어요.')),
      );
    }
  }

  InputDecoration customInputDecoration({String? labelText}) {
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

  /// Leaves the detail page back to wherever it was opened from.
  ///
  /// The calendar is the usual entry point, but the home screen's preview and
  /// a notification tap push the detail page straight onto the home route.
  /// Popping until '/calendar' in those stacks would empty the navigator and
  /// leave a black screen, so fall back to the first route.
  void _leaveDetail() {
    navigatorKey.currentState?.popUntil(
      (route) => route.settings.name == '/calendar' || route.isFirst,
    );
  }

  Future<void> _openMap() async {
    final String location = cubit.state.schedule!.location;
    if (location.isEmpty) return;

    getIt<AnalyticsService>().logEvent(AnalyticsEvents.locationMapOpened);
    final Uri url = mapSearchUri(location);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addToCalendar() async {
    getIt<AnalyticsService>().logEvent(AnalyticsEvents.calendarExportTapped);
    final bool opened =
        await getIt<CalendarService>().addToCalendar(cubit.state.schedule!);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캘린더 앱을 열 수 없어요.')),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Palette.error),
            const SizedBox(width: 8),
            const Text("삭제 확인"),
          ],
        ),
        content: const Text("일정을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("취소"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.error,
              // The theme's full-width button doesn't fit dialog actions.
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onPressed: () {
              // Physical confirmation for a destructive action.
              HapticFeedback.mediumImpact();
              cubit.deleteSchedule(cubit.state.schedule!.link);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일정이 삭제되었습니다.')),
              );
              _leaveDetail();
            },
            child: const Text("삭제"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Schedule schedule = cubit.state.schedule!;
    // While the hero is expanded the toolbar sits on the photo, so its
    // icons and title render white; both return to theme colors once the
    // bar collapses onto a solid background.
    final Color? overlayColor = _collapsed ? null : Palette.white;

    return BlocProvider<DetailCubit>.value(
      value: cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _leaveDetail();
        },
        child: SafeArea(
          top: false,
          child: Scaffold(
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: _heroHeight,
                  foregroundColor: overlayColor,
                  // The couple already headlines the expanded photo, so the
                  // toolbar title only fades in as the header collapses —
                  // the standard content-led detail pattern.
                  title: editMode
                      ? const Text('일정 수정')
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _collapsed ? 1 : 0,
                          child: Text(
                            '${schedule.groom} & ${schedule.bride}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  actions: editMode
                      ? [
                          // A labeled action reads clearer than the old
                          // floppy icon, which was easy to miss.
                          TextButton(
                            onPressed: saveChanges,
                            child: Text(
                              '저장',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: overlayColor,
                              ),
                            ),
                          ),
                        ]
                      : [
                          IconButton(
                            tooltip: '수정',
                            icon: const Icon(Icons.edit),
                            onPressed: toggleEditMode,
                          ),
                          IconButton(
                            tooltip: '삭제',
                            icon: const Icon(Icons.delete),
                            onPressed: _showDeleteDialog,
                          ),
                        ],
                  flexibleSpace: FlexibleSpaceBar(
                    background:
                        _HeroHeader(schedule: schedule, showCouple: !editMode),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    // Enters slightly after the hero header lands, so the
                    // flight has the stage to itself first.
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 100),
                      child: editMode ? _buildEditForm() : _buildInfoCard(),
                    ),
                  ),
                ),
              ],
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
          icon: Icons.event_available_outlined,
          label: '캘린더',
          value: '내 캘린더에 추가',
          hint: '기기 캘린더 앱으로 열려요',
          onTap: _addToCalendar,
        ),
        const _RowDivider(),
        InfoRow(
          icon: Icons.place_outlined,
          label: '장소',
          value: schedule.location,
          hint: '탭하면 지도로 열려요',
          onTap: _openMap,
        ),
        // Image/text/manual schedules carry a synthetic (non-http) link
        // that cannot be opened, so the row only shows for real URLs.
        // Synthetic keys (image://, text://, manual://) are not links the
        // user can open.
        if (schedule.link.isHttpUrl) ...[
          const _RowDivider(),
          InfoRow(
            icon: Icons.link,
            label: '청첩장',
            value: '링크 열기',
            valueColor: Theme.of(context).brightness == Brightness.light
                ? Palette.burgundy
                : Palette.burgundy100,
            onTap: _openLink,
          ),
        ],
        const _RowDivider(),
        InfoRow(
          icon: Icons.how_to_reg_outlined,
          label: '참석',
          value: schedule.attendance.label,
          onTap: _openRecordPage,
        ),
        // Relation row; hidden until the user records one.
        if (schedule.relation != Relation.unset) ...[
          const _RowDivider(),
          InfoRow(
            icon: Icons.people_outline,
            label: '관계',
            value: schedule.relation.label,
            hint: schedule.relationNote.isEmpty ? null : schedule.relationNote,
            onTap: _openRecordPage,
          ),
        ],
        const _RowDivider(),
        InfoRow(
          icon: Icons.payments_outlined,
          label: '축의금',
          value: schedule.pay > 0 ? schedule.pay.krCurrency : '아직 기록하지 않았어요',
          valueColor: schedule.pay > 0 ? null : Palette.grey500,
          hint: '탭해서 기록하고 AI 추천도 받아보세요',
          onTap: _openRecordPage,
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
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: schedule.thumbnail,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(color: Palette.burgundy50),
        ),

        // The toolbar now floats over the photo, so darken the top a step
        // to keep its white icons readable over bright skies.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
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

        // Bottom corner, clear of the toolbar actions above.
        Positioned(
          bottom: 20,
          right: 16,
          child: DDayBadge(date: schedule.date),
        ),

        if (showCouple)
          Positioned(
            left: 20,
            // Leave room for the D-day badge in the corner.
            right: 100,
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
        color: Theme.of(context).brightness == Brightness.light
            ? Palette.surfaceMuted
            : Palette.grey850,
        borderRadius: BorderRadius.circular(16),
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
