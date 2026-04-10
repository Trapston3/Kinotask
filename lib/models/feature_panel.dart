import 'package:flutter/material.dart';

class FeaturePanel {
  const FeaturePanel({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}
