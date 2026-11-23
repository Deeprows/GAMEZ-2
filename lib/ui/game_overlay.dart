import 'package:flutter/material.dart';
import '../game/racer_game.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game});
  final RacerGame game;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: game.hudNotifier,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                _stat('DISTANCE', '${game.distance.toInt()} m'),
                const Spacer(),
                _stat('SPEED', '${(game.speed * 320).toInt()} km/h'),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: game.togglePause,
                  icon: Icon(game.state == RaceState.paused ? Icons.play_arrow : Icons.pause),
                ),
              ]),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 125,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('NITRO', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: game.nitro,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _control(Icons.arrow_back_rounded, () => game.steer(-.55)),
                  const Spacer(),
                  GestureDetector(
                    onTapDown: (_) => game.setNitro(true),
                    onTapUp: (_) => game.setNitro(false),
                    onTapCancel: () => game.setNitro(false),
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00CDEB).withOpacity(.2),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x5500E5FF), blurRadius: 18)],
                      ),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.bolt, color: Color(0xFF00E5FF), size: 27),
                        Text('NITRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  _control(Icons.arrow_forward_rounded, () => game.steer(.55)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 2, color: Colors.white60, fontWeight: FontWeight.bold)),
      Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
    ],
  );

  Widget _control(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 66, height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(icon, size: 32),
    ),
  );
}

class StartOverlay extends StatelessWidget {
  const StartOverlay({super.key, required this.game});
  final RacerGame game;
  @override
  Widget build(BuildContext context) => _panel(
    title: 'NEON VELOCITY',
    subtitle: 'OWN THE NIGHT. RULE THE ROAD.',
    button: 'START RACE',
    onPressed: game.startRace,
    footer: 'STEER • DODGE • BOOST',
  );
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final RacerGame game;
  @override
  Widget build(BuildContext context) => _panel(
    title: 'RACE PAUSED',
    subtitle: 'Take a breath. The road is waiting.',
    button: 'RESUME RACE',
    onPressed: game.togglePause,
    footer: 'YOUR RUN IS STILL LIVE',
  );
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final RacerGame game;
  @override
  Widget build(BuildContext context) => _panel(
    title: 'CRASHED!',
    subtitle: 'Distance: ${game.distance.toInt()} m • Best: ${game.best} m',
    button: 'RACE AGAIN',
    onPressed: game.startRace,
    footer: 'WATCH THE TRAFFIC. FIND YOUR LINE.',
  );
}

Widget _panel({
  required String title,
  required String subtitle,
  required String button,
  required VoidCallback onPressed,
  required String footer,
}) => Container(
  color: const Color(0xCC050916),
  alignment: Alignment.center,
  padding: const EdgeInsets.all(28),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.sports_motorsports, color: Color(0xFF00E5FF), size: 54),
      const SizedBox(height: 20),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(
        fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2,
        shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 18)],
      )),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, letterSpacing: 1)),
      const SizedBox(height: 32),
      SizedBox(
        width: 230, height: 54,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00CDEB),
            foregroundColor: const Color(0xFF04101C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(button, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      ),
      const SizedBox(height: 22),
      Text(footer, style: const TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 2)),
    ],
  ),
);
