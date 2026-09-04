import 'package:flutter/material.dart';

import '../../core/di/di.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/services/preferences_checker.dart';
import '../../core/utils/constants.dart';
import '../theme/dimens.dart';

/// First-run intro carousel shown before the home screen.
///
/// Finishing (or skipping) marks [Constants.onboardingDoneKey] and replaces
/// the route with home, where the coach mark tour takes over. In [review]
/// mode (opened from settings) finishing simply pops back instead.
class OnboardingPage extends StatefulWidget {
  final bool review;

  const OnboardingPage({super.key, this.review = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      icon: Icons.auto_awesome,
      title: '청첩장, 붙여넣기만 하세요',
      body: '링크·문자·사진 어떤 청첩장이든\nAI가 읽고 일정을 자동으로 등록해요.',
    ),
    _Slide(
      icon: Icons.savings_outlined,
      title: '축의금, 얼마가 적당할까요?',
      body: '상대와의 관계를 알려주시면\n내 기록과 통계를 근거로 AI가 추천해요.',
    ),
    _Slide(
      icon: Icons.insights_outlined,
      title: '일정도 지출도 한눈에',
      body: '다가오는 예식은 D-day로,\n낸 축의금은 연도별·관계별 통계로 확인해요.',
    ),
    _Slide(
      icon: Icons.notifications_active_outlined,
      title: '예식 전날 미리 알려드려요',
      body: '잊기 전에 알림으로 챙겨드릴게요.\n이제 시작해볼까요?',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish() async {
    if (widget.review) {
      navigatorKey.currentState?.pop();
      return;
    }
    await getIt<PreferencesChecker>().setKey(Constants.onboardingDoneKey);
    navigatorKey.currentState?.pushReplacementNamed('/');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.sm, vertical: Dimens.xs),
                child: _isLast
                    ? const SizedBox(height: Dimens.xxl)
                    : TextButton(
                        onPressed: _finish,
                        child: const Text('건너뛰기'),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _SlideView(_slides[index]),
              ),
            ),
            _Dots(count: _slides.length, index: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Dimens.screenPadding, Dimens.lg, Dimens.screenPadding, Dimens.md),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                    _isLast ? (widget.review ? '닫기' : '시작하기') : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({required this.icon, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView(this.slide);

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon,
                size: 52, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: Dimens.xl),
          Text(slide.title,
              style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: Dimens.md),
          Text(slide.body,
              style: textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: Dimens.xxl),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;

  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
