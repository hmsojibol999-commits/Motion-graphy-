import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;

  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);

  static const BorderRadius allSm = BorderRadius.all(rSm);
  static const BorderRadius allMd = BorderRadius.all(rMd);
  static const BorderRadius allLg = BorderRadius.all(rLg);
}

class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
}
