import 'dart:ui';

import 'package:flutter/material.dart';

class HandsPainter extends CustomPainter {
  final List<Offset> points;
  final Map<String, bool> fingerStates;
  final double ratio;
  

  HandsPainter({
    required this.points,
    required this.fingerStates,
    required this.ratio,
    
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isNotEmpty) {
      // Define modern color scheme
      const Color primaryColor = Color(0xFF3F51B5); // Indigo
      const Color accentColor = Color(0xFF2196F3); // Blue
      const Color jointColor = Color(0xFFFF5722); // Deep Orange

      // Paint for drawing landmark points with improved visual style
      final pointPaint = Paint()
        ..color = jointColor
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      // Paint for the palm point - make it visually distinctive
      final palmPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;

      // Paint for drawing connecting lines with improved style
      final linePaint = Paint()
        ..color = primaryColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      // Add finger-specific colors for better visualization
      final fingerColors = {
        'Thumb': Colors.purple,
        'Index': Colors.blue,
        'Middle': Colors.teal,
        'Ring': Colors.amber,
        'Pinky': Colors.red,
      };

      // Map finger indices for clearer code
      final fingerIndices = {
        'Thumb': [0, 1, 2, 3, 4],
        'Index': [0, 5, 6, 7, 8],
        'Middle': [0, 9, 10, 11, 12],
        'Ring': [0, 13, 14, 15, 16],
        'Pinky': [0, 17, 18, 19, 20],
      };

      // Draw the palm point separately
      if (points.length > 0) {
        canvas.drawPoints(
          PointMode.points,
          [points[0] * ratio],
          palmPaint,
        );
      }

      // Draw landmark points (excluding palm point)
      if (points.length > 1) {
        canvas.drawPoints(
          PointMode.points,
          points.sublist(1).map((point) => point * ratio).toList(),
          pointPaint,
        );
      }

      // Draw lines connecting landmarks for each finger with finger-specific colors
      fingerIndices.forEach((fingerName, indices) {
        final fingerPoints = indices.map((i) => points[i] * ratio).toList();
        final fingerPaint = Paint()
          ..color = fingerColors[fingerName] ?? primaryColor
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

        canvas.drawPoints(
          PointMode.polygon,
          fingerPoints,
          fingerPaint,
        );
      });

      // Draw finger states with improved styling
      final stateTextStyle = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );

      // Create a background for the status panel
      final statusPanelRect = Rect.fromLTWH(10, 10, 150, 170);
      final statusPanelPaint = Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      final statusPanelRRect = RRect.fromRectAndRadius(
        statusPanelRect,
        const Radius.circular(12),
      );

      canvas.drawRRect(statusPanelRRect, statusPanelPaint);

      // Draw title for the status panel
      const titleStyle = TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

      final titleSpan = TextSpan(
        text: 'Finger Status',
        style: titleStyle,
      );

      final titlePainter = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
      );

      titlePainter.layout();
      titlePainter.paint(
          canvas, Offset(statusPanelRect.left + 15, statusPanelRect.top + 10));

      // Draw divider line
      final dividerPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1;

      canvas.drawLine(
        Offset(statusPanelRect.left + 15, statusPanelRect.top + 35),
        Offset(statusPanelRect.right - 15, statusPanelRect.top + 35),
        dividerPaint,
      );

      // Draw finger states with improved styling
      double yOffset = statusPanelRect.top + 45; // Starting y position for text
      const double lineHeight = 20.0; // Spacing between lines

      fingerStates.forEach((finger, isOpen) {
        final dotColor = isOpen ? Colors.green : Colors.red;

        // Draw status dot
        final dotPaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(statusPanelRect.left + 25, yOffset + 6),
          4,
          dotPaint,
        );

        // Draw finger name and status
        final statusText = isOpen ? "Open" : "Closed";
        final textSpan = TextSpan(
          text: '$finger: ',
          style: stateTextStyle.copyWith(
            color: fingerColors[finger] ?? Colors.white,
          ),
          children: [
            TextSpan(
              text: statusText,
              style: stateTextStyle.copyWith(
                color: isOpen ? Colors.green : Colors.red,
              ),
            ),
          ],
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(canvas, Offset(statusPanelRect.left + 35, yOffset));
        yOffset += lineHeight + 4; // Move down for the next finger
      });
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
