import 'dart:math';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

class Stickman extends StatefulWidget {
  final AnimationController animationController;

  const Stickman({Key key, this.animationController}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _StickmanState(animationController);
  }
}

class _StickmanState extends State<Stickman>
    with SingleTickerProviderStateMixin {
  final AnimationController aController;

  _StickmanState(this.aController);

  @override
  void initState() {
    super.initState();
    aController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: StickmanPainter(aController.view));
  }
}

class _PathCalculator {
  final List<Point> footStages;
  final List<Point> kneeStages;
  final Point hip;
  final double partLength;

  static Point lerpPoint(Point a, Point b, double delta) =>
      Point(lerp(a.x, b.x, delta), lerp(a.y, b.y, delta));

  static double lerp(double a, double b, double delta) =>
      a * (1 - delta) + b * delta;

  _PathCalculator.fromPoints(
      {@required this.footStages,
      @required this.kneeStages,
      @required this.hip,
      @required this.partLength})
      : assert(footStages.length == kneeStages.length);

  List<Point> getPointsForProgress(double progress) {
    assert(progress >= 0.0);
    assert(progress <= 1.0);

    if (progress == 1.0) {
      return getPointsForProgress(0.0);
    }

    int stage = (footStages.length * progress).floor();
    int stageNext = (stage + 1) % footStages.length;
    int mirror = (stage + footStages.length ~/ 2) % footStages.length;
    int mirrorNext = (mirror + 1) % footStages.length;
    double stageProgress = (footStages.length * progress - stage);

    Point stageFootPoint =
        lerpPoint(footStages[stage], footStages[stageNext], stageProgress);
    Point stageKneePoint =
        lerpPoint(kneeStages[stage], kneeStages[stageNext], stageProgress);
    Point mirrorFootPoint =
        lerpPoint(footStages[mirror], footStages[mirrorNext], stageProgress);
    Point mirrorKneePoint =
        lerpPoint(kneeStages[mirror], kneeStages[mirrorNext], stageProgress);
    return [
      stageFootPoint,
      stageKneePoint,
      hip,
      mirrorKneePoint,
      mirrorFootPoint,
    ];
  }
}

class StickmanPainter extends CustomPainter {
  static const BALL_PARABOLA_HEIGHT_RATE = 1 / 5;

  static _PathCalculator legPointCalculator = _PathCalculator.fromPoints(
    footStages: [
      Point(0.243, 0.678),
      Point(0.314, 0.638),
      Point(0.357, 0.637),
      Point(0.4, 0.656),
      Point(0.471, 0.754),
      Point(0.557, 0.805),
      Point(0.621, 0.851),
      Point(0.7, 0.857),
      Point(0.769, 0.857),
      Point(0.764, 0.915),
      Point(0.75, 0.925),
      Point(0.707, 0.956),
      Point(0.536, 1.0),
      Point(0.443, 0.989),
      Point(0.343, 0.961),
      Point(0.243, 0.908),
      Point(0.193, 0.873),
      Point(0.2, 0.804),
    ],
    kneeStages: [
      Point(0.471, 0.759),
      Point(0.521, 0.763),
      Point(0.567, 0.757),
      Point(0.629, 0.734),
      Point(0.7, 0.676),
      Point(0.728, 0.634),
      Point(0.728, 0.634),
      Point(0.736, 0.617),
      Point(0.736, 0.617),
      Point(0.693, 0.684),
      Point(0.686, 0.691),
      Point(0.65, 0.721),
      Point(0.557, 0.759),
      Point(0.529, 0.763),
      Point(0.479, 0.76),
      Point(0.421, 0.744),
      Point(0.385, 0.726),
      Point(0.436, 0.75),
    ],
    hip: Point(.514, .521),
    partLength: .242,
  );

  static _PathCalculator armPointCalculator = _PathCalculator.fromPoints(
    footStages: [
      Point(0.457, 0.583),
      Point(0.521, 0.622),
      Point(0.622, 0.612),
      Point(0.715, 0.54),
      Point(0.736, 0.329),
      Point(0.757, 0.251),
      Point(0.721, 0.214),
      Point(0.7, 0.183),
      Point(0.686, 0.168),
      Point(0.757, 0.325),
      Point(0.7, 0.515),
      Point(0.657, 0.554),
      Point(0.493, 0.612),
      Point(0.385, 0.564),
      Point(0.372, 0.549),
      Point(0.348, 0.517),
      Point(0.364, 0.53),
      Point(0.4, 0.55),
    ],
    kneeStages: [
      Point(0.429, 0.383),
      Point(0.514, 0.42),
      Point(0.55, 0.423),
      Point(0.55, 0.423),
      Point(0.557, 0.423),
      Point(0.629, 0.407),
      Point(0.643, 0.4),
      Point(0.671, 0.383),
      Point(0.686, 0.37),
      Point(0.579, 0.421),
      Point(0.521, 0.421),
      Point(0.507, 0.418),
      Point(0.479, 0.41),
      Point(0.407, 0.364),
      Point(0.393, 0.348),
      Point(0.372, 0.316),
      Point(0.379, 0.329),
      Point(0.393, 0.348),
    ],
    hip: Point(.550, .221),
    partLength: .202,
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

  double _ballY(double progress, double amplitude) {
    if (progress == 0.0 || progress == 1.0) {
      return 0.0;
    }

    final double b = BALL_PARABOLA_HEIGHT_RATE;
    final int i = (2 * log(1 - progress) / log(b)).ceil();
    final double dI = (1 - sqrt(b)) * pow(b, (i - 1) / 2);
    final double sI = 1 - pow(b, (i - 1) / 2);
    return (pow(progress - sI - dI / 2, 2) - pow(dI / 2, 2)) *
        -2 *
        amplitude /
        dI;
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
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.093 * s;
    List<Point> legPoints = legPointCalculator.getPointsForProgress(progress);
    List<Point> armPoints = armPointCalculator.getPointsForProgress(progress);

    double ballY = _ballY(progress, s);
    double ballX = pow(progress - 1/2, 2) - 1/4;

    Paint dotPaint = Paint()
            ..color = Colors.black45
            ..style = PaintingStyle.fill;

    canvas
      ..drawPath(_pointsToPath(legPoints, s), _paint)
      ..drawPath(_pointsToPath(armPoints, s), _paint)
      ..drawCircle(
          Offset(.581 * s, .093 * s),
          .073 * s,
          dotPaint)
      ..drawCircle(Offset((.87 - ballX) * s, (0.85 * s) - ballY), .073 * s, dotPaint);
  }

  @override
  bool shouldRepaint(StickmanPainter oldDelegate) {
    return true;
  }
}
