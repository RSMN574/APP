import 'package:flutter/material.dart';

import '../../../const/app_design_tokens.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onCompleted,
  });

  final Future<void> Function() onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  static const _pages = [
    _OnboardingContent(
      eyebrow: '一站掌握',
      title: '公共運輸，\n都在台灣通',
      description: '公車、捷運、台鐵、高鐵與航空資訊，\n一個 App 快速找到。',
      icon: Icons.hub_rounded,
      accent: Color(0xFF1677FF),
      modes: ['公車', '捷運', '台鐵', '高鐵', '航空'],
    ),
    _OnboardingContent(
      eyebrow: '即時掌握',
      title: '出門前，\n先看最新動態',
      description: '掌握公車到站、YouBike 站點與道路資訊，\n讓每一段等待更有把握。',
      icon: Icons.radar_rounded,
      accent: Color(0xFF00A88F),
      modes: ['到站預估', 'YouBike', '路況提醒'],
    ),
    _OnboardingContent(
      eyebrow: '智慧規劃',
      title: '轉乘更順，\n抵達更快',
      description: '跨運具規劃路線與轉乘建議，\n搭配 GPS 導航，安心走完最後一哩。',
      icon: Icons.route_rounded,
      accent: Color(0xFFF28C28),
      modes: ['路線規劃', '轉乘建議', 'GPS 導航'],
    ),
    _OnboardingContent(
      eyebrow: '專屬你的',
      title: '常用行程，\n一點就出發',
      description: '收藏喜愛路線、設定個人偏好，\n重要交通通知不錯過。',
      icon: Icons.bookmark_added_rounded,
      accent: Color(0xFF7C5CFC),
      modes: ['收藏路線', '偏好設定', '通知提醒'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onCompleted();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _complete();
      return;
    }
    _animateToPage(_currentPage + 1);
  }

  void _previous() {
    if (_currentPage == 0) return;
    _animateToPage(_currentPage - 1);
  }

  void _animateToPage(int page) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _pageController.animateToPage(
      page,
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final content = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const _Wordmark(),
                  const Spacer(),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _complete,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 44),
                      ),
                      child: Text(
                        '略過',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingSlide(
                  content: _pages[index],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Semantics(
                        label: '第 ${index + 1} 頁，共 ${_pages.length} 頁',
                        selected: index == _currentPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? content.accent
                                : colors.outlineVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previous,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('上一步'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 2,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _next,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isLastPage
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                          label: Text(isLastPage ? '開始使用' : '下一步'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF1677FF), Color(0xFF00B8A9)],
            ),
          ),
          child: const Icon(
            Icons.alt_route_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '台灣通',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          Semantics(
            label: '${content.eyebrow}：${content.title.replaceAll('\n', '')}',
            image: true,
            child: _TransitIllustration(content: content),
          ),
          const SizedBox(height: 28),
          Text(
            content.eyebrow,
            style: theme.textTheme.labelLarge?.copyWith(
              color: content.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            content.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransitIllustration extends StatelessWidget {
  const _TransitIllustration({required this.content});

  final _OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: content.accent.withValues(alpha: 0.1),
        borderRadius: AppRadius.roundedXl,
        border: Border.all(color: content.accent.withValues(alpha: 0.15)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 28,
            right: 28,
            top: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var index = 0; index < 5; index++)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: content.accent.withValues(
                        alpha: index.isEven ? 0.9 : 0.35,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            top: 58,
            child: Divider(
              color: content.accent.withValues(alpha: 0.3),
              thickness: 2,
            ),
          ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: content.accent.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(content.icon, size: 64, color: content.accent),
          ),
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: content.modes
                  .map(
                    (mode) => Chip(
                      label: Text(mode),
                      backgroundColor: colors.surface,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: colors.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingContent {
  const _OnboardingContent({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.modes,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<String> modes;
}
