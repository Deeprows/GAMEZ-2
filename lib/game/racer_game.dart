import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum RaceState { ready, running, paused, crashed }

class TrafficCar {
  TrafficCar(this.lane, this.depth, this.color);
  final int lane;
  double depth;
  final Color color;
}

class RacerGame extends FlameGame {
  final math.Random _random = math.Random();
  final List<TrafficCar> traffic = [];
  final ValueNotifier<int> hudNotifier = ValueNotifier<int>(0);

  RaceState state = RaceState.ready;
  double playerLane = 0;
  double speed = 0;
  double distance = 0;
  double nitro = 1;
  double roadOffset = 0;
  double spawnTimer = 0;
  bool nitroHeld = false;
  int best = 0;

  void startRace() {
    traffic.clear();
    playerLane = 0;
    speed = .58;
    distance = 0;
    nitro = 1;
    roadOffset = 0;
    spawnTimer = 0;
    state = RaceState.running;
    overlays.remove('start');
    overlays.remove('gameOver');
    overlays.remove('pause');
    resumeEngine();
    hudNotifier.value++;
  }

  void togglePause() {
    if (state == RaceState.running) {
      state = RaceState.paused;
      overlays.add('pause');
      pauseEngine();
    } else if (state == RaceState.paused) {
      state = RaceState.running;
      overlays.remove('pause');
      resumeEngine();
    }
    hudNotifier.value++;
  }

  void steer(double direction) {
    if (state == RaceState.running) {
      playerLane = (playerLane + direction).clamp(-1.0, 1.0);
    }
  }

  void setNitro(bool value) => nitroHeld = value;

  @override
  void update(double dt) {
    super.update(dt);
    if (state != RaceState.running) return;
    hudNotifier.value++;

    final boost = nitroHeld && nitro > .015;
    if (boost) {
      nitro = (nitro - dt * .27).clamp(0.0, 1.0);
      speed = (speed + dt * .45).clamp(.58, 1.0);
    } else {
      nitro = (nitro + dt * .075).clamp(0.0, 1.0);
      speed = (speed - dt * .10).clamp(.58, .78);
    }

    distance += dt * speed * 82;
    roadOffset = (roadOffset + dt * speed * 1.8) % 1;
    spawnTimer += dt;

    if (spawnTimer > (.82 - speed * .25)) {
      spawnTimer = 0;
      traffic.add(TrafficCar(
        _random.nextInt(3) - 1,
        0,
        [const Color(0xFFFFB000), const Color(0xFFB66BFF), const Color(0xFF42E695)][_random.nextInt(3)],
      ));
    }

    for (final car in traffic) {
      car.depth += dt * (.25 + speed * .30);
      if ((car.depth - .88).abs() < .045 &&
          (car.lane - playerLane).abs() < .48) {
        _crash();
        break;
      }
    }
    traffic.removeWhere((car) => car.depth > 1.12);
  }

  void _crash() {
    state = RaceState.crashed;
    best = math.max(best, distance.round());
    overlays.add('gameOver');
    pauseEngine();
    hudNotifier.value++;
  }

  double _y(double t, double top, double bottom) => top + (bottom - top) * t * t;
  double _half(double t, double top, double bottom) => top + (bottom - top) * t;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF080D25), Color(0xFF17254A), Color(0xFF101522)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    final horizon = h * .39;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF00E5FF).withOpacity(.22), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(w * .5, horizon), radius: w * .55));
    canvas.drawRect(Rect.fromLTWH(0, horizon - 100, w, h * .5), glow);

    final skyline = Paint()..color = const Color(0xFF10182D);
    for (var i = 0; i < 19; i++) {
      final bw = w / 19;
      final bh = (.05 + ((i * 37) % 11) / 100) * h;
      canvas.drawRect(Rect.fromLTWH(i * bw, horizon - bh, bw - 2, bh), skyline);
    }

    final topHalf = w * .075;
    final bottomHalf = w * .49;
    final road = Path()
      ..moveTo(w / 2 - topHalf, horizon)
      ..lineTo(w / 2 + topHalf, horizon)
      ..lineTo(w / 2 + bottomHalf, h * 1.06)
      ..lineTo(w / 2 - bottomHalf, h * 1.06)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF252B3A));

    final edge = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(.85)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(w / 2 - topHalf, horizon), Offset(w / 2 - bottomHalf, h * 1.06), edge);
    canvas.drawLine(Offset(w / 2 + topHalf, horizon), Offset(w / 2 + bottomHalf, h * 1.06), edge);

    for (var i = 0; i < 18; i++) {
      final t = (i / 18 + roadOffset) % 1;
      final y = _y(t, horizon, h * 1.06);
      final half = _half(t, topHalf, bottomHalf);
      final sw = 2 + t * 8;
      final sh = 3 + t * 18;
      final paint = Paint()..color = i.isEven ? const Color(0xFFFF3D81) : Colors.white70;
      canvas.drawRect(Rect.fromCenter(center: Offset(w / 2 - half - sw, y), width: sw, height: sh), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset(w / 2 + half + sw, y), width: sw, height: sh), paint);
    }

    for (var lane = 1; lane <= 2; lane++) {
      for (var i = 0; i < 12; i++) {
        final t = (i / 12 + roadOffset) % 1;
        final y = _y(t, horizon, h * 1.06);
        final half = _half(t, topHalf, bottomHalf);
        final x = w / 2 - half + half * 2 * lane / 3;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 2 + t * 4, height: 5 + t * 25),
            const Radius.circular(4),
          ),
          Paint()..color = Colors.white.withOpacity(.18 + t * .45),
        );
      }
    }

    final sorted = [...traffic]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final car in sorted) {
      _drawCar(canvas, w, h, car.lane.toDouble(), car.depth, car.color, false);
    }
    _drawCar(canvas, w, h, playerLane, .88, const Color(0xFF00D8FF), true);
  }

  void _drawCar(Canvas canvas, double w, double h, double lane, double depth, Color color, bool player) {
    final t = depth.clamp(0.0, 1.0);
    final roadHalf = _half(t, w * .075, w * .49);
    final x = w / 2 + lane * roadHalf * .66;
    final y = _y(t, h * .39, h * 1.02);
    final carW = (w * (.035 + t * .115)).clamp(16.0, w * .24);
    final carH = carW * 1.55;
    final body = Rect.fromCenter(center: Offset(x, y), width: carW, height: carH);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + carH * .35), width: carW * 1.25, height: carH * .35),
      Paint()..color = Colors.black.withOpacity(.48),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(.65), color, color.withOpacity(.55)],
      ).createShader(body);
    final shape = Path()
      ..moveTo(x - carW * .48, y + carH * .42)
      ..lineTo(x - carW * .43, y - carH * .30)
      ..quadraticBezierTo(x - carW * .30, y - carH * .52, x, y - carH * .50)
      ..quadraticBezierTo(x + carW * .30, y - carH * .52, x + carW * .43, y - carH * .30)
      ..lineTo(x + carW * .48, y + carH * .42)
      ..close();
    canvas.drawPath(shape, bodyPaint);

    final glass = Path()
      ..moveTo(x - carW * .29, y - carH * .22)
      ..quadraticBezierTo(x, y - carH * .43, x + carW * .29, y - carH * .22)
      ..lineTo(x + carW * .24, y + carH * .02)
      ..lineTo(x - carW * .24, y + carH * .02)
      ..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xFF101C32));

    final lights = Paint()..color = player ? Colors.white : const Color(0xFFFF334F);
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + side * carW * .29, y + carH * .30), width: carW * .15, height: carH * .10),
          Radius.circular(carW * .03),
        ),
        lights,
      );
    }
  }
}
