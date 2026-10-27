import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../state/app_state.dart';
import '../../widgets/brand_logo.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
}

const List<_OnboardingSlide> _slides = <_OnboardingSlide>[
  _OnboardingSlide(
    title: 'Show It',
    subtitle: 'Showcase your skills',
    description:
        'Build a profile that highlights what you do best. Add photos of your '
        'work, list your services and let your craft speak for itself.',
    icon: Icons.photo_camera_back_rounded,
  ),
  _OnboardingSlide(
    title: 'Prove It',
    subtitle: 'Earn trusted badges',
    description:
        'Take competency quizzes and follow certification pathways like TEVETA '
        'to prove your skills and stand out from the crowd.',
    icon: Icons.verified_rounded,
  ),
  _OnboardingSlide(
    title: 'Grow It',
    subtitle: 'Win work and grow',
    description:
        'Get discovered by clients, win jobs, collect ratings and build a '
        'reputation that opens bigger opportunities.',
    icon: Icons.trending_up_rounded,
  ),
];

/// Screens 2-4 - onboarding: Show It, Prove It, Grow It.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    ref.read(appProvider.notifier).completeOnboarding();
    if (mounted) context.go('/role');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const BrandLogo(size: 34, showRing: false),
                  const SizedBox(width: 10),
                  const Text(
                    'SkillBridge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (int value) => setState(() => _index = value),
                itemBuilder: (context, index) =>
                    _OnboardingSlideView(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      _slides.length,
                      (int i) => _Dot(active: i == _index),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_isLast ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: AppColors.navyGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 88, color: AppColors.accent),
          ),
          const SizedBox(height: 48),
          Text(
            slide.subtitle.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accentDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.title,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 26 : 8,
      decoration: BoxDecoration(
        color: active ? AppColors.navy : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
