import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/racer_game.dart';

const _cyan = Color(0xFF00E5FF);

String formatTime(double s) {
  if (s <= 0) return '--:--.--';
  final m = s ~/ 60;
  final sec = (s % 60).toStringAsFixed(2).padLeft(5, '0');
  return '$m:$sec';
}

String ordinal(int n) => switch (n) { 1 => '1ST', 2 => '2ND', 3 => '3RD', _ => '${n}TH' };

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game});
  final RacerGame game;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: game.hudNotifier,
        builder: (context, _) {
          if (game.state == RaceState.ready) return const SizedBox.shrink();
          final versus = game.raceMode != RaceMode.solo;
          return SafeArea(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          if (versus) ...[
                            Text('${game.racePosition}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: .9, shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                            Padding(
                              padding: const EdgeInsets.only(left: 3, bottom: 3),
                              child: Text('${ordinal(game.racePosition).substring(1)}/${game.totalCars}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white70)),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _label('LAP ${game.lap}/${game.laps}'),
                            Text(formatTime(game.raceTime), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()], shadows: [Shadow(color: Colors.black87, blurRadius: 6)])),
                          ]),
                        ]),
                        const SizedBox(height: 6),
                        _bar('NITRO', game.nitro, game.boosting ? const Color(0xFFFFA63D) : _cyan, Icons.bolt),
                        const SizedBox(height: 4),
                        _bar('DAMAGE', game.damage, Color.lerp(const Color(0xFF42E695), const Color(0xFFFF4B4B), game.damage)!, Icons.shield_outlined),
                        if (game.bestLap > 0) Padding(padding: const EdgeInsets.only(top: 4), child: _label('BEST ${formatTime(game.bestLap)}')),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _iconBtn(game.audio.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, game.toggleSound),
                        const SizedBox(width: 6),
                        _iconBtn(Icons.pause_rounded, game.togglePause),
                      ]),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 108,
                        height: 108,
                        child: CustomPaint(painter: _GaugePainter(game.kmh, game.rpm, game.gear, game.boosting)),
                      ),
                    ]),
                  ]),
                  if (versus)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(children: [
                        const Icon(Icons.flag_rounded, size: 12, color: Color(0xFFFFB547)),
                        const SizedBox(width: 5),
                        _label(game.raceMode == RaceMode.online ? 'ONLINE VS ${game.onlineOpponentName}' : '3 AI RIVALS  •  ${game.aiDifficulty.name.toUpperCase()}'),
                      ]),
                    ),
                  const Spacer(),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _pad(Icons.arrow_back_rounded, 'LEFT', game.setSteerLeft, size: 66),
                    const SizedBox(width: 8),
                    _pad(Icons.arrow_forward_rounded, 'RIGHT', game.setSteerRight, size: 66),
                    const Spacer(),
                    Column(children: [
                      _pad(Icons.local_fire_department, 'NITRO', game.setNitro, color: const Color(0xFF00CDEB), size: 62, active: game.boosting, wide: 116),
                      const SizedBox(height: 8),
                      Row(children: [
                        _pad(Icons.waves_rounded, 'DRIFT', game.setDrift, color: const Color(0xFFB66BFF), size: 54, active: game.drifting),
                        const SizedBox(width: 8),
                        _pad(Icons.stop_circle_outlined, 'BRAKE', game.setBrake, color: const Color(0xFFFF5B68), size: 54, active: game.brakeHeld),
                      ]),
                    ]),
                  ]),
                ]),
              ),
              if (game.countdown > 0)
                IgnorePointer(
                  child: Center(
                    child: Text(
                      game.countdown > 3 ? 'READY' : '${game.countdown.ceil()}',
                      style: TextStyle(fontSize: game.countdown > 3 ? 40 : 110, fontWeight: FontWeight.w900, color: Colors.white, shadows: const [Shadow(color: _cyan, blurRadius: 30)]),
                    ),
                  ),
                ),
              if (game.noticeTimer > 0 && game.countdown <= 0)
                IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -.38),
                    child: Text(game.notice, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white, shadows: [Shadow(color: _cyan, blurRadius: 16), Shadow(color: Colors.black, blurRadius: 4)])),
                  ),
                ),
            ]),
          );
        },
      );

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: Colors.white70, shadows: [Shadow(color: Colors.black87, blurRadius: 4)]));

  Widget _bar(String label, double v, Color c, IconData icon) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        SizedBox(
          width: 118,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: v.clamp(0.0, 1.0).toDouble(), minHeight: 6, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(c)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.white60, fontWeight: FontWeight.bold)),
      ]);

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: Colors.black38,
        shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(9), child: Icon(icon, size: 20))),
      );

  Widget _pad(IconData icon, String label, void Function(bool) onChange,
          {Color color = Colors.white, double size = 58, bool active = false, double? wide}) =>
      Listener(
        onPointerDown: (_) => onChange(true),
        onPointerUp: (_) => onChange(false),
        onPointerCancel: (_) => onChange(false),
        child: Container(
          width: wide ?? size,
          height: size,
          decoration: BoxDecoration(
            color: color.withAlpha(active ? 90 : 38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withAlpha(active ? 255 : 190), width: active ? 2 : 1),
            boxShadow: [BoxShadow(color: color.withAlpha(active ? 110 : 30), blurRadius: active ? 18 : 10)],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: size * .42),
            Text(label, style: TextStyle(fontSize: 8, letterSpacing: .8, fontWeight: FontWeight.w900, color: color)),
          ]),
        ),
      );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.kmh, this.rpm, this.gear, this.boost);
  final double kmh, rpm;
  final int gear;
  final bool boost;

  void _text(Canvas canvas, String t, Offset c, double size, Color col, {FontWeight w = FontWeight.w900}) {
    final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: w, color: col)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xAA060A16));
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white24);
    const start = math.pi * .75;
    const sweep = math.pi * 1.5;
    final rect = Rect.fromCircle(center: c, radius: r - 9);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, arc..color = Colors.white12);
    final col = rpm > .88 ? const Color(0xFFFF3B4B) : (boost ? const Color(0xFF58C8FF) : const Color(0xFFFFA63D));
    canvas.drawArc(rect, start, sweep * rpm.clamp(0.0, 1.0), false, arc..color = col);
    final tick = Paint()..color = Colors.white38..strokeWidth = 1.2;
    for (var i = 0; i <= 10; i++) {
      final a = start + sweep * i / 10;
      canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * (r - 2), c + Offset(math.cos(a), math.sin(a)) * (r - (i % 5 == 0 ? 8 : 5)), tick);
    }
    _text(canvas, '${kmh.round()}', c.translate(0, -3), 30, Colors.white);
    _text(canvas, 'KM/H', c.translate(0, 16), 8, Colors.white54);
    _text(canvas, '$gear', c.translate(0, r - 14), 13, col);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => true;
}
