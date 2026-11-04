import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';

class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.url,
    required this.size,
    this.radius = AppRadii.md,
    this.seed = '',
    this.glow = false,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double size;
  final double radius;
  final String seed;
  final bool glow;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: _image(context),
      ),
    );
    if (!glow) return image;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: accentFor(seed).withOpacity(0.25),
            blurRadius: size * 0.24,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: image,
    );
  }

  Widget _image(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: fit, errorBuilder: _fallback);
    }
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, __) => _fallback(context, null, null),
        errorWidget: (context, _, __) => _fallback(context, null, null),
        fadeInDuration: const Duration(milliseconds: 220),
      );
    }
    return _fallback(context, null, null);
  }

  Widget _fallback(BuildContext context, Object? error, StackTrace? stack) {
    final gradient = artworkGradient(seed.isEmpty ? url : seed);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -size * 0.16,
            bottom: -size * 0.16,
            child: Container(
              width: size * 0.66,
              height: size * 0.66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.graphic_eq_rounded,
              size: size * 0.3,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class ArtworkStack extends StatelessWidget {
  const ArtworkStack({
    super.key,
    required this.covers,
    this.size = 120,
    this.radius = AppRadii.md,
  });

  final List<String> covers;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final visible = covers.take(3).toList();
    if (visible.isEmpty) {
      return Artwork(url: '', size: size, seed: 'stack', radius: radius);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned(
              left: i * size * 0.12,
              top: i * size * 0.06,
              child: Transform.rotate(
                angle: (i - 1) * 0.04,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Artwork(
                    url: visible[i],
                    size: size * 0.82,
                    radius: radius - 2,
                    seed: visible[i],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
