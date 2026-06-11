import 'package:flutter/material.dart';

/// Shared color scale for the 1–5 impulse score.
Color impulseColor(num value) {
  if (value <= 1) return Colors.green;
  if (value <= 2) return Colors.lightGreen;
  if (value <= 3) return Colors.orange;
  if (value <= 4) return Colors.deepOrange;
  return Colors.red;
}
