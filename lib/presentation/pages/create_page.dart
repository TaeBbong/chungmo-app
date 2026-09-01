/// Step 8:
/// Pages(widget)
///
/// Presentation layer connected with controller
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/di/di.dart';
import '../../domain/entities/invitation_image.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/services/preferences_checker.dart';
import '../../core/services/tutorial_manager.dart';
import '../bloc/create/create_cubit.dart';
import '../theme/dimens.dart';
import '../theme/palette.dart';
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
  final GlobalKey calendarPageKey = GlobalKey(debugLabel: 'calendar-page');
  String _clipboardContent = '';
  String _showClipboardContent = '';

  @override
  void initState() {
    super.initState();
    cubit = CreateCubit();
    cubit.checkIfNotification();
    cubit.watchUpcomingSchedules();
    _initTutorial();
    WidgetsBinding.instance.addObserver(this);
    _getClipboardContent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _getClipboardContent();
        break;
      default:
        break;
    }
  }

  Future<void> _initTutorial() async {
    final bool isFirst = !(await preferencesChecker.hasKey('is_first'));
    if (!mounted) return;
    if (isFirst) {
      tutorialManager = TutorialManager(
        context: context,
        linkInputKey: linkInputKey,
        resultBodyKey: resultBodyKey,
        calendarPageKey: calendarPageKey,
      );
      tutorialManager.initTargets();
      // Home is pushed from onboarding; wait for the route transition so
      // the coach mark can locate its target widgets, otherwise it fails
      // silently before they are laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        tutorialManager.showTutorial();
        await preferencesChecker.setKey('is_first');
      });
    }
  }

  void _onSubmit() {
    String userInput = _textEditingController.text.trim();
    if (userInput.isEmpty) return;
    // One input for both: an http(s) URL is crawled as a link, anything
    // else is treated as pasted invitation text (SMS, 카톡 message).
    if (_isHttpUrl(userInput)) {
      cubit.analyzeLink(userInput);
    } else {
      cubit.analyzeText(userInput);
    }
    _textEditingController.clear();
  }

  bool _isHttpUrl(String input) {
    final uri = Uri.tryParse(input);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !input.contains(RegExp(r'\s'));
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

  Future<void> _getClipboardContent() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        final uri = Uri.tryParse(clipboardData.text!);
        if (uri != null &&
            uri.hasScheme &&
            (uri.scheme == 'http' || uri.scheme == 'https')) {
          setState(() {
            _clipboardContent = clipboardData.text!;
            _showClipboardContent = _clipboardContent.length > 35
                ? '${_clipboardContent.substring(0, 35)}...'
                : _clipboardContent;
          });
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        throw ("Failed to get clipboard data: '$e'.");
      }
    }
  }

  @override
  void dispose() {
    cubit.close();
    _textEditingController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
              // Terms/privacy moved into the about page; one entry point.
              IconButton(
                tooltip: '앱 정보',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  navigatorKey.currentState?.pushNamed('/about');
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
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: DotLottieLoader.fromAsset(
                              'assets/images/analyze.lottie', frameBuilder:
                                  (BuildContext ctx, DotLottie? dotlottie) {
                            if (dotlottie != null) {
                              return Lottie.memory(
                                  dotlottie.animations.values.single);
                            } else {
                              return const CircularProgressIndicator();
                            }
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Text('청첩장 분석 중...',
                            style: TextStyle(fontSize: 16)),
                      ],
                    );
                  }
                  if (state.isError) {
                    // A format/incomplete failure means the AI answered but
                    // found no usable schedule — retrying the same input
                    // won't help, so guide the user instead of blaming the
                    // server.
                    final bool notReadable =
                        state.errorReason == ParseFailureReason.format ||
                            state.errorReason == ParseFailureReason.incomplete;
                    return Column(
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
                    );
                  }
                  return state.schedule != null
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  _clipboardContent.isNotEmpty &&
                                          _textEditingController.text.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                              top: Dimens.lg),
                                          child: FilledButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _textEditingController.text =
                                                    _clipboardContent;
                                                _clipboardContent = '';
                                              });
                                            },
                                            icon: const Icon(
                                                Icons.content_paste_rounded,
                                                size: 18),
                                            label: Text(
                                                '$_showClipboardContent 붙여넣기'),
                                          ),
                                        )
                                      : Container(),
                                ],
                              ),
                            ),

                            // The saved schedules, so the empty home screen
                            // still says something while it waits for a link.
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              child: UpcomingPreview(
                                schedules: state.upcomingSchedules,
                              ),
                            ),
                          ],
                        );
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
