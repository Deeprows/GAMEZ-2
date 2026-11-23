import 'package:flutter_test/flutter_test.dart';
import 'package:neon_velocity/game/racer_game.dart';
import 'package:neon_velocity/game/track.dart';

void main() {
  test('race modes and garage are available', () {
    final game = RacerGame();
    expect(game.raceMode, RaceMode.solo);
    expect(raceCars, hasLength(4));
    expect(game.aiDifficulty, AiDifficulty.pro);
  });

  test('every track is a closed loop with enough segments', () {
    for (final env in RaceEnvironment.values) {
      final track = Track(env);
      expect(track.count, greaterThan(1000));
      expect(track.segments.last.y2.abs(), lessThan(1));
      expect(track.segments.first.y1, 0);
    }
  });
}
