import 'package:flutter_test/flutter_test.dart';
import 'package:neon_velocity/game/racer_game.dart';

void main() {
  test('race modes and garage are available', () {
    final game = RacerGame();
    expect(game.raceMode, RaceMode.solo);
    expect(raceCars, hasLength(4));
    expect(game.aiDifficulty, AiDifficulty.pro);
  });
}
