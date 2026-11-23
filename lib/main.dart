import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/racer_game.dart';
import 'ui/game_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final game = RacerGame();
  await game.loadProgress();
  runApp(NeonVelocityApp(game: game));
}

class NeonVelocityApp extends StatelessWidget {
  const NeonVelocityApp({super.key, required this.game});
  final RacerGame game;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Neon Velocity',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFF070B16),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00E5FF), brightness: Brightness.dark),
    ),
    home: Scaffold(
      body: GameWidget<RacerGame>(
        game: game,
        overlayBuilderMap: {
          'hud': (context, game) => GameHud(game: game),
          'pause': (context, game) => PauseOverlay(game: game),
          'gameOver': (context, game) => GameOverOverlay(game: game),
          'start': (context, game) => StartOverlay(game: game),
        },
        initialActiveOverlays: const ['hud', 'start'],
      ),
    ),
  );
}
