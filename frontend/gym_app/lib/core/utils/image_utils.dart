// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Project imports:
import '../network/api_endpoints.dart';

class SafeImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final double? width;
  final double? height;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  String get _serverBaseUrl {
    final uri = Uri.parse(ApiEndpoints.baseUrl);
    return uri.replace(path: '').toString();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
      );
    } else if (imageUrl.startsWith('/uploads/')) {
      return Image.network(
        '$_serverBaseUrl$imageUrl',
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return Image.network(
        imageUrl,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } else if (!kIsWeb) {
      // Only use Image.file if not on web
      return Image.file(
        File(imageUrl),
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
      );
    } else {
      // Fallback for web when it's not a network or asset image
      return const Center(child: Icon(Icons.image_not_supported));
    }
  }
}
