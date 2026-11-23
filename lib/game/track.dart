import 'dart:math' as math;
import 'dart:ui';

enum RaceEnvironment { neonCity, desert, countryside, midnight }

class EnvTheme {
  const EnvTheme({
    required this.skyTop,
    required this.skyMid,
    required this.horizon,
    required this.fog,
    required this.grassA,
    required this.grassB,
    required this.roadA,
    required this.roadB,
    required this.rumbleA,
    required this.rumbleB,
    required this.lane,
    required this.accent,
    required this.wall,
    required this.night,
  });
  final Color skyTop, skyMid, horizon, fog, grassA, grassB, roadA, roadB;
  final Color rumbleA, rumbleB, lane, accent, wall;
  final bool night;
}

const _neonTheme = EnvTheme(
  skyTop: Color(0xFF05071A), skyMid: Color(0xFF241466), horizon: Color(0xFFB0307F),
  fog: Color(0xFF3A1B6B), grassA: Color(0xFF0E1530), grassB: Color(0xFF111A38),
  roadA: Color(0xFF2C3042), roadB: Color(0xFF262A3A),
  rumbleA: Color(0xFFFF2E93), rumbleB: Color(0xFF00E5FF),
  lane: Color(0xFFE8F0FF), accent: Color(0xFF00E5FF), wall: Color(0xFF8C93AD), night: true,
);
const _desertTheme = EnvTheme(
  skyTop: Color(0xFF3B2A5E), skyMid: Color(0xFFD8736A), horizon: Color(0xFFFFC27A),
  fog: Color(0xFFF2B27A), grassA: Color(0xFFD9A25E), grassB: Color(0xFFCF9855),
  roadA: Color(0xFF4A4550), roadB: Color(0xFF45404B),
  rumbleA: Color(0xFFE8E0D0), rumbleB: Color(0xFFC0392B),
  lane: Color(0xFFFFF4D6), accent: Color(0xFFFFC06B), wall: Color(0xFFB9B2A6), night: false,
);
const _countryTheme = EnvTheme(
  skyTop: Color(0xFF3F8FD6), skyMid: Color(0xFF8CC8F0), horizon: Color(0xFFDDF3FF),
  fog: Color(0xFFCFE8F5), grassA: Color(0xFF4FA64B), grassB: Color(0xFF489A44),
  roadA: Color(0xFF5A5E66), roadB: Color(0xFF555960),
  rumbleA: Color(0xFFF2F2F2), rumbleB: Color(0xFFD93A32),
  lane: Color(0xFFFFFFFF), accent: Color(0xFF9BEB91), wall: Color(0xFFC4C8CE), night: false,
);
const _midnightTheme = EnvTheme(
  skyTop: Color(0xFF010208), skyMid: Color(0xFF0B0A26), horizon: Color(0xFF2E2063),
  fog: Color(0xFF140F33), grassA: Color(0xFF07090F), grassB: Color(0xFF0A0D16),
  roadA: Color(0xFF1F2332), roadB: Color(0xFF1A1E2B),
  rumbleA: Color(0xFF9D83FF), rumbleB: Color(0xFF2B2250),
  lane: Color(0xFFCFC3FF), accent: Color(0xFF9D83FF), wall: Color(0xFF5B5A7A), night: true,
);

EnvTheme themeOf(RaceEnvironment env) => switch (env) {
      RaceEnvironment.neonCity => _neonTheme,
      RaceEnvironment.desert => _desertTheme,
      RaceEnvironment.countryside => _countryTheme,
      RaceEnvironment.midnight => _midnightTheme,
    };

/// Prop kinds placed beside the road.
class Prop {
  static const none = 0, building = 1, lamp = 2, tree = 3, rock = 4, billboard = 5;
}

class RoadSegment {
  RoadSegment(this.index);
  final int index;
  double curve = 0;
  double y1 = 0, y2 = 0;
  bool dark = false;
  bool startLine = false;
  bool gantry = false;
  int propL = Prop.none, propR = Prop.none;
  double offL = 1.5, offR = 1.5, varL = 0, varR = 0;
  // per-frame projection scratch
  double sx1 = 0, sy1 = 0, sw1 = 0, sc1 = 0;
  double sx2 = 0, sy2 = 0, sw2 = 0, sc2 = 0;
  double clip = 0;
}

class Track {
  Track(this.env) {
    _build();
  }

  static const double segLength = 200;
  static const double roadWidth = 1100;

  final RaceEnvironment env;
  final List<RoadSegment> segments = [];

  int get count => segments.length;
  double get length => segments.length * segLength;

  RoadSegment segmentAt(double z) => segments[(z / segLength).floor() % segments.length];

  double _lastY() => segments.isEmpty ? 0 : segments.last.y2;
  static double _easeIn(double a, double b, double p) => a + (b - a) * p * p;
  static double _easeInOut(double a, double b, double p) => a + (b - a) * ((-math.cos(p * math.pi) / 2) + .5);

  void _add(double curve, double y2) {
    final n = segments.length;
    segments.add(RoadSegment(n)
      ..curve = curve
      ..y1 = _lastY()
      ..y2 = y2
      ..dark = (n ~/ 3).isEven);
  }

  void _road(int enter, int hold, int leave, double curve, double hill) {
    final startY = _lastY();
    final endY = startY + hill * segLength;
    final total = enter + hold + leave;
    for (var i = 0; i < enter; i++) {
      _add(_easeIn(0, curve, i / enter), _easeInOut(startY, endY, (i + 1) / total));
    }
    for (var i = 0; i < hold; i++) {
      _add(curve, _easeInOut(startY, endY, (enter + i + 1) / total));
    }
    for (var i = 0; i < leave; i++) {
      _add(_easeInOut(curve, 0, i / leave), _easeInOut(startY, endY, (enter + hold + i + 1) / total));
    }
  }

  // enter, hold, leave, curve, hill
  List<List<double>> get _patterns => switch (env) {
        RaceEnvironment.neonCity => const [
            [25, 50, 25, 0, 0], [30, 40, 30, 2, 0], [30, 40, 30, -2, 0], [25, 25, 25, 3, 6],
            [25, 25, 25, -3, -4], [40, 50, 40, 0, 10], [40, 50, 40, 0, -10], [35, 30, 35, 4, 0], [35, 30, 35, -4, 0],
          ],
        RaceEnvironment.desert => const [
            [40, 60, 40, 2, 20], [40, 60, 40, -2, -20], [30, 40, 30, 3, 15], [30, 40, 30, -3, -15],
            [50, 80, 50, 0, 30], [50, 80, 50, 0, -30], [25, 25, 25, 4, 0], [25, 25, 25, -4, 0],
          ],
        RaceEnvironment.countryside => const [
            [30, 40, 30, 3, 25], [30, 40, 30, -3, -25], [40, 40, 40, 2, 18], [40, 40, 40, -2, -18],
            [20, 20, 20, 5, 10], [20, 20, 20, -5, -10], [30, 60, 30, 0, 0], [35, 35, 35, 4, 12],
          ],
        RaceEnvironment.midnight => const [
            [20, 30, 20, 5, 0], [20, 30, 20, -5, 0], [15, 20, 15, 6, 4], [15, 20, 15, -6, -4],
            [30, 40, 30, 3, 12], [30, 40, 30, -3, -12], [25, 30, 25, 0, 0], [20, 25, 20, 4, -6],
          ],
      };

  void _build() {
    final rng = math.Random(env.index * 77 + 5);
    _road(25, 25, 25, 0, 0);
    final patterns = _patterns;
    while (segments.length < 1050) {
      final p = patterns[rng.nextInt(patterns.length)];
      var hill = p[4];
      final y = _lastY();
      if ((y > 5000 && hill > 0) || (y < -5000 && hill < 0)) hill = -hill;
      _road(p[0].toInt(), p[1].toInt(), p[2].toInt(), p[3], hill);
    }
    _road(40, 40, 40, 0, -_lastY() / segLength);
    _road(20, 40, 20, 0, 0);
    segments[4].startLine = true;
    segments[5].startLine = true;
    segments[5].gantry = true;
    _scenery(rng);
  }

  void _scenery(math.Random r) {
    for (final s in segments) {
      final i = s.index;
      if (i < 9) continue;
      switch (env) {
        case RaceEnvironment.neonCity:
          if (i % 5 == 0) {
            s.propL = Prop.building; s.offL = 1.5 + r.nextDouble() * 1.4; s.varL = r.nextDouble();
          }
          if (i % 5 == 2) {
            s.propR = Prop.building; s.offR = 1.5 + r.nextDouble() * 1.4; s.varR = r.nextDouble();
          }
          if (i % 10 == 4) { s.propL = Prop.lamp; s.offL = 1.2; }
          if (i % 10 == 9) { s.propR = Prop.lamp; s.offR = 1.2; }
          if (i % 90 == 45) { s.propR = Prop.billboard; s.offR = 1.7; s.varR = r.nextDouble(); }
        case RaceEnvironment.desert:
          if (i % 7 == 0) {
            s.propL = r.nextInt(3) == 0 ? Prop.rock : Prop.tree; s.offL = 1.5 + r.nextDouble() * 3; s.varL = r.nextDouble();
          }
          if (i % 7 == 3) {
            s.propR = r.nextInt(3) == 0 ? Prop.rock : Prop.tree; s.offR = 1.5 + r.nextDouble() * 3; s.varR = r.nextDouble();
          }
          if (i % 120 == 60) { s.propL = Prop.billboard; s.offL = 1.8; s.varL = r.nextDouble(); }
        case RaceEnvironment.countryside:
          if (i % 3 == 0) { s.propL = Prop.tree; s.offL = 1.45 + r.nextDouble() * 3.5; s.varL = r.nextDouble(); }
          if (i % 3 == 1) { s.propR = Prop.tree; s.offR = 1.45 + r.nextDouble() * 3.5; s.varR = r.nextDouble(); }
          if (i % 23 == 5) { s.propR = Prop.rock; s.offR = 1.5 + r.nextDouble(); s.varR = r.nextDouble(); }
          if (i % 140 == 70) { s.propR = Prop.billboard; s.offR = 1.8; s.varR = r.nextDouble(); }
        case RaceEnvironment.midnight:
          if (i % 8 == 0) { s.propL = Prop.lamp; s.offL = 1.2; }
          if (i % 8 == 4) { s.propR = Prop.lamp; s.offR = 1.2; }
          if (i % 6 == 1) { s.propL = Prop.tree; s.offL = 1.8 + r.nextDouble() * 3; s.varL = r.nextDouble(); }
          if (i % 6 == 3) { s.propR = Prop.tree; s.offR = 1.8 + r.nextDouble() * 3; s.varR = r.nextDouble(); }
          if (i % 90 == 30) { s.propR = Prop.billboard; s.offR = 1.7; s.varR = r.nextDouble(); }
      }
    }
  }
}
