import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'car_painter.dart';
import 'multiplayer_client.dart';
import 'sound.dart';
import 'track.dart';

export 'track.dart' show RaceEnvironment;

enum RaceState { ready, running, paused, crashed, finished }
enum MenuPage { home, garage, environments, career, modes }
enum RaceMode { solo, versusComputer, online }
enum AiDifficulty { rookie, pro, elite }

class RaceCar {
  const RaceCar({
    required this.id,
    required this.name,
    required this.price,
    required this.topSpeed,
    required this.acceleration,
    required this.handling,
    required this.color,
    this.style = 0,
  });
  final String id;
  final String name;
  final int price;
  final double topSpeed;
  final double acceleration;
  final double handling;
  final Color color;
  final int style;
  int get topKmh => (topSpeed * 320).round();
  String get zeroTo100 => (7.2 - acceleration * 4.6).toStringAsFixed(1);
}

const raceCars = <RaceCar>[
  RaceCar(id: 'street', name: 'Street R', price: 0, topSpeed: 0.78, acceleration: .72, handling: .76, color: Color(0xFF00B8E6), style: 0),
  RaceCar(id: 'blaze', name: 'Blaze GT', price: 350, topSpeed: .88, acceleration: .82, handling: .70, color: Color(0xFFE63B34), style: 1),
  RaceCar(id: 'phantom', name: 'Phantom X', price: 700, topSpeed: .96, acceleration: .90, handling: .84, color: Color(0xFF9B59FF), style: 2),
  RaceCar(id: 'volt', name: 'Volt RS', price: 1100, topSpeed: 1.0, acceleration: .96, handling: .94, color: Color(0xFFFFC21F), style: 3),
];

class TrafficCar {
  TrafficCar({required this.z, required this.x, required this.baseSpeed, required this.color, required this.style})
      : targetX = x,
        speed = baseSpeed;
  double z, x, targetX, baseSpeed, speed;
  final Color color;
  final int style;
  double prevDz = 0;
  double laneTimer = 2;
}

class RivalCar {
  RivalCar({required this.name, required this.x, required this.topSpeed, required this.color, required this.style, required this.dist})
      : targetX = x;
  final String name;
  double x, targetX;
  final double topSpeed;
  final Color color;
  final int style;
  double dist;
  double speed = 0;
  bool finished = false;
  double finishTime = 0;
  double laneTimer = 1;
}

class _Sprite {
  _Sprite(this.pct, this.x, this.color, this.style, this.kind);
  final double pct;
  final double x;
  final Color color;
  final int style;
  final int kind; // 0 traffic, 1 rival, 2 online
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.color, {this.glow = false, this.grow = 0, this.gravity = 0})
      : maxLife = life;
  double x, y, vx, vy, life, size;
  final double maxLife;
  final Color color;
  final bool glow;
  final double grow, gravity;
}

const _laneX = <double>[-.667, 0.0, .667];

class RacerGame extends FlameGame {
  static const double maxSpeed = 12000;
  static const double camHeight = 1050;
  static const double playerZ = 1050;
  static const int drawDistance = 130;
  static const double carWorldW = 480;
  static const double carLength = 300;

  final math.Random _random = math.Random();
  Track track = Track(RaceEnvironment.neonCity);
  final RaceAudio audio = RaceAudio();
  final List<TrafficCar> traffic = [];
  final List<RivalCar> rivals = [];
  final List<_Particle> _particles = [];
  final List<List<_Sprite>> _buckets = List.generate(drawDistance, (_) => <_Sprite>[]);
  final List<double> _fogTable = List.generate(drawDistance, (i) {
    final t = i / drawDistance;
    return 1 - math.exp(-t * t * 3.0);
  });
  final Paint _fill = Paint()..isAntiAlias = false;
  final Path _path = Path();

  RaceMode raceMode = RaceMode.solo;
  AiDifficulty aiDifficulty = AiDifficulty.pro;
  double onlineOpponentProgress = 0;
  double onlineOpponentLane = 0;
  String onlineOpponentName = 'Rival';
  bool onlineOpponentConnected = false;
  RaceMultiplayerClient? multiplayerClient;
  double _networkTimer = 0;
  double _oppDist = 0;
  double _oppX = 0;
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
  double bestLap = 0;

  // live race state
  double playerX = 0;
  double speed = 0;
  double nitro = 1;
  double damage = 0;
  double countdown = 0;
  double raceTime = 0;
  double lapTime = 0;
  double lastLapTime = 0;
  int lap = 1;
  int laps = 2;
  int gear = 1;
  double rpm = .3;
  bool nitroHeld = false;
  bool throttleHeld = true;
  bool brakeHeld = false;
  bool driftHeld = false;
  bool drifting = false;
  bool boosting = false;
  bool slipstream = false;
  String notice = '';
  double noticeTimer = 0;

  // results
  int lastReward = 0;
  int lastPosition = 1;
  bool lastWon = false;
  String finishReason = '';
  double lastRaceTime = 0;
  final List<String> rewardNotes = [];

  double _worldDist = 0;
  double _pos = 0;
  double _time = 0;
  double _steer = 0;
  double _slip = 0;
  double _skyX = 0;
  double _shake = 0;
  double _camDepth = 1.0;
  double _hitCool = 0;
  double _wallCool = 0;
  double _driftTime = 0;
  double _audioTimer = 0;
  double _carX = 0, _carY = 0, _carW = 60;
  bool _steerLeft = false, _steerRight = false;
  bool _keyLeft = false, _keyRight = false;
  int _lastCount = 99;

  RaceCar get selectedCar => raceCars.firstWhere((car) => car.id == selectedCarId);
  double get distance => _worldDist / 100;
  double get kmh => speed / maxSpeed * 320;
  double get _totalDist => track.length * laps;
  double get raceProgress => (_worldDist / _totalDist).clamp(0.0, 1.0).toDouble();
  int get totalCars => 1 + rivals.length + (raceMode == RaceMode.online && onlineOpponentConnected ? 1 : 0);
  int get racePosition {
    var p = 1;
    for (final r in rivals) {
      if (r.finished || r.dist > _worldDist) p++;
    }
    if (raceMode == RaceMode.online && onlineOpponentConnected && onlineOpponentProgress * _totalDist > _worldDist) p++;
    return p;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnTraffic();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('nv_coins') ?? 0;
    level = prefs.getInt('nv_level') ?? 1;
    racesWon = prefs.getInt('nv_wins') ?? 0;
    bestDistance = prefs.getInt('nv_best') ?? 0;
    bestLap = prefs.getDouble('nv_bestlap') ?? 0;
    audio.enabled = prefs.getBool('nv_sound') ?? true;
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
    await prefs.setDouble('nv_bestlap', bestLap);
    await prefs.setBool('nv_sound', audio.enabled);
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

  void chooseDifficulty(AiDifficulty value) {
    aiDifficulty = value;
    hudNotifier.value++;
  }

  void chooseRaceMode(RaceMode value) {
    raceMode = value;
    hudNotifier.value++;
  }

  void chooseEnvironment(RaceEnvironment value) {
    environment = value;
    track = Track(value);
    _spawnTraffic();
    hudNotifier.value++;
  }

  void toggleSound() {
    audio.enabled = !audio.enabled;
    if (!audio.enabled) audio.stopEngine();
    _saveProgress();
    hudNotifier.value++;
  }

  // ───────────────────────── input ─────────────────────────
  void setSteerLeft(bool v) { _steerLeft = v; }
  void setSteerRight(bool v) { _steerRight = v; }
  void setThrottle(bool value) => throttleHeld = value;
  void setBrake(bool value) => brakeHeld = value;
  void setDrift(bool value) => driftHeld = value;
  void setNitro(bool value) => nitroHeld = value;

  bool handleKey(KeyEvent e) {
    final down = e is KeyDownEvent || e is KeyRepeatEvent;
    final up = e is KeyUpEvent;
    if (!down && !up) return false;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _keyLeft = down;
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _keyRight = down;
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      brakeHeld = down;
    } else if (k == LogicalKeyboardKey.space) {
      nitroHeld = down;
    } else if (k == LogicalKeyboardKey.shiftLeft || k == LogicalKeyboardKey.shiftRight) {
      driftHeld = down;
    } else if ((k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP) && e is KeyDownEvent) {
      togglePause();
    } else {
      return false;
    }
    return true;
  }

  // ───────────────────────── race flow ─────────────────────────
  void _spawnTraffic() {
    traffic.clear();
    final count = (34 + level * 3).clamp(34, 66);
    final len = track.length;
    var tries = 0;
    const styles = [4, 4, 0, 5, 4, 0, 5];
    const colors = [
      Color(0xFFE9E9EE), Color(0xFF2F3B52), Color(0xFFB8BCC6), Color(0xFF7A1F2B),
      Color(0xFF1E6F5C), Color(0xFFE0A92B), Color(0xFF3A5FCD), Color(0xFF30343F),
    ];
    while (traffic.length < count && tries < count * 25) {
      tries++;
      final z = 6000 + _random.nextDouble() * (len - 12000);
      final x = _laneX[_random.nextInt(3)];
      if (traffic.any((c) => (c.x - x).abs() < .3 && (c.z - z).abs() < 2600)) continue;
      traffic.add(TrafficCar(
        z: z,
        x: x,
        baseSpeed: maxSpeed * (.17 + _random.nextDouble() * .15),
        color: colors[_random.nextInt(colors.length)],
        style: styles[_random.nextInt(styles.length)],
      ));
    }
  }

  void startRace() {
    laps = (2 + (level - 1) ~/ 2).clamp(2, 6);
    _spawnTraffic();
    rivals.clear();
    onlineOpponentProgress = 0;
    onlineOpponentLane = 0;
    _oppDist = 0;
    _oppX = 0;
    onlineOpponentConnected = raceMode == RaceMode.online && onlineOpponentConnected;
    if (raceMode == RaceMode.versusComputer) {
      final base = (switch (aiDifficulty) { AiDifficulty.rookie => .62, AiDifficulty.pro => .70, AiDifficulty.elite => .78 }) + math.min(level, 8) * .008;
      rivals.addAll([
        RivalCar(name: 'NOVA', x: -.667, topSpeed: maxSpeed * base * .96, color: const Color(0xFFFF9F1C), style: 1, dist: 320),
        RivalCar(name: 'VIPER', x: .667, topSpeed: maxSpeed * base, color: const Color(0xFFB66BFF), style: 2, dist: 640),
        RivalCar(name: 'GHOST', x: 0, topSpeed: maxSpeed * base * 1.03, color: const Color(0xFFFF3B5C), style: 3, dist: 960),
      ]);
      for (final r in rivals) {
        r.speed = 0;
      }
    }
    playerX = 0;
    speed = 0;
    _worldDist = 0;
    _pos = 0;
    nitro = 1;
    damage = 0;
    raceTime = 0;
    lapTime = 0;
    lastLapTime = 0;
    lap = 1;
    gear = 1;
    rpm = .3;
    _steer = 0;
    _slip = 0;
    _shake = 0;
    _hitCool = 0;
    _wallCool = 0;
    _driftTime = 0;
    _particles.clear();
    throttleHeld = true;
    brakeHeld = false;
    driftHeld = false;
    nitroHeld = false;
    drifting = false;
    boosting = false;
    slipstream = false;
    notice = '';
    noticeTimer = 0;
    lastReward = 0;
    rewardNotes.clear();
    countdown = 3.6;
    _lastCount = 99;
    state = RaceState.running;
    overlays.remove('start');
    overlays.remove('gameOver');
    overlays.remove('pause');
    resumeEngine();
    audio.startEngine();
    hudNotifier.value++;
  }

  void togglePause() {
    if (state == RaceState.running) {
      state = RaceState.paused;
      overlays.add('pause');
      audio.stopEngine();
      pauseEngine();
    } else if (state == RaceState.paused) {
      state = RaceState.running;
      overlays.remove('pause');
      audio.startEngine();
      resumeEngine();
    }
    hudNotifier.value++;
  }

  void returnToMenu() {
    state = RaceState.ready;
    overlays.remove('pause');
    overlays.remove('gameOver');
    overlays.add('start');
    audio.stopEngine();
    rivals.clear();
    countdown = 0;
    speed = 3800;
    _spawnTraffic();
    menuPage = MenuPage.home;
    resumeEngine();
    hudNotifier.value++;
  }

  void _notify(String text, [double seconds = 1.4]) {
    notice = text;
    noticeTimer = seconds;
  }

  // ───────────────────────── simulation ─────────────────────────
  double _wrap(double d) {
    final len = track.length;
    var r = d % len;
    if (r > len / 2) r -= len;
    return r;
  }

  @override
  void update(double dt) {
    super.update(dt);
    dt = math.min(dt, .05);
    _time += dt;
    _updateParticles(dt);
    if (state == RaceState.ready) {
      _attract(dt);
      return;
    }
    if (state != RaceState.running) return;
    if (_shake > 0) _shake = math.max(0.0, _shake - dt * 2.4);
    if (noticeTimer > 0) noticeTimer -= dt;
    _hitCool -= dt;
    _wallCool -= dt;
    final seg = track.segmentAt(_pos + playerZ);
    _skyX += seg.curve * cl(speed / maxSpeed, 0, 1) * dt * .045;
    _camDepth += ((1.0 - cl(speed / maxSpeed, 0, 1.3) * .10 - (boosting ? .10 : 0)) - _camDepth) * math.min(1.0, dt * 3);
    if (countdown > 0) {
      _tickCountdown(dt);
      return;
    }
    _drive(dt, seg);
  }

  void _attract(double dt) {
    speed = 3800;
    _pos = (_pos + speed * dt) % track.length;
    playerX = math.sin(_time * .35) * .35;
    _camDepth += (.96 - _camDepth) * math.min(1.0, dt * 2);
    _skyX += track.segmentAt(_pos + playerZ).curve * .25 * dt * .045 * 3;
    _updateTraffic(dt, collide: false);
  }

  void _tickCountdown(double dt) {
    final before = countdown;
    countdown -= dt;
    final c = countdown.ceil();
    if (c != _lastCount && c <= 3 && c >= 1) {
      _lastCount = c;
      audio.play('beep', volume: .8);
    }
    rpm = .45 + .3 * math.sin(_time * 9).abs();
    if (before > 0 && countdown <= 0) {
      countdown = 0;
      audio.play('go');
      _notify('GO!', 1.0);
      speed = 400;
    }
    _audioTimer -= dt;
    if (_audioTimer <= 0) {
      _audioTimer = .1;
      audio.updateEngine(.8 + rpm * .7, .4);
    }
    hudNotifier.value++;
  }

  void _drive(double dt, RoadSegment seg) {
    final car = selectedCar;
    final carMax = maxSpeed * car.topSpeed * (1 - damage * .2);
    final onGrass = playerX.abs() > 1.0;
    final canBoost = nitroHeld && nitro > .02 && speed > 600 && !brakeHeld;
    if (canBoost && !boosting) {
      audio.play('boost', volume: .8);
      HapticFeedback.mediumImpact();
    }
    boosting = canBoost;
    var cap = carMax * (boosting ? 1.3 : 1.0) * (slipstream ? 1.04 : 1.0);
    if (onGrass) cap = carMax * .45;
    final accel = carMax / (7.5 - car.acceleration * 4.2);
    if (brakeHeld) {
      speed -= maxSpeed * .62 * dt;
    } else if (throttleHeld || boosting) {
      final ratio = cl(speed / cap, 0, 1.2);
      speed += accel * (boosting ? 2.6 : 1.0) * math.max(.1, 1.12 - ratio) * dt;
    } else {
      speed -= maxSpeed * .14 * dt;
    }
    if (speed > cap) speed -= (speed - cap) * math.min(1.0, dt * (onGrass ? 4.0 : 1.6));
    speed -= (seg.y2 - seg.y1) / Track.segLength * maxSpeed * .22 * dt;
    speed = cl(speed, 0, maxSpeed * 1.5);
    if (boosting) {
      nitro = math.max(0.0, nitro - dt * .21);
    } else {
      nitro = math.min(1.0, nitro + dt * .02);
    }

    // steering
    final target = ((_steerRight || _keyRight) ? 1.0 : 0.0) - ((_steerLeft || _keyLeft) ? 1.0 : 0.0);
    _steer += (target - _steer) * math.min(1.0, dt * (target == 0 ? 10 : 7));
    final spd = cl(speed / maxSpeed, 0, 1);
    drifting = driftHeld && _steer.abs() > .25 && spd > .3;
    final grip = .65 + car.handling * .55;
    playerX += _steer * 2.8 * grip * (drifting ? 1.3 : 1.0) * spd * dt;
    playerX -= dt * 2 * spd * spd * seg.curve * (.22 * (1.25 - car.handling * .5)) * (drifting ? .45 : 1.0);
    _slip += ((drifting ? _steer * .38 : 0.0) - _slip) * math.min(1.0, dt * 6);
    if (drifting) {
      nitro = math.min(1.0, nitro + dt * .2);
      _driftTime += dt;
      speed -= maxSpeed * .03 * dt;
    }
    if (playerX.abs() > 1.3) {
      final sgn = playerX.sign;
      playerX = 1.3 * sgn;
      if (_wallCool <= 0 && speed > 1500) {
        _wallCool = .6;
        playerX -= sgn * .1;
        _impact(.03 + spd * .06, sparkSide: sgn);
        speed *= .6;
        _notify('WALL HIT', .9);
      }
    }

    // advance
    _worldDist += speed * dt;
    _pos = _worldDist % track.length;
    raceTime += dt;
    lapTime += dt;
    final newLap = math.min(laps, (_worldDist / track.length).floor() + 1);
    if (newLap > lap) {
      lastLapTime = lapTime;
      if (bestLap == 0 || lapTime < bestLap) {
        bestLap = lapTime;
        _notify('BEST LAP ${lapTime.toStringAsFixed(2)}', 2.0);
      } else {
        _notify(newLap == laps ? 'FINAL LAP' : 'LAP $newLap', 1.6);
      }
      lap = newLap;
      lapTime = 0;
      audio.play('lap');
    }

    _updateTraffic(dt, collide: true);
    _updateRivals(dt);
    _updateOnline(dt);

    // gearbox
    final f = cl(speed / (maxSpeed * car.topSpeed * 1.05), 0, 1.4);
    final gi = math.min(5, (f * 6).floor());
    gear = gi + 1;
    final target2 = (throttleHeld || boosting ? .32 : .22) + (f * 6 - gi).clamp(0.0, 1.0) * .68;
    rpm += (target2 - rpm) * math.min(1.0, dt * 14);

    _emitEffects(dt, onGrass);

    _audioTimer -= dt;
    if (_audioTimer <= 0) {
      _audioTimer = .1;
      audio.updateEngine(.75 + rpm * .85 + (boosting ? .15 : 0), .35 + spd * .35);
    }

    if (damage >= 1) {
      _finishRace(won: false, reason: 'WRECKED');
      return;
    }
    if (raceMode == RaceMode.online && onlineOpponentConnected && onlineOpponentProgress >= 1 && _worldDist < _totalDist) {
      _finishRace(won: false, reason: 'RIVAL FINISHED FIRST');
      return;
    }
    if (_worldDist >= _totalDist) {
      _finishRace(won: true, reason: 'FINISHED');
      return;
    }
    _networkTimer += dt;
    if (raceMode == RaceMode.online && _networkTimer >= .08) {
      _networkTimer = 0;
      multiplayerClient?.sendState(progress: raceProgress, lane: playerX.clamp(-1.0, 1.0).toDouble(), speed: speed / maxSpeed);
    }
    hudNotifier.value++;
  }

  void _updateTraffic(double dt, {required bool collide}) {
    final pz = (_pos + playerZ) % track.length;
    var slip = false;
    for (final c in traffic) {
      c.speed = c.baseSpeed;
      for (final o in traffic) {
        if (identical(o, c) || (o.x - c.x).abs() > .3) continue;
        final d = _wrap(o.z - c.z);
        if (d > 0 && d < 900) c.speed = math.min(c.speed, o.baseSpeed * .97);
      }
      c.z = (c.z + c.speed * dt) % track.length;
      c.laneTimer -= dt;
      if (c.laneTimer <= 0) {
        c.laneTimer = 3 + _random.nextDouble() * 6;
        _trafficLaneChange(c, pz);
      }
      c.x += (c.targetX - c.x) * math.min(1.0, dt * 1.6);
      final dz = _wrap(c.z - pz);
      if (collide) {
        final dxl = (c.x - playerX).abs();
        if (dz.abs() < carLength && dxl < .44 && _hitCool <= 0) {
          _hitCar(dz, c.x, c.speed, null, c);
        } else if (dz > 350 && dz < 1800 && dxl < .32 && speed > 5000) {
          slip = true;
        }
        if (c.prevDz > 0 && c.prevDz < 700 && dz <= 0 && dxl >= .44 && dxl < .56 && speed > 4000) {
          nitro = math.min(1.0, nitro + .08);
          _notify('NEAR MISS +NITRO', 1.0);
        }
      }
      c.prevDz = dz;
    }
    slipstream = slip;
    if (slip) {
      nitro = math.min(1.0, nitro + dt * .1);
      if (noticeTimer <= 0) _notify('SLIPSTREAM', .4);
    }
  }

  void _trafficLaneChange(TrafficCar c, double pz) {
    var idx = 0;
    for (var i = 1; i < 3; i++) {
      if ((c.x - _laneX[i]).abs() < (c.x - _laneX[idx]).abs()) idx = i;
    }
    final opts = <int>[if (idx > 0) idx - 1, if (idx < 2) idx + 1];
    final ni = opts[_random.nextInt(opts.length)];
    final tx = _laneX[ni];
    for (final o in traffic) {
      if (identical(o, c)) continue;
      if ((o.x - tx).abs() < .4 && _wrap(o.z - c.z).abs() < 1500) return;
    }
    if (_wrap(c.z - pz).abs() < 1400 && (tx - playerX).abs() < .6) return;
    c.targetX = tx;
  }

  void _updateRivals(double dt) {
    final pz = (_pos + playerZ) % track.length;
    for (final r in rivals) {
      final rz = (r.dist + playerZ) % track.length;
      var target = r.topSpeed * (1 - track.segmentAt(rz).curve.abs() * .012);
      final gap = r.dist - _worldDist;
      if (gap > 9000) target *= .94;
      if (gap < -6000) target *= 1.05;
      var blocked = false;
      for (final t in traffic) {
        final d = _wrap(t.z - rz);
        if (d > 0 && d < 2600 && (t.x - r.x).abs() < .5) {
          blocked = true;
          target = math.min(target, t.speed * 1.05 + 400);
        }
      }
      r.laneTimer -= dt;
      if (blocked || r.laneTimer <= 0) {
        r.laneTimer = blocked ? .8 : 4 + _random.nextDouble() * 4;
        final curve = track.segmentAt(rz).curve;
        var bestLane = r.targetX;
        var bestFree = -1.0;
        for (final lx in _laneX) {
          var free = 6000.0;
          for (final t in traffic) {
            final d = _wrap(t.z - rz);
            if (d > -300 && (t.x - lx).abs() < .4) free = math.min(free, d.abs());
          }
          for (final o in rivals) {
            if (identical(o, r)) continue;
            final d = _wrap((o.dist + playerZ) % track.length - rz);
            if (d.abs() < 700 && (o.x - lx).abs() < .4) free = math.min(free, d.abs());
          }
          if (!blocked && curve.abs() > 1.5 && lx.sign == curve.sign && lx != 0) free += 400;
          if (free > bestFree) {
            bestFree = free;
            bestLane = lx;
          }
        }
        r.targetX = bestLane;
      }
      r.speed += (target - r.speed) * math.min(1.0, dt * .8);
      r.dist += r.speed * dt;
      r.x += (r.targetX - r.x) * math.min(1.0, dt * 2.2);
      if (!r.finished && r.dist >= _totalDist) {
        r.finished = true;
        r.finishTime = raceTime;
      }
      final dz = _wrap(rz - pz);
      if (dz.abs() < carLength && (r.x - playerX).abs() < .44 && _hitCool <= 0) {
        _hitCar(dz, r.x, r.speed, r, null);
      }
    }
  }

  void _updateOnline(double dt) {
    if (raceMode != RaceMode.online || !onlineOpponentConnected) return;
    final target = onlineOpponentProgress * _totalDist;
    _oppDist += (target - _oppDist) * math.min(1.0, dt * 8);
    _oppX += (onlineOpponentLane - _oppX) * math.min(1.0, dt * 8);
  }

  void _hitCar(double dz, double ox, double ospeed, RivalCar? rival, TrafficCar? tc) {
    _hitCool = .8;
    final rel = math.max(0.0, speed - ospeed);
    final dir = (playerX - ox) >= 0 ? 1.0 : -1.0;
    if (dz > 0) {
      speed = math.max(ospeed * .85, speed * .45);
    } else {
      speed *= .92;
    }
    playerX += dir * .16;
    if (tc != null) tc.targetX = (tc.x - dir * .3).clamp(-.9, .9).toDouble();
    if (rival != null) {
      rival.x -= dir * .12;
      rival.speed *= .9;
    }
    _impact(.03 + rel / maxSpeed * .30, sparkSide: dir);
  }

  void _impact(double severity, {double sparkSide = 0}) {
    damage = math.min(1.0, damage + severity);
    _shake = math.max(_shake, math.min(1.0, .45 + severity * 4));
    audio.play('crash', volume: .9);
    HapticFeedback.heavyImpact();
    for (var i = 0; i < 16; i++) {
      final a = _random.nextDouble() * math.pi * 2;
      final v = 80 + _random.nextDouble() * 260;
      _particles.add(_Particle(_carX + sparkSide * _carW * .45, _carY - _carW * .25, math.cos(a) * v, math.sin(a) * v - 120,
          .35 + _random.nextDouble() * .3, 2 + _random.nextDouble() * 2.5, const Color(0xFFFFD27A), glow: true, gravity: 520));
    }
  }

  void _emitEffects(double dt, bool onGrass) {
    final spd = speed / maxSpeed;
    if ((drifting || (brakeHeld && spd > .4)) && _random.nextDouble() < .7) {
      for (final s in [-1.0, 1.0]) {
        _particles.add(_Particle(_carX + s * _carW * .38, _carY - 3, (_random.nextDouble() - .5) * 30, -20 - _random.nextDouble() * 30,
            .6 + _random.nextDouble() * .4, _carW * .09, const Color(0xFFE9ECF5), grow: _carW * .25));
      }
    }
    if (onGrass && spd > .1) {
      final c = themeOf(environment).grassA;
      for (final s in [-1.0, 1.0]) {
        _particles.add(_Particle(_carX + s * _carW * .38, _carY - 2, (_random.nextDouble() - .5) * 60, -30 - _random.nextDouble() * 60,
            .5 + _random.nextDouble() * .4, _carW * .08, shade(c, 1.2), grow: _carW * .2));
      }
    }
    if (boosting && _random.nextDouble() < .6) {
      _particles.add(_Particle(_carX + (_random.nextBool() ? -1 : 1) * _carW * .28, _carY - _carW * .08, (_random.nextDouble() - .5) * 40,
          140 + _random.nextDouble() * 120, .3, 2.5, const Color(0xFF7FD6FF), glow: true));
    }
    if (damage > .55 && _random.nextDouble() < damage * .5) {
      _particles.add(_Particle(_carX + (_random.nextDouble() - .5) * _carW * .5, _carY - _carW * .5, (_random.nextDouble() - .5) * 20, -50,
          .9, _carW * .08, const Color(0xFF444850), grow: _carW * .2));
    }
  }

  void _updateParticles(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += p.gravity * dt;
      p.life -= dt;
      p.size += p.grow * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
    if (_particles.length > 220) _particles.removeRange(0, _particles.length - 220);
  }

  @override
  void onRemove() {
    hudNotifier.dispose();
    multiplayerClient?.close();
    audio.dispose();
    super.onRemove();
  }

  void _finishRace({required bool won, required String reason}) {
    if (state != RaceState.running) return;
    finishReason = reason;
    lastRaceTime = raceTime;
    boosting = false;
    final pos = racePosition;
    lastPosition = pos;
    rewardNotes.clear();
    if (won) {
      state = RaceState.finished;
      lastWon = raceMode == RaceMode.solo || pos == 1;
      final base = 60 + level * 25;
      final mult = raceMode == RaceMode.solo ? 1.0 : switch (pos) { 1 => 1.0, 2 => .55, 3 => .3, _ => .15 };
      var reward = (base * mult).round();
      rewardNotes.add(raceMode == RaceMode.solo ? 'Race complete  +$reward' : 'Position $pos  +$reward');
      if (_driftTime > 3) {
        reward += 25;
        rewardNotes.add('Drift master  +25');
      }
      if (damage < .1) {
        reward += 40;
        rewardNotes.add('Clean race  +40');
      }
      lastReward = reward;
      if (lastWon) {
        racesWon++;
        level++;
      }
    } else {
      state = RaceState.crashed;
      lastWon = false;
      lastReward = (_worldDist / 3000).floor();
      rewardNotes.add('Distance covered  +$lastReward');
    }
    coins += lastReward;
    bestDistance = math.max(bestDistance, distance.round());
    if (raceMode == RaceMode.online && won) multiplayerClient?.sendFinish();
    _saveProgress();
    audio.stopEngine();
    overlays.add('gameOver');
    pauseEngine();
    hudNotifier.value++;
  }

  // ───────────────────────── rendering ─────────────────────────
  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;
    final theme = themeOf(environment);
    final horizon = h * .36;
    canvas.save();
    if (_shake > 0) {
      canvas.translate((_random.nextDouble() - .5) * _shake * 14, (_random.nextDouble() - .5) * _shake * 10);
    }
    _drawSky(canvas, w, horizon, theme);
    _drawWorld(canvas, w, h, horizon, theme);
    _drawEffects(canvas, w, h, horizon, theme);
    canvas.restore();
  }

  void _drawSky(Canvas canvas, double w, double horizon, EnvTheme t) {
    final rect = Rect.fromLTWH(0, 0, w, horizon + 2);
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.skyTop, t.skyMid, t.horizon], stops: const [0, .55, 1]).createShader(rect),
    );
    final off = _skyX * w;
    if (environment == RaceEnvironment.midnight || environment == RaceEnvironment.neonCity) {
      for (var i = 0; i < 60; i++) {
        final x = ((i * 137.5) - off * .1) % w;
        final y = (i * 53.3) % (horizon * .75);
        final a = .35 + .35 * math.sin(_time * 2 + i);
        canvas.drawCircle(Offset(x < 0 ? x + w : x, y), i % 7 == 0 ? 1.4 : .8, Paint()..color = Colors.white.withAlpha((a * 255).round()));
      }
    }
    switch (environment) {
      case RaceEnvironment.neonCity: {
        final c = Offset(w * .5, horizon - w * .02);
        final r = w * .24;
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
        final sunRect = Rect.fromCircle(center: c, radius: r);
        canvas.drawRect(sunRect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45E), Color(0xFFFF3E9A)]).createShader(sunRect));
        for (var i = 0; i < 6; i++) {
          final y = c.dy + i * r * .17;
          canvas.drawRect(Rect.fromLTWH(c.dx - r, y, r * 2, 1.5 + i * 1.6), Paint()..color = t.skyMid);
        }
        canvas.restore();
        _skyline(canvas, w, horizon, off * .3, const Color(0xFF1A1D4C), .10, .16);
        _skyline(canvas, w, horizon, off * .6, const Color(0xFF0E1230), .06, .13);
      }
      case RaceEnvironment.desert: {
        final c = Offset(w * .72, horizon * .62);
        canvas.drawCircle(c, w * .2, Paint()..shader = RadialGradient(colors: [const Color(0x88FFE2A0), const Color(0x00FFE2A0)]).createShader(Rect.fromCircle(center: c, radius: w * .2)));
        canvas.drawCircle(c, w * .065, Paint()..color = const Color(0xFFFFF0C2));
        _ridge(canvas, w, horizon, off * .3, horizon * .10, horizon * .06, 3, const Color(0xFFC7705A));
        _ridge(canvas, w, horizon, off * .6, horizon * .05, horizon * .05, 8, const Color(0xFFA9573E));
        _clouds(canvas, w, horizon, off, .35);
      }
      case RaceEnvironment.countryside: {
        canvas.drawCircle(Offset(w * .78, horizon * .35), w * .05, Paint()..color = const Color(0xFFFFF6D0));
        _clouds(canvas, w, horizon, off, .8);
        _ridge(canvas, w, horizon, off * .3, horizon * .12, horizon * .07, 4, const Color(0xFF86B8CB));
        _ridge(canvas, w, horizon, off * .6, horizon * .05, horizon * .06, 9, const Color(0xFF4E9B63));
      }
      case RaceEnvironment.midnight: {
        final c = Offset(w * .26, horizon * .38);
        canvas.drawCircle(c, w * .16, Paint()..shader = RadialGradient(colors: [const Color(0x55C9C3FF), const Color(0x00C9C3FF)]).createShader(Rect.fromCircle(center: c, radius: w * .16)));
        canvas.drawCircle(c, w * .055, Paint()..color = const Color(0xFFEDEBFF));
        canvas.drawCircle(c.translate(-w * .015, w * .01), w * .012, Paint()..color = const Color(0x22000000));
        _ridge(canvas, w, horizon, off * .3, horizon * .10, horizon * .08, 5, const Color(0xFF15133F));
        _ridge(canvas, w, horizon, off * .6, horizon * .04, horizon * .05, 11, const Color(0xFF0A0A1E));
      }
    }
  }

  void _clouds(Canvas canvas, double w, double horizon, double off, double a) {
    final p = Paint()..color = Colors.white.withAlpha((a * 150).round());
    for (var i = 0; i < 5; i++) {
      final x = ((i * w * .27) - off * .2 + _time * 4) % (w + 160) - 80;
      final y = horizon * (.18 + (i % 3) * .14);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 90 + (i % 2) * 40, height: 20), p);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 22, y - 8), width: 56, height: 20), p);
    }
  }

  void _ridge(Canvas canvas, double w, double horizon, double offset, double baseH, double amp, int seed, Color color) {
    final path = Path()..moveTo(-10, horizon + 2);
    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final x = -10 + (w + 20) * i / steps;
      final u = (x + offset) / w * 2 * math.pi;
      final hg = baseH + amp * (math.sin(u * 2 + seed) * .5 + math.sin(u * 5 + seed * 1.7) * .3 + math.sin(u * 11 + seed * 2.3) * .2);
      path.lineTo(x, horizon - hg);
    }
    path
      ..lineTo(w + 10, horizon + 2)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _skyline(Canvas canvas, double w, double horizon, double offset, Color color, double minH, double varH) {
    final bw = w / 9;
    final first = (offset / bw).floor();
    final p = Paint()..color = color;
    final win = Paint()..color = const Color(0x66FFE08A);
    for (var k = -1; k < 12; k++) {
      final bi = first + k;
      final hash = ((bi % 20) * 37 % 11) / 11;
      final x = bi * bw - offset;
      final bh = horizon * (minH + varH * hash);
      canvas.drawRect(Rect.fromLTWH(x, horizon - bh, bw - 3, bh + 2), p);
      for (var j = 0; j < 4; j++) {
        if ((bi + j) % 3 == 0) continue;
        canvas.drawRect(Rect.fromLTWH(x + 5 + (j % 2) * bw * .4, horizon - bh + 6 + j * 9, 3, 4), win);
      }
    }
  }

  Color _fg(Color c, double fog, EnvTheme t) => fog < .02 ? c : Color.lerp(c, t.fog, fog)!;

  void _quad(Canvas canvas, Color color, double x1, double y1, double w1, double x2, double y2, double w2) {
    _path
      ..reset()
      ..moveTo(x1 - w1, y1)
      ..lineTo(x2 - w2, y2)
      ..lineTo(x2 + w2, y2)
      ..lineTo(x1 + w1, y1)
      ..close();
    canvas.drawPath(_path, _fill..color = color);
  }

  void _drawWorld(Canvas canvas, double w, double h, double horizon, EnvTheme t) {
    final segs = track.segments;
    final n = segs.length;
    final baseIdx = (_pos / Track.segLength).floor() % n;
    final basePercent = (_pos % Track.segLength) / Track.segLength;
    final base = segs[baseIdx];
    final pzAbs = _pos + playerZ;
    final pSeg = track.segmentAt(pzAbs);
    final pPct = (pzAbs % Track.segLength) / Track.segLength;
    final camY = camHeight + _lerp(pSeg.y1, pSeg.y2, pPct);
    final camX = playerX * Track.roadWidth;
    final halfW = w / 2;
    final k = h * .42;
    var x = 0.0;
    var dx = -(base.curve * basePercent);
    var maxY = h;

    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), Paint()..color = t.fog);
    canvas.drawRect(Rect.fromLTWH(0, horizon + 4, w, h), Paint()..color = _fg(t.grassA, .6, t));

    final wallCol = t.wall;
    for (var i = 0; i < drawDistance; i++) {
      final idx = baseIdx + i;
      final s = segs[idx % n];
      final z1 = idx * Track.segLength - _pos;
      final z2 = z1 + Track.segLength;
      final ok = z1 > _camDepth;
      if (ok) {
        s.sc1 = _camDepth / z1;
        s.sc2 = _camDepth / z2;
        s.sx1 = halfW + s.sc1 * (x - camX) * halfW;
        s.sx2 = halfW + s.sc2 * (x + dx - camX) * halfW;
        s.sy1 = horizon - s.sc1 * (s.y1 - camY) * k;
        s.sy2 = horizon - s.sc2 * (s.y2 - camY) * k;
        s.sw1 = s.sc1 * Track.roadWidth * halfW;
        s.sw2 = s.sc2 * Track.roadWidth * halfW;
      } else {
        s.sc1 = 0;
        s.sc2 = 0;
      }
      x += dx;
      dx += s.curve;
      s.clip = maxY;
      if (!ok || s.sy2 >= s.sy1 || s.sy2 >= maxY) continue;

      final fog = _fogTable[i];
      final dark = s.dark;
      canvas.drawRect(Rect.fromLTRB(0, s.sy2, w, s.sy1 + 1), _fill..color = _fg(dark ? t.grassB : t.grassA, fog, t));
      final rw1 = s.sw1 / 6, rw2 = s.sw2 / 6;
      final rc = _fg(dark ? t.rumbleB : t.rumbleA, fog, t);
      _quad(canvas, rc, s.sx1 - s.sw1 - rw1 / 2, s.sy1, rw1 / 2, s.sx2 - s.sw2 - rw2 / 2, s.sy2, rw2 / 2);
      _quad(canvas, rc, s.sx1 + s.sw1 + rw1 / 2, s.sy1, rw1 / 2, s.sx2 + s.sw2 + rw2 / 2, s.sy2, rw2 / 2);
      _quad(canvas, _fg(dark ? t.roadB : t.roadA, fog, t), s.sx1, s.sy1, s.sw1, s.sx2, s.sy2, s.sw2);
      if (s.startLine) {
        for (var c = 0; c < 8; c++) {
          if ((c + s.index) % 2 == 0) continue;
          final a1 = -1 + c * .25, a2 = a1 + .25;
          _path
            ..reset()
            ..moveTo(s.sx1 + s.sw1 * a1, s.sy1)
            ..lineTo(s.sx2 + s.sw2 * a1, s.sy2)
            ..lineTo(s.sx2 + s.sw2 * a2, s.sy2)
            ..lineTo(s.sx1 + s.sw1 * a2, s.sy1)
            ..close();
          canvas.drawPath(_path, _fill..color = _fg(Colors.white, fog, t));
        }
      } else if (!dark) {
        final lc = _fg(t.lane, fog, t);
        for (final lx in const [-.333, .333]) {
          _quad(canvas, lc, s.sx1 + s.sw1 * lx, s.sy1, s.sw1 * .018, s.sx2 + s.sw2 * lx, s.sy2, s.sw2 * .018);
        }
      }
      // barriers
      final wh1 = s.sc1 * 190 * k, wh2 = s.sc2 * 190 * k;
      final wc = _fg(dark ? shade(wallCol, .8) : wallCol, fog, t);
      for (final sd in const [-1.0, 1.0]) {
        _path
          ..reset()
          ..moveTo(s.sx1 + s.sw1 * 1.3 * sd, s.sy1)
          ..lineTo(s.sx2 + s.sw2 * 1.3 * sd, s.sy2)
          ..lineTo(s.sx2 + s.sw2 * 1.3 * sd, s.sy2 - wh2)
          ..lineTo(s.sx1 + s.sw1 * 1.3 * sd, s.sy1 - wh1)
          ..close();
        canvas.drawPath(_path, _fill..color = wc);
      }
      maxY = s.sy1;
    }

    // night headlight pool on the road
    final lightSeg = segs[(baseIdx + 24) % n];
    if (t.night && lightSeg.sc1 > 0) {
      final cone = Path()
        ..moveTo(halfW - w * .09, h * .74)
        ..lineTo(halfW + w * .09, h * .74)
        ..lineTo(lightSeg.sx1 + lightSeg.sw1 * .55, lightSeg.sy1)
        ..lineTo(lightSeg.sx1 - lightSeg.sw1 * .55, lightSeg.sy1)
        ..close();
      final cr = Rect.fromLTRB(0, lightSeg.sy1, w, h * .74);
      canvas.drawPath(cone, Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [const Color(0x30FFF2C2), const Color(0x00FFF2C2)]).createShader(cr));
    }

    _buildBuckets(baseIdx, n);
    for (var i = drawDistance - 1; i >= 0; i--) {
      final s = segs[(baseIdx + i) % n];
      if (s.sc1 <= 0) continue;
      final fog = _fogTable[i];
      final clip = s.clip;
      if (s.gantry) _drawGantry(canvas, s, k, fog, t);
      if (s.propL != Prop.none) _drawSideProp(canvas, s, -1, w, k, fog, t, clip, halfW);
      if (s.propR != Prop.none) _drawSideProp(canvas, s, 1, w, k, fog, t, clip, halfW);
      for (final sp in _buckets[i]) {
        final sc = _lerp(s.sc1, s.sc2, sp.pct);
        final sx = _lerp(s.sx1, s.sx2, sp.pct);
        final sy = _lerp(s.sy1, s.sy2, sp.pct);
        if (sc <= 0) continue;
        final cx = sx + sc * sp.x * Track.roadWidth * halfW;
        final cw = sc * carWorldW * (sp.style == 5 ? 1.1 : 1.0) * halfW;
        if (cx + cw < 0 || cx - cw > w) continue;
        final clipped = sy > clip;
        if (clipped) {
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, 0, w, clip));
        }
        drawCar(canvas, Offset(cx, sy), cw, color: sp.color, style: sp.style, braking: false, fog: fog, fogColor: t.fog);
        if (sp.kind == 1 && cw > 10) {
          final m = Path()
            ..moveTo(cx, sy - cw * carHeightRatio(sp.style) - cw * .55)
            ..lineTo(cx - cw * .2, sy - cw * carHeightRatio(sp.style) - cw * .85)
            ..lineTo(cx + cw * .2, sy - cw * carHeightRatio(sp.style) - cw * .85)
            ..close();
          canvas.drawPath(m, Paint()..color = sp.color);
        }
        if (clipped) canvas.restore();
      }
    }

    // player car
    final psc = _lerp(pSeg.sc1, pSeg.sc2, pPct);
    var carW = psc > 0 ? psc * carWorldW * halfW : w * .24;
    var carY = psc > 0 ? _lerp(pSeg.sy1, pSeg.sy2, pPct) : h * .78;
    final onGrass = playerX.abs() > 1.0;
    carY += math.sin(_time * 22) * cl(speed / maxSpeed, 0, 1) * (onGrass ? 3.5 : .8);
    carW = carW.clamp(20.0, w * .5).toDouble();
    final carX = halfW + _slip * carW * .35;
    _carX = carX;
    _carY = carY;
    _carW = carW;
    for (final p in _particles) {
      if (p.glow) continue;
      final a = cl(p.life / p.maxLife, 0, 1);
      canvas.drawCircle(Offset(p.x, p.y), p.size, Paint()..color = p.color.withAlpha((a * a * 110).round()));
    }
    drawCar(
      canvas,
      Offset(carX, carY),
      carW,
      color: selectedCar.color,
      style: selectedCar.style,
      braking: brakeHeld || (!throttleHeld && speed > 100),
      boost: boosting ? 1.0 : 0.0,
      tilt: _steer * .035 + _slip * .35,
      underglow: t.night,
      glow: selectedCar.color,
    );
    for (final p in _particles) {
      if (!p.glow) continue;
      final a = cl(p.life / p.maxLife, 0, 1);
      canvas.drawCircle(Offset(p.x, p.y), p.size * (.5 + a), Paint()..color = p.color.withAlpha((a * 255).round()));
    }
    // rivals ahead markers handled in sprites
  }

  void _buildBuckets(int baseIdx, int n) {
    for (final b in _buckets) {
      b.clear();
    }
    final len = track.length;
    void add(double z, double x, Color color, int style, int kind) {
      final si = (z / Track.segLength).floor() % n;
      final i = ((si - baseIdx) % n + n) % n;
      if (i >= drawDistance) return;
      _buckets[i].add(_Sprite((z % Track.segLength) / Track.segLength, x, color, style, kind));
    }

    for (final c in traffic) {
      add(c.z, c.x, c.color, c.style, 0);
    }
    for (final r in rivals) {
      add((r.dist + playerZ) % len, r.x, r.color, r.style, 1);
    }
    if (raceMode == RaceMode.online && onlineOpponentConnected && state != RaceState.ready) {
      add((_oppDist + playerZ) % len, _oppX, const Color(0xFFFFB547), 2, 2);
    }
  }

  void _drawSideProp(Canvas canvas, RoadSegment s, int side, double w, double k, double fog, EnvTheme t, double clip, double halfW) {
    final kind = side < 0 ? s.propL : s.propR;
    final off = side < 0 ? s.offL : s.offR;
    final v = side < 0 ? s.varL : s.varR;
    final worldW = switch (kind) {
      Prop.building => 1100 + v * 900,
      Prop.lamp => 260.0,
      Prop.tree => 520 + v * 300,
      Prop.rock => 420 + v * 300,
      _ => 900.0,
    };
    final cx = s.sx1 + s.sc1 * side * off * Track.roadWidth * halfW;
    final pw = s.sc1 * worldW * halfW;
    if (cx + pw < 0 || cx - pw > w) return;
    final clipped = s.sy1 > clip;
    if (clipped) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, w, clip));
    }
    drawProp(canvas, kind, environment, t, cx, s.sy1, pw, v, side, fog, _time);
    if (clipped) canvas.restore();
  }

  void _drawGantry(Canvas canvas, RoadSegment s, double k, double fog, EnvTheme t) {
    final leftX = s.sx1 - s.sw1 * 1.12;
    final rightX = s.sx1 + s.sw1 * 1.12;
    final ph = s.sc1 * 1700 * k;
    final pw = math.max(2.0, s.sw1 * .07);
    final post = Paint()..color = _fg(const Color(0xFF2B303D), fog, t);
    canvas.drawRect(Rect.fromLTWH(leftX - pw / 2, s.sy1 - ph, pw, ph), post);
    canvas.drawRect(Rect.fromLTWH(rightX - pw / 2, s.sy1 - ph, pw, ph), post);
    final bh = s.sc1 * 380 * k;
    final banner = Rect.fromLTRB(leftX - pw / 2, s.sy1 - ph - bh * .2, rightX + pw / 2, s.sy1 - ph + bh * .8);
    canvas.drawRect(banner, Paint()..color = _fg(const Color(0xFF0C0F1A), fog, t));
    final cells = 24;
    final cw = banner.width / cells;
    for (var c = 0; c < cells; c++) {
      for (var r = 0; r < 2; r++) {
        if ((c + r) % 2 == 0) continue;
        canvas.drawRect(Rect.fromLTWH(banner.left + c * cw, banner.top + r * banner.height / 2, cw, banner.height / 2), Paint()..color = _fg(Colors.white, fog, t));
      }
    }
    canvas.drawRect(Rect.fromLTWH(banner.left, banner.bottom, banner.width, math.max(1.5, bh * .08)), Paint()..color = _fg(t.accent, fog, t));
  }

  void _drawEffects(Canvas canvas, double w, double h, double horizon, EnvTheme t) {
    final spd = speed / maxSpeed;
    final intensity = cl((spd - .55) * 2.2, 0, 1) + (boosting ? .5 : 0);
    if (intensity > .02 && state != RaceState.ready) {
      final cx = w / 2, cy = horizon + (h - horizon) * .22;
      final p = Paint()..strokeCap = StrokeCap.round;
      final col = boosting ? const Color(0xFF8FE3FF) : Colors.white;
      for (var i = 0; i < 28; i++) {
        final a = (i * 2.399963) % (2 * math.pi);
        final tt = (i * .137 + _time * (1.6 + (i % 5) * .25)) % 1.0;
        final r1 = w * .28 + tt * tt * math.max(w, h) * .8;
        final r2 = r1 + 14 + tt * 90 * intensity;
        p.color = col.withAlpha((tt * 120 * cl(intensity, 0, 1)).round());
        p.strokeWidth = 1 + tt * 2;
        canvas.drawLine(Offset(cx + math.cos(a) * r1, cy + math.sin(a) * r1 * 1.25), Offset(cx + math.cos(a) * r2, cy + math.sin(a) * r2 * 1.25), p);
      }
    }
    final vig = cl(spd * .5 + (boosting ? .3 : 0) + damage * .25, 0, .8);
    final rect = Rect.fromLTWH(0, 0, w, h);
    final tint = boosting ? const Color(0xFF0A3A66) : (damage > .6 ? const Color(0xFF4A0A10) : const Color(0xFF000000));
    canvas.drawRect(rect, Paint()..shader = RadialGradient(radius: .95, colors: [const Color(0x00000000), alpha(tint, vig)], stops: const [.55, 1]).createShader(rect));
  }
}
