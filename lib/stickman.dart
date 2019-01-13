import 'dart:math';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class Stickman extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _StickmanState();
  }
}

class _StickmanState extends State<Stickman>
    with SingleTickerProviderStateMixin {
  AnimationController aController;

  @override
  void initState() {
    super.initState();
    aController =
        AnimationController(vsync: this, duration: Duration(seconds: 30));
    aController.repeat();
    aController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    aController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: StickmanPainter(aController.view));
  }
}

class _PathCalculator {
  final List<double> footStagesX;
  final List<double> kneeStagesX;
  final Point hip;
  final double partLength;
  final List<int> kneeFootDirectionUpIndexes;

  static double lerp(double a, double b, double delta) =>
      a * (1 - delta) + b * delta;

  _PathCalculator(
      {@required this.footStagesX,
      @required this.kneeStagesX,
      @required this.hip,
      @required this.partLength,
      @required this.kneeFootDirectionUpIndexes});

  double _getTargetY(
      {@required double sourceX,
      @required double sourceY,
      @required double targetX,
      @required bool upwards}) {
    final sqDelta = pow(partLength, 2) - pow(sourceX - targetX, 2);
    final yDelta = sqDelta > 0.0 ? sqrt(sqDelta) : 0;
    return upwards ? sourceY - yDelta : sourceY + yDelta;
  }

  List<Point> getPointsForProgress(double progress) {
    assert(progress >= 0.0);
    assert(progress <= 1.0);

    if (progress == 1.0) {
      return getPointsForProgress(0.0);
    }

    int stage = (footStagesX.length * progress).floor();
    int mirror = (stage + footStagesX.length ~/ 2) % footStagesX.length;
    double stageProgress = (footStagesX.length * progress - stage);

    double stageFootX = lerp(footStagesX[stage],
        footStagesX[(stage + 1) % footStagesX.length], stageProgress);
    double stageKneeX = lerp(kneeStagesX[stage],
        kneeStagesX[(stage + 1) % footStagesX.length], stageProgress);
    double mirrorFootX = lerp(footStagesX[mirror],
        footStagesX[(mirror + 1) % footStagesX.length], stageProgress);
    double mirrorKneeX = lerp(kneeStagesX[mirror],
        kneeStagesX[(mirror + 1) % footStagesX.length], stageProgress);

    final stageKneeY = _getTargetY(
        sourceX: hip.x, sourceY: hip.y, targetX: stageKneeX, upwards: false);
    final stageFootY = _getTargetY(
        sourceX: stageKneeX,
        sourceY: stageKneeY,
        targetX: stageFootX,
        upwards: kneeFootDirectionUpIndexes.contains(stage));

    final mirrorKneeY = _getTargetY(
        sourceX: hip.x, sourceY: hip.y, targetX: mirrorKneeX, upwards: false);
    final mirrorFootY = _getTargetY(
        sourceX: mirrorKneeX,
        sourceY: mirrorKneeY,
        targetX: mirrorFootX,
        upwards: kneeFootDirectionUpIndexes.contains(mirror));

    return [
      Point(stageFootX, stageFootY),
      Point(stageKneeX, stageKneeY),
      hip,
      Point(mirrorKneeX, mirrorKneeY),
      Point(mirrorFootX, mirrorFootY)
    ];
  }
}

class StickmanPainter extends CustomPainter {
  static _PathCalculator legCalculator = _PathCalculator(
    footStagesX: [
      .243,
      .314,
      .357,
      .400,
      .471,
      .557,
      .621,
      .629,
      .769,
      .764,
      .750,
      .707,
      .536,
      .443,
      .343,
      .243,
      .193,
      .200,
    ],
    kneeStagesX: [
      .471,
      .521,
      .567,
      .629,
      .700,
      .728,
      .728,
      .736,
      .736,
      .693,
      .686,
      .650,
      .557,
      .529,
      .479,
      .421,
      .385,
      .436,
    ],
    kneeFootDirectionUpIndexes: [0, 1, 2, 3],
    hip: Point(.514, .521),
    partLength: .242,
  );

  static _PathCalculator armCalculator = _PathCalculator(
    footStagesX: [
      .457,
      .521,
      .622,
      .715,
      .736,
      .757,
      .721,
      .700,
      .686,
      .757,
      .700,
      .657,
      .493,
      .385,
      .372,
      .348,
      .364,
      .400,
    ],
    kneeStagesX: [
      .429,
      .514,
      .550,
      .550,
      .557,
      .629,
      .643,
      .671,
      .686,
      .579,
      .521,
      .507,
      .479,
      .407,
      .393,
      .372,
      .379,
      .393,
    ],
    hip: Point(.550, .221),
    partLength: .202,
    kneeFootDirectionUpIndexes: [4, 5, 6, 7, 8, 9],
  );

  final Animation<double> aController;

  StickmanPainter(this.aController);

  Size _calculateActualSize(Size canvasSize) {
    if (canvasSize.isInfinite) {
      return Size(100.0, 100.0);
    }
    return Size(min(canvasSize.width, canvasSize.height),
        min(canvasSize.width, canvasSize.height));
  }

  Path _pointsToPath(List<Point> points, double scale) {
    assert(points.isNotEmpty);
    final Path path = Path()..moveTo(points[0].x * scale, points[0].y * scale);
    points.skip(1).forEach((point) {
      return path.lineTo(point.x * scale, point.y * scale);
    });
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final progress = aController == null ? 0.0 : aController.value;
    final Size actualSize = _calculateActualSize(size);
    final double s = actualSize.width;

    final _paint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 0.093 * s;
    List<Point> legPoints = legCalculator.getPointsForProgress(progress);
    List<Point> armPoints = armCalculator.getPointsForProgress(progress);

    canvas
      ..drawPath(_pointsToPath(legPoints, s), _paint)
      ..drawPath(_pointsToPath(armPoints, s), _paint)
      ..drawCircle(
          Offset(.571 * s, .1 * s),
          .093 * s,
          Paint()
            ..color = Colors.black45
            ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(StickmanPainter oldDelegate) {
    return true;
  }
}
