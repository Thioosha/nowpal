import 'package:flutter/material.dart';

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 28.0;
    final path = Path();

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
