import 'package:flutter/material.dart';
import '../widgets/onboarding_page_widget.dart';
import 'main_shell_screen.dart';

/// Data model for a single onboarding page
class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBgColor;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.iconBgColor,
  });
}

/// The 3-page onboarding flow with PageView and animated indicators.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding page content
  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.monitor_heart_outlined,
      title: 'Real Time Monitoring',
      description:
          'Monitor classroom temperature, noise, lighting, and air quality in real time using IoT sensors.',
      iconColor: Color(0xFF4A90D9),
      iconBgColor: Color(0xFFEAF4FB),
    ),
    _OnboardingData(
      icon: Icons.notifications_active_outlined,
      title: 'Instant Alerts',
      description:
          'Receive alerts when environmental conditions become uncomfortable or overstimulating.',
      iconColor: Color(0xFF5BB8A0),
      iconBgColor: Color(0xFFE8F8F5),
    ),
    _OnboardingData(
      icon: Icons.trending_up_rounded,
      title: 'Smart Insights',
      description:
          'Analyze trends and improve classroom conditions with data-driven insights.',
      iconColor: Color(0xFF7B6FD4),
      iconBgColor: Color(0xFFF0EEFF),
    ),
  ];

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShellScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Soft mint-to-white gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F8F5), Color(0xFFFFFFFF), Color(0xFFEAF4FB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with Skip button
              _buildTopBar(),

              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return OnboardingPageWidget(
                      icon: page.icon,
                      title: page.title,
                      description: page.description,
                      iconColor: page.iconColor,
                      iconBgColor: page.iconBgColor,
                    );
                  },
                ),
              ),

              // Bottom bar with indicators and action button
              _buildBottomBar(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Skip button — hidden on last page
          if (!_isLastPage)
            TextButton(
              onPressed: _navigateToMain,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7A8FA6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Animated page indicator dots
          _buildPageIndicators(),

          // Next / Get Started button
          _buildActionButton(),
        ],
      ),
    );
  }

  /// Animated dot indicators
  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4A90D9) : const Color(0xFFB0C8E0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Next or Get Started button
  Widget _buildActionButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isLastPage
          ? ElevatedButton(
              key: const ValueKey('get_started'),
              onPressed: _navigateToMain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF4A90D9).withValues(alpha: 0.4),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          : ElevatedButton(
              key: const ValueKey('next'),
              onPressed: _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF4A90D9).withValues(alpha: 0.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
    );
  }
}
