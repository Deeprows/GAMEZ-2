import 'package:flutter/material.dart';
import '../game/racer_game.dart';
import '../game/multiplayer_client.dart';

class OnlineLobbyOverlay extends StatefulWidget {
  const OnlineLobbyOverlay({super.key, required this.game});
  final RacerGame game;

  @override
  State<OnlineLobbyOverlay> createState() => _OnlineLobbyOverlayState();
}

class _OnlineLobbyOverlayState extends State<OnlineLobbyOverlay> {
  static const _defaultEndpoint = String.fromEnvironment('RACE_SERVER_URL');
  final _nameController = TextEditingController(text: 'Driver');
  final _endpointController = TextEditingController(text: _defaultEndpoint);
  String _status = 'Connect to matchmaking to find another driver.';
  bool _connecting = false;
  bool _matched = false;
  String? _error;

  Future<void> _connect() async {
    final endpoint = _endpointController.text.trim();
    if (endpoint.isEmpty) {
      setState(() => _error = 'Enter the multiplayer WebSocket URL. Deploy the included server first.');
      return;
    }
    setState(() { _connecting = true; _error = null; _status = 'Connecting to race server…'; });
    try {
      final client = await RaceMultiplayerClient.connect(
        endpoint: endpoint,
        playerName: _nameController.text.trim().isEmpty ? 'Driver' : _nameController.text.trim(),
        onMessage: (message) {
          if (!mounted) return;
          final type = message['type'];
          if (type == 'matched') {
            widget.game.onlineOpponentName = (message['opponentName'] ?? 'Rival').toString();
            widget.game.onlineOpponentConnected = true;
            widget.game.chooseRaceMode(RaceMode.online);
            setState(() { _matched = true; _connecting = false; _status = 'Opponent found — race started!'; });
            widget.game.startRace();
          } else if (type == 'state') {
            widget.game.onlineOpponentProgress = (message['progress'] as num? ?? 0).toDouble();
            widget.game.onlineOpponentLane = (message['lane'] as num? ?? 0).toDouble();
            widget.game.hudNotifier.value++;
          } else if (type == 'opponent_left') {
            widget.game.onlineOpponentConnected = false;
            setState(() => _status = 'Your opponent disconnected.');
          } else if (type == 'waiting') {
            setState(() => _status = 'Searching for another driver…');
          }
        },
        onError: (error) {
          if (mounted) setState(() { _connecting = false; _error = 'Connection error: $error'; });
        },
        onDisconnected: () {
          widget.game.onlineOpponentConnected = false;
          if (mounted) setState(() { _connecting = false; _status = 'Disconnected from race server.'; });
        },
      );
      widget.game.multiplayerClient = client;
      if (mounted) setState(() => _status = 'Connected. Waiting for another driver…');
    } catch (error) {
      if (mounted) setState(() { _connecting = false; _error = 'Could not connect: $error'; });
    }
  }

  void _close() {
    widget.game.multiplayerClient?.leave();
    widget.game.multiplayerClient = null;
    widget.game.onlineOpponentConnected = false;
    widget.game.overlays.remove('onlineLobby');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_matched) {
      return Positioned(
        top: 54, left: 12, right: 12,
        child: SafeArea(child: Align(alignment: Alignment.topCenter, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(color: const Color(0xEE10182B), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB66BFF))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.public, color: Color(0xFFB66BFF), size: 17),
            const SizedBox(width: 8),
            Flexible(child: Text('ONLINE RACE  •  VS ${widget.game.onlineOpponentName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
            IconButton(onPressed: _close, icon: const Icon(Icons.close, size: 17), visualDensity: VisualDensity.compact),
          ]),
        ))),
      );
    }
    return Container(
      color: const Color(0xF2070B16),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(22),
      child: SafeArea(child: SingleChildScrollView(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.public_rounded, color: Color(0xFFB66BFF), size: 48),
          const SizedBox(height: 12),
          const Text('ONLINE MATCHMAKING', textAlign: TextAlign.center, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(_status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 22),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Racer name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _endpointController, decoration: const InputDecoration(labelText: 'WebSocket server URL', hintText: 'wss://your-game-server.onrender.com', border: OutlineInputBorder())),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 11))),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _connecting ? null : _connect,
            icon: _connecting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
            label: Text(_connecting ? 'CONNECTING…' : 'FIND AN OPPONENT')),
          TextButton(onPressed: _close, child: const Text('BACK TO RACE MODES')),
        ]),
      ))),
    );
  }
}
