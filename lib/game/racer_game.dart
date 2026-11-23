import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RaceState { ready, running, paused, crashed, finished }
enum RaceEnvironment { neonCity, desert, countryside, midnight }
enum MenuPage { home, garage, environments, career }

class RaceCar {
  const RaceCar({
    required this.id,
    required this.name,
    required this.price,
    required this.topSpeed,
    required this.acceleration,
    required this.handling,
    required this.color,
  });
  final String id;
  final String name;
  final int price;
  final double topSpeed;
  final double acceleration;
  final double handling;
  final Color color;
}

const raceCars = <RaceCar>[
  RaceCar(id: 'street', name: 'Street R', price: 0, topSpeed: 0.78, acceleration: .72, handling: .76, color: Color(0xFF00D8FF)),
  RaceCar(id: 'blaze', name: 'Blaze GT', price: 350, topSpeed: .88, acceleration: .82, handling: .70, color: Color(0xFFFF4B45)),
  RaceCar(id: 'phantom', name: 'Phantom X', price: 700, topSpeed: .96, acceleration: .90, handling: .84, color: Color(0xFFB66BFF)),
  RaceCar(id: 'volt', name: 'Volt RS', price: 1100, topSpeed: 1.0, acceleration: .96, handling: .94, color: Color(0xFFFFD447)),
];

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
  MenuPage menuPage = MenuPage.home;
  RaceEnvironment environment = RaceEnvironment.neonCity;
  String selectedCarId = 'street';
  final Set<String> unlockedCars = {'street'};
  int coins = 0;
  int level = 1;
  int racesWon = 0;
  int bestDistance = 0;
  double playerLane = 0;
  double speed = 0;
  double distance = 0;
  double nitro = 1;
  double roadOffset = 0;
  double spawnTimer = 0;
  bool nitroHeld = false;
  bool throttleHeld = true;
  bool brakeHeld = false;
  bool driftHeld = false;
  bool drifting = false;
  int lastReward = 0;

  RaceCar get selectedCar => raceCars.firstWhere((car) => car.id == selectedCarId);

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('nv_coins') ?? 0;
    level = prefs.getInt('nv_level') ?? 1;
    racesWon = prefs.getInt('nv_wins') ?? 0;
    bestDistance = prefs.getInt('nv_best') ?? 0;
    selectedCarId = prefs.getString('nv_car') ?? 'street';
    unlockedCars
      ..clear()
      ..addAll(prefs.getStringList('nv_unlocked') ?? ['street']);
    if (!unlockedCars.contains('street')) unlockedCars.add('street');
    hudNotifier.value++;
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nv_coins', coins);
    await prefs.setInt('nv_level', level);
    await prefs.setInt('nv_wins', racesWon);
    await prefs.setInt('nv_best', bestDistance);
    await prefs.setString('nv_car', selectedCarId);
    await prefs.setStringList('nv_unlocked', unlockedCars.toList());
  }

  void showPage(MenuPage page) {
    menuPage = page;
    hudNotifier.value++;
  }

  bool buyOrSelectCar(RaceCar car) {
    if (unlockedCars.contains(car.id)) {
      selectedCarId = car.id;
      _saveProgress();
      hudNotifier.value++;
      return true;
    }
    if (coins < car.price) return false;
    coins -= car.price;
    unlockedCars.add(car.id);
    selectedCarId = car.id;
    _saveProgress();
    hudNotifier.value++;
    return true;
  }

  void chooseEnvironment(RaceEnvironment value) {
    environment = value;
    hudNotifier.value++;
  }

  void startRace() {
    traffic.clear();
    playerLane = 0;
    speed = 0;
    distance = 0;
    nitro = 1;
    roadOffset = 0;
    spawnTimer = 0;
    throttleHeld = true;
    brakeHeld = false;
    driftHeld = false;
    nitroHeld = false;
    drifting = false;
    lastReward = 0;
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
      final grip = driftHeld ? .72 : selectedCar.handling;
      playerLane = (playerLane + direction * grip).clamp(-1.0, 1.0).toDouble();
    }
  }

  void setThrottle(bool value) => throttleHeld = value;
  void setBrake(bool value) => brakeHeld = value;
  void setDrift(bool value) {
    driftHeld = value;
    drifting = value;
  }
  void setNitro(bool value) => nitroHeld = value;

  @override
  void update(double dt) {
    super.update(dt);
    if (state != RaceState.running) return;
    final boost = nitroHeld && nitro > .01;
    final acceleration = selectedCar.acceleration;
    if (boost) {
      nitro = (nitro - dt * .24).clamp(0.0, 1.0).toDouble();
      speed += dt * .55;
    } else if (throttleHeld && !brakeHeld) {
      speed += dt * (.20 + acceleration * .32);
      nitro = (nitro + dt * (driftHeld ? .16 : .035)).clamp(0.0, 1.0).toDouble();
    } else if (brakeHeld) {
      speed -= dt * .72;
    } else {
      speed -= dt * .16;
      nitro = (nitro + dt * .06).clamp(0.0, 1.0).toDouble();
    }
    final cap = selectedCar.topSpeed * (boost ? 1.22 : 1.0);
    speed = speed.clamp(0.0, cap).toDouble();
    if (speed > .04) {
      distance += dt * speed * 110;
      roadOffset = (roadOffset + dt * speed * (drifting ? 2.2 : 1.8)) % 1;
    }
    spawnTimer += dt;
    if (speed > .12 && spawnTimer > (.95 - speed * .28)) {
      spawnTimer = 0;
      traffic.add(TrafficCar(
        _random.nextInt(3) - 1,
        0,
        [const Color(0xFFFFB000), const Color(0xFFB66BFF), const Color(0xFF42E695)][_random.nextInt(3)],
      ));
    }
    for (final car in traffic) {
      car.depth += dt * (.12 + speed * .42);
      if ((car.depth - .88).abs() < .045 && (car.lane - playerLane).abs() < .43) {
        _finishRace(won: false);
        break;
      }
    }
    traffic.removeWhere((car) => car.depth > 1.12);
    if (distance >= _raceTarget) _finishRace(won: true);
    hudNotifier.value++;
  }

  double get _raceTarget => 900 + (level - 1) * 125;

  void _finishRace({required bool won}) {
    if (state != RaceState.running) return;
    state = won ? RaceState.finished : RaceState.crashed;
    bestDistance = math.max(bestDistance, distance.round());
    lastReward = won ? 120 + level * 30 + (drifting ? 25 : 0) : (distance / 30).floor();
    coins += lastReward;
    if (won) {
      racesWon++;
      level++;
    }
    _saveProgress();
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
    final palette = _palette;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()
      ..shader = LinearGradient(colors: palette, begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, w, h)));

    final horizon = h * .39;
    _drawScenery(canvas, w, h, horizon);
    final topHalf = w * .075;
    final bottomHalf = w * .49;
    final road = Path()
      ..moveTo(w / 2 - topHalf, horizon)
      ..lineTo(w / 2 + topHalf, horizon)
      ..lineTo(w / 2 + bottomHalf, h * 1.06)
      ..lineTo(w / 2 - bottomHalf, h * 1.06)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF252B3A));
    final edge = Paint()..color = _accent.withOpacity(.9)..strokeWidth = 3;
    canvas.drawLine(Offset(w / 2 - topHalf, horizon), Offset(w / 2 - bottomHalf, h * 1.06), edge);
    canvas.drawLine(Offset(w / 2 + topHalf, horizon), Offset(w / 2 + bottomHalf, h * 1.06), edge);

    for (var i = 0; i < 18; i++) {
      final t = (i / 18 + roadOffset) % 1;
      final y = _y(t, horizon, h * 1.06);
      final half = _half(t, topHalf, bottomHalf);
      final sw = 2 + t * 8;
      final sh = 3 + t * 18;
      final paint = Paint()..color = i.isEven ? _accent : Colors.white70;
      canvas.drawRect(Rect.fromCenter(center: Offset(w / 2 - half - sw, y), width: sw, height: sh), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset(w / 2 + half + sw, y), width: sw, height: sh), paint);
    }
    for (var lane = 1; lane <= 2; lane++) {
      for (var i = 0; i < 12; i++) {
        final t = (i / 12 + roadOffset) % 1;
        final y = _y(t, horizon, h * 1.06);
        final half = _half(t, topHalf, bottomHalf);
        final x = w / 2 - half + half * 2 * lane / 3;
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 2 + t * 4, height: 5 + t * 25),
          const Radius.circular(4)), Paint()..color = Colors.white.withOpacity(.18 + t * .45));
      }
    }
    final sorted = [...traffic]..sort((a, b) => a.depth.compareTo(b.depth));
    for (final car in sorted) {
      _drawCar(canvas, w, h, car.lane.toDouble(), car.depth, car.color, false);
    }
    _drawCar(canvas, w, h, playerLane, .88, selectedCar.color, true);
  }

  List<Color> get _palette => switch (environment) {
    RaceEnvironment.neonCity => const [Color(0xFF080D25), Color(0xFF17254A), Color(0xFF101522)],
    RaceEnvironment.desert => const [Color(0xFF5B3150), Color(0xFFE59A55), Color(0xFF6C3D2D)],
    RaceEnvironment.countryside => const [Color(0xFF4C9BBA), Color(0xFF8BCB83), Color(0xFF284B38)],
    RaceEnvironment.midnight => const [Color(0xFF02030B), Color(0xFF10112D), Color(0xFF080914)],
  };

  Color get _accent => switch (environment) {
    RaceEnvironment.desert => const Color(0xFFFFC06B),
    RaceEnvironment.countryside => const Color(0xFF9BEB91),
    RaceEnvironment.midnight => const Color(0xFF9D83FF),
    RaceEnvironment.neonCity => const Color(0xFF00E5FF),
  };

  void _drawScenery(Canvas canvas, double w, double h, double horizon) {
    final accent = _accent;
    if (environment == RaceEnvironment.countryside || environment == RaceEnvironment.desert) {
      final hill = Paint()..color = environment == RaceEnvironment.desert ? const Color(0xFFB76D45) : const Color(0xFF356B4A);
      final path = Path()..moveTo(0, horizon + 22)..quadraticBezierTo(w * .2, horizon - 70, w * .42, horizon + 18)
        ..quadraticBezierTo(w * .72, horizon - 65, w, horizon + 10)..lineTo(w, horizon + 100)..lineTo(0, horizon + 100)..close();
      canvas.drawPath(path, hill);
      if (environment == RaceEnvironment.desert) {
        final sun = Paint()..color = const Color(0xFFFFD28A).withOpacity(.75);
        canvas.drawCircle(Offset(w * .78, h * .19), w * .07, sun);
      } else {
        for (var i = 0; i < 12; i++) {
          final x = (i * 91.0) % w;
          canvas.drawCircle(Offset(x, horizon + 15 + (i % 3) * 8), 9 + (i % 3) * 3, Paint()..color = const Color(0xFF214E3A));
        }
      }
    } else {
      final skyline = Paint()..color = const Color(0xFF10182D);
      for (var i = 0; i < 19; i++) {
        final bw = w / 19;
        final bh = (.05 + ((i * 37) % 11) / 100) * h;
        canvas.drawRect(Rect.fromLTWH(i * bw, horizon - bh, bw - 2, bh), skyline);
        for (var j = 0; j < 3; j++) {
          canvas.drawRect(Rect.fromLTWH(i * bw + 4, horizon - bh + 7 + j * 10, 3, 4),
            Paint()..color = accent.withOpacity(.28));
        }
      }
    }
  }

  void _drawCar(Canvas canvas, double w, double h, double lane, double depth, Color color, bool player) {
    final t = depth.clamp(0.0, 1.0).toDouble();
    final roadHalf = _half(t, w * .075, w * .49);
    final x = w / 2 + lane * roadHalf * .66;
    final y = _y(t, h * .39, h * 1.02);
    final carW = (w * (.035 + t * .115)).clamp(16.0, w * .24).toDouble();
    final carH = carW * 1.55;
    final body = Rect.fromCenter(center: Offset(x, y), width: carW, height: carH);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + carH * .35), width: carW * 1.25, height: carH * .35),
      Paint()..color = Colors.black.withOpacity(.48));
    final bodyPaint = Paint()..shader = LinearGradient(
      colors: [color.withOpacity(.65), color, color.withOpacity(.55)],
    ).createShader(body);
    final shape = Path()
      ..moveTo(x - carW * .48, y + carH * .42)
      ..lineTo(x - carW * .43, y - carH * .30)
      ..quadraticBezierTo(x - carW * .30, y - carH * .52, x, y - carH * .50)
      ..quadraticBezierTo(x + carW * .30, y - carH * .52, x + carW * .43, y - carH * .30)
      ..lineTo(x + carW * .48, y + carH * .42)..close();
    canvas.drawPath(shape, bodyPaint);
    final glass = Path()..moveTo(x - carW * .29, y - carH * .22)
      ..quadraticBezierTo(x, y - carH * .43, x + carW * .29, y - carH * .22)
      ..lineTo(x + carW * .24, y + carH * .02)..lineTo(x - carW * .24, y + carH * .02)..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xFF101C32));
    final lights = Paint()..color = player ? Colors.white : const Color(0xFFFF334F);
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + side * carW * .29, y + carH * .30), width: carW * .15, height: carH * .10),
        Radius.circular(carW * .03)), lights);
    }
    if (player && drifting) {
      final smoke = Paint()..color = Colors.white.withOpacity(.28);
      canvas.drawCircle(Offset(x - carW * .35, y + carH * .45), carW * .17, smoke);
      canvas.drawCircle(Offset(x + carW * .35, y + carH * .45), carW * .17, smoke);
    }
  }
}
