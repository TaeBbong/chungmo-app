/// Step 8:
/// Pages(widget)
///
/// Presentation layer connected with controller
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../domain/entities/invitation_image.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/services/preferences_checker.dart';
import '../../core/services/share_intent_service.dart';
import '../../core/services/tutorial_manager.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/string_extension.dart';
import '../bloc/create/create_cubit.dart';
import '../theme/dimens.dart';
import '../theme/motions.dart';
import '../theme/palette.dart';
import '../widgets/analyze_animation.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/schedule_detail_column.dart';
import '../widgets/upcoming_preview.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> with WidgetsBindingObserver {
  late final CreateCubit cubit;
  final PreferencesChecker preferencesChecker = getIt<PreferencesChecker>();
  final TextEditingController _textEditingController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late TutorialManager tutorialManager;
  final GlobalKey linkInputKey = GlobalKey(debugLabel: 'link-input');
  final GlobalKey resultBodyKey = GlobalKey(debugLabel: 'result-body');
  final GlobalKey statsPageKey = GlobalKey(debugLabel: 'stats-page');
  final GlobalKey calendarPageKey = GlobalKey(debugLabel: 'calendar-page');
  bool _clipboardHasText = false;
  StreamSubscription<SharedInvitation>? _shareSub;

  @override
  void initState() {
    super.initState();
    cubit = CreateCubit();
    // Parse the analyze Lottie now, while the screen is idle, so entering
    // the loading state later swaps the animation in without a parse hitch.
    AnalyzeAnimation.preload();
    cubit.checkIfNotification();
    cubit.watchUpcomingSchedules();
    _initTutorial();
    _listenForShares();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  /// Starts parsing right away when an invitation is shared from another
  /// app, whether the share launched the app or arrived while it ran.
  void _listenForShares() {
    final ShareIntentService shareIntent = getIt<ShareIntentService>();
    _shareSub = shareIntent.shares.listen(_analyzeShared);
    shareIntent.consumeInitialShare().then((share) {
      // The future can complete after dispose() closed the cubit.
      if (!mounted || share == null) return;
      _analyzeShared(share);
    });
  }

  Future<void> _analyzeShared(SharedInvitation share) async {
    // A share can arrive while another page is on top; the parse result
    // renders on this home screen, so come back to it first.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    switch (share.type) {
      case SharedInvitationType.link:
        cubit.analyzeLink(share.value, source: 'share');
        break;
      case SharedInvitationType.text:
        cubit.analyzeText(share.value, source: 'share');
        break;
      case SharedInvitationType.image:
        try {
          // The OS copies the shared image into the app cache; read it from
          // there like a gallery pick.
          final Uint8List bytes = await File(share.value).readAsBytes();
          if (!mounted) return;
          cubit.analyzeImage(
            InvitationImage(
              bytes: bytes,
              mimeType: share.mimeType ?? _mimeTypeOf(share.value),
            ),
            source: 'share',
          );
        } on FileSystemException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공유된 이미지를 불러오지 못했어요. 다시 시도해주세요.')),
          );
        }
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _checkClipboard();
        break;
      default:
        break;
    }
  }

  Future<void> _initTutorial() async {
    final TourMode? mode = TutorialManager.resolveTourMode(
      sawVersionedTour: await preferencesChecker.hasKey(Constants.tourDoneKey),
      sawLegacyTour:
          await preferencesChecker.hasKey(Constants.legacyTourDoneKey),
    );
    if (mode == null || !mounted) return;
    _showTour(newFeaturesOnly: mode == TourMode.newFeaturesOnly);
  }

  void _showTour({required bool newFeaturesOnly, bool replay = false}) {
    final String tourMode =
        replay ? 'replay' : (newFeaturesOnly ? 'new_features' : 'full');
    tutorialManager = TutorialManager(
      context: context,
      linkInputKey: linkInputKey,
      resultBodyKey: resultBodyKey,
      statsPageKey: statsPageKey,
      calendarPageKey: calendarPageKey,
    );
    tutorialManager.initTargets(newFeaturesOnly: newFeaturesOnly);
    // Home replaces the onboarding route; the coach mark reads target
    // positions eagerly and aborts silently while the entrance transition
    // is still animating, so wait for the route to settle first.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Only the replay flow waits out a covering route's pop (settings
      // closing); the automatic flow must instead defer to a later launch
      // when something covers home, checked right below.
      await _waitForRouteSettled(waitForCoveringRoute: replay);
      if (!mounted) return;
      // A route pushed on top at launch (e.g. a notification deep link)
      // covers the targets; skip without marking done so the tour can
      // still show on a later launch.
      if (ModalRoute.of(context)?.isCurrent == false) return;
      // A launch-time share swaps home into its loading branch and
      // unmounts tour targets; showing now would abort yet still fire
      // the done callback, so bail out and let a later launch retry.
      if (!tutorialManager.targetsReady) return;
      // Persist only on real completion (finish or explicit skip), not
      // merely because the overlay was requested.
      tutorialManager.showTutorial(
        onDone: ({required bool skipped}) {
          preferencesChecker.setKey(Constants.tourDoneKey);
          getIt<AnalyticsService>().logEvent(
            AnalyticsEvents.tutorialFinished,
            parameters: {
              AnalyticsParams.method: skipped ? 'skip' : 'done',
              AnalyticsParams.tourMode: tourMode,
            },
          );
        },
      );
    });
  }

  /// Waits until this route stops moving: its entrance animation has
  /// completed and, with [waitForCoveringRoute], any covering route has
  /// fully popped. The pop matters for the tutorial replay — pushNamed's
  /// future resolves before the pop transition starts, and the Cupertino
  /// transition shifts this page while it runs, which would skew the coach
  /// mark positions read at focus time.
  Future<void> _waitForRouteSettled(
      {required bool waitForCoveringRoute}) async {
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    await _waitForStatus(route?.animation, AnimationStatus.completed);
    if (waitForCoveringRoute) {
      await _waitForStatus(
          route?.secondaryAnimation, AnimationStatus.dismissed);
    }
    // One more frame so the settled positions are laid out and readable.
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _waitForStatus(
      Animation<double>? animation, AnimationStatus target) async {
    if (animation == null || animation.status == target) return;
    final Completer<void> settled = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == target) {
        animation.removeStatusListener(onStatus);
        settled.complete();
      }
    }

    animation.addStatusListener(onStatus);
    await settled.future;
  }

  void _onSubmit() {
    String userInput = _textEditingController.text.trim();
    if (userInput.isEmpty) return;
    // One input for both: an http(s) URL is crawled as a link, anything
    // else is treated as pasted invitation text (SMS, 카톡 message).
    if (userInput.isHttpUrl) {
      cubit.analyzeLink(userInput);
    } else {
      cubit.analyzeText(userInput);
    }
    _textEditingController.clear();
  }

  /// Lets the user attach an invitation image, or add a schedule by hand.
  void _onAttachImage() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('직접 입력하기'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                navigatorKey.currentState?.pushNamed('/schedule/form');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      // Downscale before upload; invitations stay readable well below 1600px.
      final XFile? picked = await _imagePicker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      cubit.analyzeImage(
        InvitationImage(bytes: bytes, mimeType: _mimeTypeOf(picked.path)),
        source: source == ImageSource.camera ? 'camera' : 'gallery',
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오지 못했어요. 다시 시도해주세요.')),
      );
    }
  }

  /// Maps the picked file's extension onto a Gemini-supported image mime type.
  String _mimeTypeOf(String path) {
    switch (path.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  /// Peeks whether the clipboard holds any text without reading it.
  ///
  /// `Clipboard.hasStrings` (UIPasteboard.hasStrings) does not trigger the
  /// iOS 16+ paste-permission prompt, unlike `Clipboard.getData` — reading on
  /// launch/resume used to pop the system dialog before the user did
  /// anything. The content is read only in [_pasteFromClipboard], where the
  /// prompt appears in response to the user's own tap.
  Future<void> _checkClipboard() async {
    try {
      final bool hasText = await Clipboard.hasStrings();
      if (!mounted) return;
      setState(() => _clipboardHasText = hasText);
    } on PlatformException {
      // An unreadable clipboard counts as empty; the button stays hidden.
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted) return;
      setState(() {
        // One-shot: hide the suggestion until the next launch/resume,
        // whether or not the read produced text (e.g. permission denied).
        _clipboardHasText = false;
        final String text = data?.text?.trim() ?? '';
        if (text.isNotEmpty) _textEditingController.text = text;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _clipboardHasText = false);
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    cubit.close();
    _textEditingController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cross-fades between the analyze states (idle/loading/error/result)
  /// instead of hard-swapping subtrees. Every branch returns this wrapper at
  /// the same tree position, so the AnimatedSwitcher element persists across
  /// builds and only its keyed child changes — which is what triggers the
  /// transition.
  Widget _analyzeBranch(String branch, Widget child) {
    return AnimatedSwitcher(
      duration: Motions.standard,
      switchInCurve: Motions.easeOut,
      switchOutCurve: Motions.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: Motions.emergeScale, end: 1)
            .animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<String>(branch), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateCubit>.value(
      value: cubit,
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('청모'),
            leading: IconButton(
              key: calendarPageKey,
              tooltip: '일정 보기',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () {
                navigatorKey.currentState?.pushNamed('/calendar');
              },
            ),
            actions: [
              /// Only shows notification button in `kDebugMode`.
              kDebugMode
                  ? IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        cubit.notificationService.addTestNotifySchedule(id: 1);
                        cubit.notificationService.checkScheduledNotifications();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('알림'),
                            content: const Text('스케쥴이 등록되었습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(),
              IconButton(
                key: statsPageKey,
                tooltip: '축의금 통계',
                icon: const Icon(Icons.insights_outlined),
                onPressed: () {
                  navigatorKey.currentState?.pushNamed('/stats');
                },
              ),
              // Terms/privacy moved into the about page; one entry point.
              IconButton(
                tooltip: '앱 정보',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () async {
                  // The about page pops with true when the user asks to
                  // replay the tutorial; the targets live on this screen.
                  final Object? result =
                      await navigatorKey.currentState?.pushNamed('/about');
                  if (result == true && mounted) {
                    _showTour(newFeaturesOnly: false, replay: true);
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: BlocBuilder<CreateCubit, CreateState>(
                    builder: (context, state) {
                  if (state.isLoading) {
                    return _analyzeBranch(
                        'loading',
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 250,
                              height: 250,
                              child: AnalyzeAnimation(),
                            ),
                            SizedBox(height: 16),
                            Text('청첩장 분석 중...', style: TextStyle(fontSize: 16)),
                          ],
                        ));
                  }
                  if (state.isError) {
                    // A format/incomplete failure means the AI answered but
                    // found no usable schedule — retrying the same input
                    // won't help, so guide the user instead of blaming the
                    // server.
                    final bool notReadable =
                        state.errorReason == ParseFailureReason.format ||
                            state.errorReason == ParseFailureReason.incomplete;
                    return _analyzeBranch(
                        'error',
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 44,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(height: Dimens.md),
                            Text(
                              notReadable ? '청첩장 정보를 찾지 못했어요.' : '다시 시도해주세요.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: Dimens.xs),
                            Text(
                              notReadable
                                  ? '예식 날짜가 담긴 청첩장인지 확인하고 다시 시도해주세요.'
                                  : '잠시 서버에 문제가 생겼어요.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            // Partial extraction kept from the failed parse:
                            // let the user finish it instead of retrying.
                            if (state.draft != null)
                              Padding(
                                padding: const EdgeInsets.only(top: Dimens.lg),
                                child: FilledButton.icon(
                                  onPressed: () {
                                    final draft = state.draft;
                                    cubit.resetState();
                                    navigatorKey.currentState?.pushNamed(
                                        '/schedule/form',
                                        arguments: draft);
                                  },
                                  icon: const Icon(Icons.edit_calendar_outlined,
                                      size: 18),
                                  label: const Text('읽은 내용으로 직접 완성하기'),
                                ),
                              ),
                          ],
                        ));
                  }
                  return _analyzeBranch(
                      state.schedule != null ? 'result' : 'idle',
                      state.schedule != null
                          ? ScheduleDetailColumn(
                              schedule: state.schedule!,
                              extraChildren: [
                                const SizedBox(height: Dimens.md),
                                Text(
                                  '분석 결과를 일정에 추가할게요.',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Palette.burgundy),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.auto_awesome,
                                            size: 40,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer),
                                      ),
                                      const SizedBox(height: Dimens.lg),
                                      Text(
                                        key: resultBodyKey,
                                        '모바일 청첩장을 첨부해주세요.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: Dimens.xs),
                                      Text(
                                        '링크·문자·사진 무엇이든 AI가 분석해드려요.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      // No content preview: the clipboard is
                                      // only peeked (hasStrings), not read, so
                                      // launch stays free of the iOS paste
                                      // prompt. Tapping reads and pastes.
                                      // The chip enters through the shared
                                      // FadeSlideIn when a clipboard link is
                                      // detected; consuming it unmounts the
                                      // chip as the parse takes the screen.
                                      if (_clipboardHasText &&
                                          _textEditingController.text.isEmpty)
                                        FadeSlideIn(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                top: Dimens.lg),
                                            child: FilledButton.icon(
                                              onPressed: _pasteFromClipboard,
                                              icon: const Icon(
                                                  Icons.content_paste_rounded,
                                                  size: 18),
                                              label:
                                                  const Text('복사한 내용 붙여넣기'),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // The saved schedules, so the empty home screen
                                // still says something while it waits for a link.
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                  child: UpcomingPreview(
                                    schedules: state.upcomingSchedules,
                                  ),
                                ),
                              ],
                            ));
                }),
              ),
            ],
          ),
          bottomSheet:
              BlocBuilder<CreateCubit, CreateState>(builder: (context, state) {
            return state.schedule != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(Dimens.screenPadding,
                        Dimens.md, Dimens.screenPadding, Dimens.md),
                    child: ElevatedButton(
                      onPressed: () {
                        // Physical confirmation for the flow's terminal step.
                        HapticFeedback.mediumImpact();
                        cubit.resetState();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('일정을 캘린더에 저장했습니다.')),
                        );
                      },
                      child: const Text('확인'),
                    ),
                  )
                : Padding(
                    key: linkInputKey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.md, vertical: Dimens.sm + 2),
                    // The input surface comes from the theme's
                    // InputDecorationTheme, so it adapts to dark mode.
                    child: TextField(
                      controller: _textEditingController,
                      onSubmitted: (value) => _onSubmit(),
                      // Invitation SMS pastes span multiple lines.
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '링크 또는 청첩장 문자 붙여넣기...',
                        prefixIcon: IconButton(
                          tooltip: '청첩장 이미지 첨부',
                          icon: const Icon(Icons.add_photo_alternate_outlined,
                              size: 22),
                          onPressed: _onAttachImage,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_upward_rounded,
                              size: 22, color: Palette.burgundy),
                          onPressed: _onSubmit,
                        ),
                      ),
                    ),
                  );
          }),
        ),
      ),
    );
  }
}
