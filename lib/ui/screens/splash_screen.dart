import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ready ? widget.child : _SplashView(controller: _controller),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        intensity: 1.4,
        child: Center(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(controller.value.clamp(0.0, 1.0));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.86 + 0.14 * t,
                    child: Opacity(
                      opacity: t,
                      child: const BrandMark(size: 92),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: Curves.easeOut.transform((t * 2 - 0.6).clamp(0.0, 1.0)),
                    child: const Column(
                      children: [
                        Text(
                          'MuseFlow',
                          style: TextStyle(
                            fontFamily: 'InterDisplay',
                            fontSize: 34,
                            letterSpacing: -1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '沐 声 · EVERY SOUND, YOUR FLOW',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 3.2,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: 120,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          Container(color: Colors.white.withOpacity(0.08)),
                          FractionallySizedBox(
                            widthFactor: t,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.auroraHorizontal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
