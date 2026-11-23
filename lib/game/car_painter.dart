import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'racer_game.dart' show RaceCar;
import 'track.dart';

double cl(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
Color shade(Color c, double f) => f <= 1
    ? Color.lerp(c, const Color(0xFF000000), 1 - f)!
    : Color.lerp(c, const Color(0xFFFFFFFF), cl(f - 1, 0, 1))!;
Color alpha(Color c, double a) => c.withAlpha((cl(a, 0, 1) * 255).round());

class _Spec {
  const _Spec(this.h, this.cabinW, this.cabinH, this.wing);
  final double h, cabinW, cabinH;
  final int wing;
}

// styles: 0 hatch, 1 muscle, 2 supercar, 3 hypercar, 4 sedan, 5 van
const _specs = <_Spec>[
  _Spec(.78, .72, .42, 0),
  _Spec(.64, .66, .34, 1),
  _Spec(.52, .62, .34, 1),
  _Spec(.48, .58, .32, 2),
  _Spec(.70, .70, .40, 0),
  _Spec(1.0, .94, .72, 0),
];

double carHeightRatio(int style) => _specs[style].h;

/// Draws a car seen from behind. [base] is the bottom-centre contact point.
void drawCar(
  Canvas canvas,
  Offset base,
  double w, {
  required Color color,
  int style = 0,
  bool braking = false,
  double boost = 0,
  double tilt = 0,
  double fog = 0,
  Color fogColor = const Color(0xFF000000),
  bool underglow = false,
  Color glow = const Color(0xFF00E5FF),
}) {
  if (w < 3) return;
  Color f(Color c) => fog <= .01 ? c : Color.lerp(c, fogColor, fog)!;
  final spec = _specs[style];
  final hh = w * spec.h;
  final cx = base.dx;
  double px(double fx) => cx + fx * w / 2;
  double py(double fy) => base.dy - fy * hh;

  if (w < 9) {
    canvas.drawRect(Rect.fromLTWH(px(-.9), py(.7), w * .9, hh * .6), Paint()..color = f(color));
    canvas.drawRect(Rect.fromLTWH(px(-.8), py(.45), w * .25, hh * .1), Paint()..color = f(const Color(0xFFFF2A3A)));
    canvas.drawRect(Rect.fromLTWH(px(.55), py(.45), w * .25, hh * .1), Paint()..color = f(const Color(0xFFFF2A3A)));
    return;
  }

  canvas.save();
  if (tilt != 0) {
    canvas.translate(cx, base.dy);
    canvas.rotate(tilt);
    canvas.translate(-cx, -base.dy);
  }

  // ground shadow
  canvas.drawOval(Rect.fromCenter(center: Offset(cx, base.dy), width: w * 1.15, height: hh * .22),
      Paint()..color = Colors.black.withAlpha((90 * (1 - fog)).round()));
  if (underglow) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, base.dy), width: w * 1.5, height: hh * .45),
      Paint()
        ..shader = RadialGradient(colors: [alpha(glow, .55), alpha(glow, 0)])
            .createShader(Rect.fromCenter(center: Offset(cx, base.dy), width: w * 1.5, height: hh * .45)),
    );
  }

  // wheels
  final wheelH = hh * (style == 5 ? .26 : .32);
  final wheelW = w * .16;
  final tire = Paint()..color = f(const Color(0xFF0B0B0E));
  final rim = Paint()..color = f(const Color(0xFF3A3F4B));
  for (final s in [-1.0, 1.0]) {
    final r = Rect.fromLTWH(s < 0 ? px(-.99) : px(.99) - wheelW, base.dy - wheelH, wheelW, wheelH);
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(wheelW * .3)), tire);
    canvas.drawRect(Rect.fromLTWH(r.left + wheelW * .25, r.top + wheelH * .3, wheelW * .5, wheelH * .12), rim);
  }

  final dark = shade(color, .55);
  final light = shade(color, 1.28);

  if (style == 5) {
    // box van
    final body = Rect.fromLTRB(px(-.92), py(.98), px(.92), py(.1));
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(w * .05)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [f(light), f(color), f(dark)]).createShader(body),
    );
    canvas.drawRect(Rect.fromLTRB(px(-.5), py(.86), px(.5), py(.58)), Paint()..color = f(const Color(0xFF0E1726)));
    canvas.drawLine(Offset(cx, py(.98)), Offset(cx, py(.14)), Paint()..color = f(dark)..strokeWidth = math.max(1, w * .012));
  } else {
    // lower body
    final lower = Path()
      ..moveTo(px(-.95), py(.10))
      ..lineTo(px(-.99), py(.34))
      ..quadraticBezierTo(px(-.97), py(.52), px(-.88), py(.56))
      ..lineTo(px(.88), py(.56))
      ..quadraticBezierTo(px(.97), py(.52), px(.99), py(.34))
      ..lineTo(px(.95), py(.10))
      ..close();
    final lr = Rect.fromLTRB(px(-1), py(.58), px(1), py(.08));
    canvas.drawPath(
      lower,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [f(light), f(color), f(dark)]).createShader(lr),
    );
    // cabin
    final cw = spec.cabinW;
    final top = .56 + spec.cabinH * .9;
    final cabin = Path()
      ..moveTo(px(-cw * .96), py(.55))
      ..lineTo(px(-cw * .62), py(top))
      ..quadraticBezierTo(px(0), py(top + .05), px(cw * .62), py(top))
      ..lineTo(px(cw * .96), py(.55))
      ..close();
    canvas.drawPath(cabin, Paint()..color = f(shade(color, .8)));
    final glass = Path()
      ..moveTo(px(-cw * .86), py(.6))
      ..lineTo(px(-cw * .56), py(top - .04))
      ..quadraticBezierTo(px(0), py(top + .01), px(cw * .56), py(top - .04))
      ..lineTo(px(cw * .86), py(.6))
      ..close();
    final gr = Rect.fromLTRB(px(-cw), py(top), px(cw), py(.58));
    canvas.drawPath(
      glass,
      Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [f(const Color(0xFF1B2A44)), f(const Color(0xFF070B14))]).createShader(gr),
    );
    if (w > 30) {
      canvas.drawLine(Offset(px(-cw * .45), py(top - .06)), Offset(px(-cw * .15), py(.64)),
          Paint()..color = Colors.white.withAlpha((50 * (1 - fog)).round())..strokeWidth = w * .03);
    }
    // body crease
    canvas.drawLine(Offset(px(-.9), py(.55)), Offset(px(.9), py(.55)), Paint()..color = f(light)..strokeWidth = math.max(1, w * .012));
  }

  // diffuser + plate
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTRB(px(-.86), py(.27), px(.86), py(.04)), Radius.circular(w * .03)),
    Paint()..color = f(const Color(0xFF101218)),
  );
  if (w > 18) {
    canvas.drawRect(Rect.fromLTRB(px(-.2), py(.24), px(.2), py(.12)), Paint()..color = f(const Color(0xFFE9ECF2)));
  }

  // exhausts + boost flames
  for (final s in [-1.0, 1.0]) {
    final ex = Offset(px(s * .55), py(.12));
    if (boost > 0.01) {
      final fr = w * (.10 + .09 * boost);
      canvas.drawCircle(
        ex.translate(0, fr * .6),
        fr * 1.4,
        Paint()..shader = RadialGradient(colors: [const Color(0xFFFFFFFF), const Color(0xFF58C8FF), const Color(0x0058C8FF)], stops: const [0, .35, 1])
            .createShader(Rect.fromCircle(center: ex.translate(0, fr * .6), radius: fr * 1.4)),
      );
    }
    canvas.drawCircle(ex, w * .045, Paint()..color = f(const Color(0xFF8A90A0)));
    canvas.drawCircle(ex, w * .03, Paint()..color = f(const Color(0xFF050507)));
  }

  // tail lights
  final lit = braking ? 1.0 : .62;
  final red = Color.lerp(const Color(0xFF7A0A18), const Color(0xFFFF2A3A), lit)!;
  if (braking && w > 14) {
    for (final s in [-1.0, 1.0]) {
      final g = Rect.fromLTRB(px(s < 0 ? -1.04 : .26), py(.62), px(s < 0 ? -.26 : 1.04), py(.24));
      canvas.drawRect(g, Paint()..color = alpha(const Color(0xFFFF2A3A), .28 * (1 - fog)));
    }
  }
  for (final s in [-1.0, 1.0]) {
    final r = Rect.fromLTRB(px(s < 0 ? -.94 : .34), py(.50), px(s < 0 ? -.34 : .94), py(.38));
    canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * .02)), Paint()..color = f(red));
    if (w > 24) {
      canvas.drawRect(Rect.fromLTRB(r.left + r.width * .08, r.top + r.height * .3, r.right - r.width * .08, r.top + r.height * .5),
          Paint()..color = f(braking ? const Color(0xFFFFB3B8) : const Color(0xFFFF6674)));
    }
  }
  if (style == 2 || style == 3) {
    canvas.drawRect(Rect.fromLTRB(px(-.34), py(.455), px(.34), py(.425)), Paint()..color = f(red));
  }

  // spoiler / wing
  if (spec.wing == 1) {
    canvas.drawRect(Rect.fromLTRB(px(-.9), py(.66), px(.9), py(.6)), Paint()..color = f(shade(color, .45)));
  } else if (spec.wing == 2) {
    final p = Paint()..color = f(const Color(0xFF0C0D12));
    canvas.drawRect(Rect.fromLTRB(px(-.55), py(.80), px(-.5), py(.56)), p);
    canvas.drawRect(Rect.fromLTRB(px(.5), py(.80), px(.55), py(.56)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(px(-1.02), py(.88), px(1.02), py(.78)), Radius.circular(w * .02)), Paint()..color = f(shade(color, .5)));
    canvas.drawRect(Rect.fromLTRB(px(-1.02), py(.94), px(-.96), py(.76)), p);
    canvas.drawRect(Rect.fromLTRB(px(.96), py(.94), px(1.02), py(.76)), p);
  }
  canvas.restore();
}

/// Scenery sprite. [x],[y] = base centre, [w] = pixel width, [side] -1 left, 1 right.
void drawProp(Canvas canvas, int kind, RaceEnvironment env, EnvTheme t, double x, double y, double w, double v, int side, double fog, double time) {
  if (w < 2) return;
  Color f(Color c) => fog <= .01 ? c : Color.lerp(c, t.fog, fog)!;
  switch (kind) {
    case Prop.building: {
      final h = w * (1.5 + v * 2.4);
      final rect = Rect.fromLTWH(x - w / 2, y - h, w, h);
      final base = env == RaceEnvironment.midnight ? const Color(0xFF14172B) : const Color(0xFF12183A);
      canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: [f(shade(base, 1.5)), f(base)]).createShader(rect));
      canvas.drawRect(Rect.fromLTWH(x - w / 2, y - h, w, math.max(1.5, w * .03)), Paint()..color = f(t.accent));
      if (w > 20) {
        final cols = math.max(2, (w / 14).floor().clamp(2, 6));
        final rows = math.min(14, (h / 14).floor());
        for (var c = 0; c < cols; c++) {
          for (var r = 0; r < rows; r++) {
            final on = ((c * 7 + r * 13 + (v * 100).floor()) % 5) != 0;
            if (!on) continue;
            final col = (c + r) % 3 == 0 ? const Color(0xFFFF4FA3) : ((c + r) % 3 == 1 ? t.accent : const Color(0xFFFFE08A));
            canvas.drawRect(
              Rect.fromLTWH(x - w / 2 + w * .1 + c * (w * .8 / cols), y - h + h * .06 + r * (h * .88 / rows), w * .8 / cols * .55, h * .88 / rows * .5),
              Paint()..color = f(alpha(col, .85)),
            );
          }
        }
      }
    }
    case Prop.lamp: {
      final ph = w * 4.2;
      final pw = math.max(1.5, w * .09);
      final p = Paint()..color = f(const Color(0xFF2A2F3E));
      canvas.drawRect(Rect.fromLTWH(x - pw / 2, y - ph, pw, ph), p);
      final armEnd = x - side * w * .8;
      canvas.drawLine(Offset(x, y - ph), Offset(armEnd, y - ph - w * .1), p..strokeWidth = pw);
      final lc = t.night ? const Color(0xFFFFE9A8) : const Color(0xFFEFEFEF);
      if (t.night) {
        canvas.drawCircle(Offset(armEnd, y - ph - w * .1), w * .9,
            Paint()..shader = RadialGradient(colors: [alpha(lc, .55 * (1 - fog)), alpha(lc, 0)]).createShader(Rect.fromCircle(center: Offset(armEnd, y - ph - w * .1), radius: w * .9)));
      }
      canvas.drawCircle(Offset(armEnd, y - ph - w * .1), math.max(1.5, w * .14), Paint()..color = f(lc));
    }
    case Prop.tree: {
      final h = w * (1.5 + v * .8);
      if (env == RaceEnvironment.desert) {
        final g = Paint()..color = f(const Color(0xFF3E7A45));
        final tw = w * .24;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - tw / 2, y - h, tw, h), Radius.circular(tw / 2)), g);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w * .5, y - h * .62, w * .18, h * .3), Radius.circular(tw / 2)), g);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - w * .5, y - h * .4, w * .38, tw * .9), Radius.circular(tw / 2)), g);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .32, y - h * .75, w * .18, h * .35), Radius.circular(tw / 2)), g);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .12, y - h * .48, w * .38, tw * .9), Radius.circular(tw / 2)), g);
      } else {
        final night = env == RaceEnvironment.midnight;
        canvas.drawRect(Rect.fromLTWH(x - w * .06, y - h * .25, w * .12, h * .25), Paint()..color = f(const Color(0xFF4B3426)));
        for (var i = 0; i < 3; i++) {
          final tw = w * (.95 - i * .22);
          final ty = y - h * .2 - i * h * .27;
          final path = Path()..moveTo(x - tw / 2, ty)..lineTo(x, ty - h * .42)..lineTo(x + tw / 2, ty)..close();
          final c = night ? const Color(0xFF0E1D2A) : const Color(0xFF1F6B3A);
          canvas.drawPath(path, Paint()..color = f(shade(c, 1 + i * .18)));
        }
      }
    }
    case Prop.rock: {
      final h = w * .6;
      final path = Path()..moveTo(x - w / 2, y);
      const pts = [[-.45, .45], [-.3, .85], [.0, 1.0], [.32, .8], [.5, .35], [.5, 0.0]];
      for (final p in pts) {
        path.lineTo(x + p[0] * w, y - p[1] * h * (.8 + v * .4));
      }
      path.close();
      final rc = env == RaceEnvironment.desert ? const Color(0xFFA85F3B) : const Color(0xFF6C7078);
      canvas.drawPath(path, Paint()..color = f(rc));
      canvas.drawPath(Path()..moveTo(x, y - h)..lineTo(x + w * .32, y - h * .8)..lineTo(x + w * .5, y - h * .35)..lineTo(x + w * .1, y)..lineTo(x, y)..close(),
          Paint()..color = f(shade(rc, .7)));
    }
    case Prop.billboard: {
      final pw = math.max(1.5, w * .04);
      final post = Paint()..color = f(const Color(0xFF30343F));
      final ph = w * .85;
      canvas.drawRect(Rect.fromLTWH(x - w * .35, y - ph, pw, ph), post);
      canvas.drawRect(Rect.fromLTWH(x + w * .35 - pw, y - ph, pw, ph), post);
      final panel = Rect.fromLTWH(x - w / 2, y - ph - w * .5, w, w * .5);
      final cols = [t.accent, const Color(0xFFFF4FA3), const Color(0xFFFFC857)];
      final c1 = cols[(v * 3).floor() % 3];
      canvas.drawRRect(RRect.fromRectAndRadius(panel.inflate(w * .02), Radius.circular(w * .02)), Paint()..color = f(const Color(0xFF0B0E17)));
      canvas.drawRect(panel, Paint()..shader = LinearGradient(colors: [f(c1), f(shade(c1, .45))]).createShader(panel));
      if (w > 24) {
        canvas.drawRect(Rect.fromLTWH(panel.left + w * .08, panel.top + w * .12, w * .5, w * .06), Paint()..color = f(Colors.white));
        canvas.drawRect(Rect.fromLTWH(panel.left + w * .08, panel.top + w * .26, w * .32, w * .04), Paint()..color = f(alpha(Colors.white, .7)));
      }
    }
  }
}

/// Stand-alone painter used in the garage / menus.
class CarPreview extends StatelessWidget {
  const CarPreview({super.key, required this.car, this.size = const Size(86, 64)});
  final RaceCar car;
  final Size size;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(painter: _PreviewPainter(car)),
      );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.car);
  final RaceCar car;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * .8;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)), Paint()..color = alpha(car.color, .12));
    drawCar(canvas, Offset(size.width / 2, size.height * .9), w, color: car.color, style: car.style, braking: true, underglow: true, glow: car.color);
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.car.id != car.id;
}
