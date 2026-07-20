import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class _OnboardingSlide {
  const _OnboardingSlide({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;
}

List<_OnboardingSlide> _slides(AppStrings s) => [
      _OnboardingSlide(icon: Icons.satellite_alt_rounded, title: s.onboardSlide1Title, description: s.onboardSlide1Desc),
      _OnboardingSlide(icon: Icons.eco_rounded, title: s.onboardSlide2Title, description: s.onboardSlide2Desc),
      _OnboardingSlide(
          icon: Icons.trending_up_rounded, title: s.onboardSlide3Title, description: s.onboardSlide3Desc),
    ];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final slides = _slides(s);
    final isLast = _page == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(s.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(slide: slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _page ? 24 : 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: PrimaryButton(
                label: isLast ? s.getStarted : s.next,
                onPressed: () {
                  if (isLast) {
                    context.go('/login');
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(slide.title, style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
