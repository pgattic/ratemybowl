import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedToiletPaperRoll extends StatefulWidget {
  final int sheets; // 1..maxSheets (slider snaps to integers)
  final int maxSheets;
  final double? width;
  final Color rollColor;
  final Color paperColor;
  final double rollSizeFactor;

  const AnimatedToiletPaperRoll({
    super.key,
    required this.sheets,
    required this.maxSheets,
    this.width,
    this.rollColor = Colors.white,
    this.paperColor = Colors.white,
    this.rollSizeFactor = 1.0,
  });

  @override
  State<AnimatedToiletPaperRoll> createState() =>
      _AnimatedToiletPaperRollState();
}

class _AnimatedToiletPaperRollState extends State<AnimatedToiletPaperRoll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _lastProgress = 0.0; // track previous progress
  int _previousSheets = 0; // track previous sheets

  double _sheetToProgress(int sheet) {
    final clamped = sheet.clamp(1, widget.maxSheets);
    if (widget.maxSheets <= 1) return 1.0;
    return clamped / widget.maxSheets;
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 650),
          value: _sheetToProgress(widget.sheets),
        )..addListener(() {
          setState(() {
            _lastProgress = _controller.value; // update last progress
          });
        });
    _previousSheets = widget.sheets; // Initialize with current sheets
  }

  @override
  void didUpdateWidget(covariant AnimatedToiletPaperRoll oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheets != widget.sheets ||
        oldWidget.maxSheets != widget.maxSheets) {
      final target = _sheetToProgress(widget.sheets);
      _controller.animateTo(
        target.clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
      _previousSheets = oldWidget.sheets; // Update previous sheets
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double useWidth = (widget.width ?? (constraints.maxWidth * 0.9))
            .clamp(200.0, constraints.maxWidth);
        return SizedBox(
          height: 100,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(useWidth, 260),
                painter: _UprightToiletPaperPainter(
                  sheets: widget.sheets,
                  progress: _controller.value,
                  lastProgress: _lastProgress,
                  maxSheets: widget.maxSheets,
                  rollColor: widget.rollColor,
                  paperColor: widget.paperColor,
                  rollSizeFactor: widget.rollSizeFactor,
                  previousSheets: _previousSheets, // Pass previous sheets
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _UprightToiletPaperPainter extends CustomPainter {
  final int sheets; // Current sheet count
  final double progress; // Animation progress (0.0 to 1.0)
  final int maxSheets; // Maximum sheet count
  final Color rollColor; // Color of the toilet paper roll
  final Color paperColor; // Color of the paper
  final double rollSizeFactor; // Scaling factor for roll size
  final double lastProgress; // Previous animation progress
  final int previousSheets; // Previous sheet count for direction detection

  _UprightToiletPaperPainter({
    required this.sheets,
    required this.progress,
    required this.lastProgress,
    required this.maxSheets,
    required this.rollColor,
    required this.paperColor,
    this.rollSizeFactor = 1.0,
    required this.previousSheets,
  });

  // Linear interpolation helper
  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final double canvasW = size.width;
    final double canvasH = size.height;

    // Compute blend for color transition between sheets 4 and 5
    final double sheetsProgress = progress * maxSheets;
    double localBlend = 0.0;
    if (sheetsProgress > 4.0 && sheetsProgress <= 5.0) {
      localBlend = (sheetsProgress - 4.0).clamp(0.0, 1.0);
    } else if (sheetsProgress > 5.0) {
      localBlend = 1.0;
    }

    // ────────────────────── Roll Dimensions ──────────────────────
    final double baseMaxWidth = canvasW * 0.30;
    final double scaledMaxWidth = baseMaxWidth * rollSizeFactor;
    final double rollWidth = scaledMaxWidth.clamp(40.0, 200.0);
    final double ellipseH = rollWidth * 0.36;
    final double rollBodyH = rollWidth * 0.8;
    final double reservedBottom = 44.0 + 30.0 + 10.0 + 20.0;
    final double availableHeight = canvasH - reservedBottom;
    final double totalRollHeight = ellipseH + rollBodyH + ellipseH;
    double rollTop = (availableHeight - totalRollHeight) / 2 + 20.0;
    rollTop = rollTop.clamp(20.0, canvasH * 0.4);
    final double rollLeft = 14.0;

    // ────────────────────── Paper Dimensions ──────────────────────
    final double availableRight = canvasW - (rollLeft + rollWidth + 12.0);
    final double fullPaperLen = math.max(availableRight - 8.0, 120.0);
    final double currentPaperLen = _lerp(0.0, fullPaperLen, progress);

    // ────────────────────── Paints ──────────────────────
    final paintRoll = Paint()
      ..color = Color.lerp(rollColor, Colors.amber.shade200, localBlend)!;
    final paintRollStroke = Paint()
      ..color = Color.lerp(
        Colors.grey.shade400,
        Colors.amber.shade700,
        localBlend,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final paintCore = Paint()..color = const Color.fromARGB(255, 137, 96, 0);
    final paintPaper = Paint()
      ..color = Color.lerp(paperColor, Colors.amber.shade100, localBlend)!;
    final paintPaperStroke = Paint()
      ..color = Color.lerp(
        Colors.grey.shade300,
        Colors.amber.shade700,
        localBlend,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final rollPerfPaint = Paint()
      ..color = Color.lerp(
        Colors.grey.shade600,
        Colors.amber.shade900,
        localBlend,
      )!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final perfPaint = Paint()
      ..color = Color.lerp(
        Colors.grey.shade500,
        Colors.amber.shade800,
        localBlend,
      )!
      ..strokeWidth = 1.0;

    // ────────────────────── Roll (Top and Bottom Ovals, Body) ──────────────────────
    final Rect topOval = Rect.fromLTWH(rollLeft, rollTop, rollWidth, ellipseH);
    final Rect bottomOval = Rect.fromLTWH(
      rollLeft,
      rollTop + rollBodyH,
      rollWidth,
      ellipseH,
    );
    final Rect sideRect = Rect.fromLTWH(
      rollLeft,
      rollTop + ellipseH / 2,
      rollWidth,
      rollBodyH,
    );
    final RRect sideRRect = RRect.fromRectAndRadius(
      sideRect.inflate(0.5),
      const Radius.circular(6),
    );
    final double innerFactor = 0.42;
    final Rect innerTop = Rect.fromLTWH(
      rollLeft + rollWidth * (1 - innerFactor) / 2,
      rollTop + ellipseH * (1 - innerFactor) / 2,
      rollWidth * innerFactor,
      ellipseH * innerFactor,
    );

    // ────────────────────── Paper Sheet ──────────────────────
    final double sheetLeft = rollLeft + rollWidth - 2;
    final double sheetTop = rollTop + ellipseH + rollBodyH * 0.5;
    final double sheetHeight = rollBodyH;
    final Rect sheetRect = Rect.fromLTWH(
      sheetLeft - 2,
      (sheetTop - sheetHeight / 2) * 0.8,
      currentPaperLen,
      sheetHeight,
    );
    final Rect shadowRect = sheetRect.translate(6, 8).inflate(0.5);

    // Draw shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(6)),
      Paint()..color = Colors.black.withOpacity(0.06),
    );

    // Draw paper
    canvas.drawRect(sheetRect, paintPaper);
    canvas.drawRect(sheetRect, paintPaperStroke);

    // ────────────────────── Perforation Lines on Paper ──────────────────────
    if (maxSheets > 1) {
      final double seg = fullPaperLen / maxSheets;
      const double dash = 3.0;
      const double gap = 2.0;
      for (int i = 1; i < maxSheets; i++) {
        final double x = sheetLeft + seg * i;
        if (x < sheetLeft + currentPaperLen) {
          double y = sheetRect.top + 4.0;
          final double y2 = sheetRect.bottom - 4.0;
          while (y < y2) {
            final double yEnd = (y + dash).clamp(y, y2);
            canvas.drawLine(Offset(x, y), Offset(x, yEnd), perfPaint);
            y += dash + gap;
          }
        }
      }
    }

    // ────────────────────── Roll Body and Edges ──────────────────────
    canvas.drawOval(bottomOval, paintRoll);
    canvas.drawOval(bottomOval, paintRollStroke);
    canvas.drawRRect(
      sideRRect,
      Paint()
        ..color = Color.lerp(Colors.white, Colors.amber.shade200, localBlend)!,
    );
    final Paint edgePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final Path edgePath = Path()
      ..moveTo(sideRect.left, sideRect.top)
      ..lineTo(sideRect.left, sideRect.bottom)
      ..moveTo(sideRect.right, sideRect.top)
      ..lineTo(sideRect.right, sideRect.bottom);
    canvas.drawPath(edgePath, edgePaint);

    // Draw top oval and core
    canvas.drawOval(topOval, paintRoll);
    canvas.drawOval(topOval, paintRollStroke);
    canvas.drawOval(innerTop, paintCore);
    canvas.drawOval(
      innerTop,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.grey.shade400,
    );

    // ────────────────────── Roll Perforation Lines ──────────────────────
    final int rollPerfCount = 6;
    final double lineHeight = 20.0;
    final double rx = topOval.width * 0.50;
    final double ry = topOval.height * 0.55;
    final double cx = topOval.center.dx;
    final double cy = topOval.center.dy * 1.75;
    const double dash2 = 3.0;
    const double gap2 = 2.0;
    final double rotation = progress * math.pi * 2;
    for (int i = 0; i < rollPerfCount; i++) {
      final double angle = (i / rollPerfCount) * math.pi * 2 + rotation;
      final double xCenter = cx + rx * math.cos(angle);
      final double yCenter = cy + ry * math.sin(angle);
      if (yCenter < cy) continue;
      double y = yCenter - lineHeight;
      final double y2 = yCenter + lineHeight;
      while (y < y2) {
        final double yEnd = (y + dash2).clamp(y, y2);
        canvas.drawLine(
          Offset(xCenter, y),
          Offset(xCenter, yEnd),
          rollPerfPaint,
        );
        y += dash2 + gap2;
      }
    }

    // ────────────────────── Sheet Numbers ──────────────────────
    if (maxSheets > 1) {
      final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      final double seg = fullPaperLen / maxSheets;
      final int selectedSheet = (progress * maxSheets).round().clamp(
        1,
        maxSheets,
      );
      for (int i = 1; i <= maxSheets; i++) {
        double sheetProgress = (progress * maxSheets - (i - 1)).clamp(0.0, 1.0);
        if (sheetProgress <= 0.0) continue;
        final double opacity = Curves.easeOut.transform(sheetProgress);
        final double xCenter = sheetLeft + seg * (i - 0.5);
        final Color baseColor = Colors.grey.shade700;
        final Color goldColor = Colors.amber.shade700;
        final double blend = (i == selectedSheet ? sheetProgress : 0.0);
        final Color color = Color.lerp(
          baseColor,
          goldColor,
          blend,
        )!.withOpacity(opacity);
        textPainter.text = TextSpan(
          text: '$i',
          style: TextStyle(
            color: color,
            fontSize: sheetHeight * 0.28,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final Offset textOffset = Offset(
          xCenter - textPainter.width / 2,
          sheetRect.center.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }

    // ────────────────────── Sparkles ──────────────────────
    // Only show sparkles when transitioning from 4 to 5 sheets
    if (previousSheets <= 4 && sheets == 5) {
      final int sparkleCount = 6;
      final Paint sparklePaint = Paint()..color = Colors.amber.shade300;
      final math.Random rnd = math.Random(42); // Fixed seed for consistency
      final double sparkleProgress = (sheetsProgress - 4.0).clamp(0.0, 1.0);
      final double opacity = Curves.easeOut.transform(1.0 - sparkleProgress);
      for (int i = 0; i < sparkleCount; i++) {
        final double sx = sheetRect.left + currentPaperLen * rnd.nextDouble();
        final double sy = sheetRect.top + sheetHeight * rnd.nextDouble();
        final double size = 3.0 + rnd.nextDouble() * 4.0;
        final double rOuter = size;
        final double rInner = size * 0.4;
        final Path starPath = Path();
        for (int j = 0; j < 4; j++) {
          final double angleOuter = (math.pi / 2) * j;
          final double angleInner = angleOuter + math.pi / 4;
          final double xOuter = sx + rOuter * math.cos(angleOuter);
          final double yOuter = sy + rOuter * math.sin(angleOuter);
          final double xInner = sx + rInner * math.cos(angleInner);
          final double yInner = sy + rInner * math.sin(angleInner);
          if (j == 0) {
            starPath.moveTo(xOuter, yOuter);
          } else {
            starPath.lineTo(xOuter, yOuter);
          }
          starPath.lineTo(xInner, yInner);
        }
        starPath.close();
        sparklePaint.color = sparklePaint.color.withOpacity(opacity);
        canvas.drawPath(starPath, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UprightToiletPaperPainter old) {
    return old.progress != progress ||
        old.lastProgress != lastProgress ||
        old.maxSheets != maxSheets ||
        old.rollColor != rollColor ||
        old.paperColor != paperColor ||
        old.rollSizeFactor != rollSizeFactor ||
        old.sheets != sheets ||
        old.previousSheets != previousSheets;
  }
}
