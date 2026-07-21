import 'dart:convert';
import 'package:flutter/material.dart';

Widget buildReportImage(
  String? imageString, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? fallbackWidget,
}) {
  if (imageString == null || imageString.trim().isEmpty) {
    return fallbackWidget ??
        const Center(
          child: Icon(Icons.image_not_supported, size: 36, color: Colors.grey),
        );
  }

  final cleanString = imageString.trim();

  // 1. If it's a web URL, use Image.network
  if (cleanString.startsWith('http://') || cleanString.startsWith('https://')) {
    return Image.network(
      cleanString,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          fallbackWidget ?? const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
    );
  }

  // 2. Otherwise try base64 decoding inside a try-catch block
  try {
    // Remove data URI prefix if present (e.g. data:image/png;base64,)
    final base64Data = cleanString.contains(',')
        ? cleanString.split(',').last
        : cleanString;

    return Image.memory(
      base64Decode(base64Data),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          fallbackWidget ?? const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
    );
  } catch (e) {
    debugPrint('Failed to decode image string: $e');
    return fallbackWidget ?? const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey));
  }
}
