import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF05070D);
  static const background2 = Color(0xFF08111C);

  static const panel = Color(0xFF101A17);
  static const panel2 = Color(0xFF121C2D);
  static const card = Color(0xFF121C18);
  static const card2 = Color(0xFF0F1727);

  static const line = Color(0xFF263128);

  static const green = Color(0xFF74E26B);
  static const green2 = Color(0xFF42C95A);
  static const blue = Color(0xFF60A5FA);
  static const purple = Color(0xFF8B5CF6);
  static const pink = Color(0xFFFF5DA2);
  static const orange = Color(0xFFFFB86B);

  static const text = Color(0xFFF6FFF6);
  static const soft = Color(0xFFB6C5B7);
  static const muted = Color(0xFF6F7D75);

  static const mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3E24),
      Color(0xFF07101A),
    ],
  );

  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      green,
      green2,
    ],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF17211C),
      Color(0xFF091018),
    ],
  );
}