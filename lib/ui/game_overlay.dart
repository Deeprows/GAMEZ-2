import 'package:flutter/material.dart';
import '../game/racer_game.dart';
import '../game/multiplayer_client.dart';

const _cyan = Color(0xFF00E5FF);
const _panel = Color(0xEE10182B);

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.game});
  final RacerGame game;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: game.hudNotifier,
    builder: (context, _) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(children: [
          Row(children: [
            _hudStat('DISTANCE', '${game.distance.toInt()} m'),
            const Spacer(),
            _hudStat('SPEED', '${(game.speed * 320).toInt()}'),
            const SizedBox(width: 4),
            const Text('KM/H', style: TextStyle(fontSize: 9, color: Colors.white60)),
            const Spacer(),
            _hudStat('LEVEL', '${game.level}'),
            IconButton.filledTonal(onPressed: game.togglePause, icon: const Icon(Icons.pause_rounded)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.bolt, color: _cyan, size: 17),
            const SizedBox(width: 6),
            const Text('TURBO', style: TextStyle(fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(width: 8),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(value: game.nitro, minHeight: 7,
                backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(_cyan)),
            )),
            const SizedBox(width: 8),
            Text('${(game.nitro * 100).round()}%', style: const TextStyle(fontSize: 10)),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _holdButton(Icons.arrow_back_rounded, 'LEFT', () => game.steer(-.45)),
            const SizedBox(width: 8),
            _holdButton(Icons.arrow_forward_rounded, 'RIGHT', () => game.steer(.45)),
            const Spacer(),
            Column(children: [
              _holdButton(Icons.local_fire_department, 'TURBO', () => game.setNitro(true),
                onUp: () => game.setNitro(false), color: const Color(0xFF00CDEB)),
              const SizedBox(height: 8),
              _holdButton(Icons.directions_car_filled, 'DRIFT', () => game.setDrift(true),
                onUp: () => game.setDrift(false), color: const Color(0xFFB66BFF)),
            ]),
            const SizedBox(width: 8),
            Column(children: [
              _holdButton(Icons.keyboard_arrow_up_rounded, 'GAS', () => game.setThrottle(true),
                onUp: () => game.setThrottle(false), color: const Color(0xFF42E695)),
              const SizedBox(height: 8),
              _holdButton(Icons.keyboard_arrow_down_rounded, 'BRAKE', () => game.setBrake(true),
                onUp: () => game.setBrake(false), color: const Color(0xFFFF5B68)),
            ]),
          ]),
        ]),
      ),
    ),
  );

  Widget _hudStat(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 8, letterSpacing: 1.6, color: Colors.white60, fontWeight: FontWeight.bold)),
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
  ]);
}

Widget _holdButton(IconData icon, String label, VoidCallback onDown,
    {VoidCallback? onUp, Color color = Colors.white}) => GestureDetector(
  onTap: onUp == null ? onDown : null,
  onTapDown: onUp == null ? null : (_) => onDown(),
  onTapUp: onUp == null ? null : (_) => onUp(),
  onTapCancel: onUp,
  child: Container(
    width: 58, height: 58,
    decoration: BoxDecoration(color: color.withOpacity(.16), borderRadius: BorderRadius.circular(17),
      border: Border.all(color: color.withOpacity(.75)), boxShadow: [BoxShadow(color: color.withOpacity(.12), blurRadius: 12)]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 22),
      Text(label, style: TextStyle(fontSize: 7, letterSpacing: .8, fontWeight: FontWeight.w900, color: color)),
    ]),
  ),
);

class StartOverlay extends StatelessWidget {
  const StartOverlay({super.key, required this.game});
  final RacerGame game;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: game.hudNotifier,
    builder: (context, _) {
      switch (game.menuPage) {
        case MenuPage.garage: return _garage(context);
        case MenuPage.environments: return _environments(context);
        case MenuPage.career: return _career(context);
        case MenuPage.modes: return _modes(context);
        case MenuPage.home: return _home(context);
      }
    },
  );

  Widget _shell({required String title, required Widget child, String? trailing}) => Container(
    color: const Color(0xE8070B16),
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(onPressed: () => game.showPage(MenuPage.home), icon: const Icon(Icons.arrow_back_rounded)),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1.4))),
        if (trailing != null) Text(trailing, style: const TextStyle(color: Color(0xFFFFD447), fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 14),
      Expanded(child: child),
    ])),
  );

  Widget _home(BuildContext context) => Container(
    color: const Color(0xE8070B16),
    alignment: Alignment.center,
    padding: const EdgeInsets.all(22),
    child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.sports_motorsports_rounded, color: _cyan, size: 52),
      const SizedBox(height: 10),
      const Text('NEON VELOCITY', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: 2.5,
          shadows: [Shadow(color: _cyan, blurRadius: 18)])),
      const Text('RACING CHAMPIONSHIP', style: TextStyle(color: Colors.white60, letterSpacing: 3, fontSize: 10)),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _pill(Icons.monetization_on, '${game.coins} COINS', const Color(0xFFFFD447)),
        const SizedBox(width: 8),
        _pill(Icons.emoji_events, 'LEVEL ${game.level}', _cyan),
      ]),
      const SizedBox(height: 26),
      _bigButton('CHOOSE RACE MODE', Icons.flag_rounded, () => game.showPage(MenuPage.modes)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _menuButton('GARAGE', Icons.directions_car, () => game.showPage(MenuPage.garage))),
        const SizedBox(width: 9),
        Expanded(child: _menuButton('TRACKS', Icons.landscape, () => game.showPage(MenuPage.environments))),
      ]),
      const SizedBox(height: 9),
      _menuButton('CAREER & REWARDS', Icons.emoji_events, () => game.showPage(MenuPage.career), wide: true),
      const SizedBox(height: 22),
      Text('CAR  •  ${game.selectedCar.name.toUpperCase()}     TRACK  •  ${_environmentName(game.environment).toUpperCase()}',
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1.1)),
      const SizedBox(height: 12),
      const Text('STEER  •  DRIFT  •  TURBO  •  WIN', style: TextStyle(fontSize: 9, color: _cyan, letterSpacing: 2)),
    ])),
  );

  Widget _garage(BuildContext context) => _shell(
    title: 'CAR GARAGE',
    trailing: '🪙 ${game.coins}',
    child: ListView(children: [
      const Text('CHOOSE YOUR MACHINE', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 12),
      for (final car in raceCars) _carCard(car, context),
    ]),
  );

  Widget _carCard(RaceCar car, BuildContext context) {
    final owned = game.unlockedCars.contains(car.id);
    final selected = game.selectedCarId == car.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? car.color : Colors.white12, width: selected ? 2 : 1)),
      child: Row(children: [
        Container(width: 58, height: 58, decoration: BoxDecoration(color: car.color.withOpacity(.13), borderRadius: BorderRadius.circular(15)),
          child: Icon(Icons.directions_car_filled_rounded, color: car.color, size: 37)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(car.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 7),
          _statBar('TOP SPEED', car.topSpeed, car.color),
          _statBar('ACCELERATION', car.acceleration, car.color),
          _statBar('HANDLING', car.handling, car.color),
        ])),
        const SizedBox(width: 8),
        SizedBox(width: 84, child: FilledButton(
          onPressed: selected ? null : () {
            final ok = game.buyOrSelectCar(car);
            if (!ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins yet. Win races to earn more!')));
          },
          style: FilledButton.styleFrom(backgroundColor: car.color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 5)),
          child: Text(selected ? 'SELECTED' : owned ? 'SELECT' : '${car.price} 🪙', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
        )),
      ]),
    );
  }

  Widget _statBar(String label, double value, Color color) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 7, color: Colors.white54, letterSpacing: .6))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: value, minHeight: 4, backgroundColor: Colors.white12, valueColor: AlwaysStoppedAnimation(color)))),
    ]),
  );

  Widget _environments(BuildContext context) => _shell(
    title: 'SELECT TRACK',
    child: ListView(children: [
      const Text('FOUR WORLDS. ONE CHAMPION.', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 14),
      for (final env in RaceEnvironment.values)
        _trackCard(env),
    ]),
  );

  Widget _trackCard(RaceEnvironment env) {
    final selected = game.environment == env;
    final color = switch (env) {
      RaceEnvironment.neonCity => _cyan,
      RaceEnvironment.desert => const Color(0xFFFFC06B),
      RaceEnvironment.countryside => const Color(0xFF9BEB91),
      RaceEnvironment.midnight => const Color(0xFF9D83FF),
    };
    final icon = switch (env) {
      RaceEnvironment.neonCity => Icons.location_city,
      RaceEnvironment.desert => Icons.wb_sunny,
      RaceEnvironment.countryside => Icons.forest,
      RaceEnvironment.midnight => Icons.nightlight_round,
    };
    return InkWell(
      onTap: () => game.chooseEnvironment(env),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: color.withOpacity(.12),
          border: Border.all(color: selected ? color : Colors.white12, width: selected ? 2 : 1)),
        child: Row(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_environmentName(env), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(_environmentDescription(env), style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ])),
          if (selected) Icon(Icons.check_circle, color: color),
        ]),
      ),
    );
  }


  Widget _modes(BuildContext context) => _shell(
    title: 'SELECT RACE MODE',
    child: ListView(children: [
      const Text('PICK YOUR CHALLENGE', style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 14),
      _modeCard('FREE DRIVE', 'Practice the road, master the drift and test your car.', Icons.route_rounded, _cyan,
        () { game.chooseRaceMode(RaceMode.solo); game.startRace(); }),
      _modeCard('PLAYER VS COMPUTER', 'Race three AI drivers. Choose how aggressive they are.', Icons.smart_toy_rounded, const Color(0xFFFFB547),
        () => _showAiDifficulty(context)),
      _modeCard('ONLINE MULTIPLAYER', 'Join matchmaking and race another real player.', Icons.public_rounded, const Color(0xFFB66BFF),
        () => game.overlays.add('onlineLobby')),
      const SizedBox(height: 12),
      Text('AI DIFFICULTY: ${game.aiDifficulty.name.toUpperCase()}', style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final difficulty in AiDifficulty.values)
          ChoiceChip(label: Text(difficulty.name.toUpperCase()),
            selected: game.aiDifficulty == difficulty,
            onSelected: (_) => game.chooseDifficulty(difficulty)),
      ]),
      const SizedBox(height: 10),
      _bigButton('RACE AGAINST AI', Icons.flag_rounded, () {
        game.chooseRaceMode(RaceMode.versusComputer);
        game.startRace();
      }),
    ]),
  );

  void _showAiDifficulty(BuildContext context) {
    showModalBottomSheet<void>(context: context, backgroundColor: const Color(0xFF10182B), builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('CHOOSE AI DIFFICULTY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        for (final difficulty in AiDifficulty.values)
          ListTile(title: Text(difficulty.name.toUpperCase()),
            subtitle: Text(switch (difficulty) { AiDifficulty.rookie => 'Relaxed rivals — learn the track.', AiDifficulty.pro => 'Balanced, competitive opponents.', AiDifficulty.elite => 'Fast and aggressive racing line.' }),
            trailing: game.aiDifficulty == difficulty ? const Icon(Icons.check_circle, color: _cyan) : null,
            onTap: () { game.chooseDifficulty(difficulty); Navigator.pop(sheetContext); game.chooseRaceMode(RaceMode.versusComputer); game.startRace(); }),
      ]),
    ));
  }

  Widget _modeCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.55))),
      child: Row(children: [
        Icon(icon, color: color, size: 32), const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .7)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white60)),
        ])),
        Icon(Icons.chevron_right_rounded, color: color),
      ]),
    )),
  );

  Widget _career(BuildContext context) => _shell(
    title: 'CAREER & REWARDS',
    child: ListView(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF123B55), Color(0xFF18203D)])),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CHAMPIONSHIP PROGRESS', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('LEVEL ${game.level}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          Text('${game.racesWon} races won  •  Best distance ${game.bestDistance} m', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _careerStat('WALLET', '${game.coins}', Icons.monetization_on, const Color(0xFFFFD447))),
        const SizedBox(width: 10),
        Expanded(child: _careerStat('VICTORIES', '${game.racesWon}', Icons.emoji_events, _cyan)),
      ]),
      const SizedBox(height: 18),
      const Text('RACE REWARDS', style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      _rewardRow('Finish a championship race', '120+ coins'),
      _rewardRow('Higher championship levels', 'Bigger payouts'),
      _rewardRow('Drift during your race', 'Bonus coins'),
      _rewardRow('Unlock new cars', 'Improve your stats'),
      const SizedBox(height: 16),
      _bigButton('RACE FOR REWARDS', Icons.flag, game.startRace),
    ]),
  );

  Widget _careerStat(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Icon(icon, color: color, size: 25),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60, letterSpacing: 1)),
    ]),
  );

  Widget _rewardRow(String title, String reward) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, color: _cyan, size: 18),
      const SizedBox(width: 9),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
      Text(reward, style: const TextStyle(color: Color(0xFFFFD447), fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});
  final RacerGame game;
  @override
  Widget build(BuildContext context) => _messagePanel(
    title: 'RACE PAUSED', subtitle: 'Your championship run is waiting.',
    button: 'RESUME RACE', onPressed: game.togglePause,
    secondary: 'QUIT TO GARAGE', onSecondary: () {
      game.state = RaceState.ready;
      game.overlays.remove('pause');
      game.overlays.add('start');
      game.showPage(MenuPage.home);
      game.resumeEngine();
    },
  );
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final RacerGame game;
  @override
  Widget build(BuildContext context) => _messagePanel(
    title: game.state == RaceState.finished ? 'CHAMPION!' : 'RACE OVER',
    subtitle: game.state == RaceState.finished
      ? 'Level cleared! +${game.lastReward} coins. Next championship unlocked.'
      : 'Distance: ${game.distance.toInt()} m  •  Reward: +${game.lastReward} coins',
    button: 'NEXT RACE', onPressed: game.startRace,
    secondary: 'BACK TO GARAGE', onSecondary: () {
      game.state = RaceState.ready;
      game.overlays.remove('gameOver');
      game.overlays.add('start');
      game.showPage(MenuPage.home);
      game.resumeEngine();
    },
  );
}

Widget _messagePanel({required String title, required String subtitle, required String button,
  required VoidCallback onPressed, required String secondary, required VoidCallback onSecondary}) => Container(
  color: const Color(0xE8070B16),
  alignment: Alignment.center,
  padding: const EdgeInsets.all(28),
  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.sports_motorsports, color: _cyan, size: 54),
    const SizedBox(height: 18),
    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
    const SizedBox(height: 10),
    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    const SizedBox(height: 28),
    SizedBox(width: 240, height: 52, child: FilledButton(onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: Colors.black),
      child: Text(button, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)))),
    const SizedBox(height: 10),
    TextButton(onPressed: onSecondary, child: Text(secondary, style: const TextStyle(color: Colors.white70))),
  ]),
);

Widget _bigButton(String label, IconData icon, VoidCallback onTap) => SizedBox(
  width: double.infinity, height: 54,
  child: FilledButton.icon(onPressed: onTap, icon: Icon(icon),
    style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: const Color(0xFF04101C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
    label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1, fontSize: 11))),
);

Widget _menuButton(String label, IconData icon, VoidCallback onTap, {bool wide = false}) => SizedBox(
  width: wide ? double.infinity : null, height: 48,
  child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 17),
    style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8))),
);

Widget _pill(IconData icon, String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(.4))),
  child: Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 5),
    Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900))]),
);

String _environmentName(RaceEnvironment env) => switch (env) {
  RaceEnvironment.neonCity => 'Neon City',
  RaceEnvironment.desert => 'Desert Run',
  RaceEnvironment.countryside => 'Green Valley',
  RaceEnvironment.midnight => 'Midnight Circuit',
};
String _environmentDescription(RaceEnvironment env) => switch (env) {
  RaceEnvironment.neonCity => 'Glowing skyline and high-speed streets',
  RaceEnvironment.desert => 'Golden dunes and sunset highways',
  RaceEnvironment.countryside => 'Rolling hills and open country roads',
  RaceEnvironment.midnight => 'Dark roads under a violet night sky',
};
