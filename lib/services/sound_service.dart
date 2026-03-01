// Generates and plays short synthesised tones for game events.
//
// All audio data is built in pure Dart — no bundled asset files required.
// Each event has a distinct pitch/rhythm pattern:
//   • Money Ball  : ascending ding-ding  (exciting)
//   • Draw Alert  : falling chime        (neutral caution)
//   • Elimination : descending buzz      (urgent warning)
//   • Game Over   : 4-note fanfare       (celebration)
//   • Game Over Draw: 3-note neutral end

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  // One dedicated player per sound category so they can overlap.
  final _moneyBallPlayer   = AudioPlayer();
  final _eliminationPlayer = AudioPlayer();
  final _drawPlayer        = AudioPlayer();
  final _gameOverPlayer    = AudioPlayer();

  // Pre-built WAV bytes (populated lazily on first play).
  Uint8List? _moneyBallWav;
  Uint8List? _eliminationWav;
  Uint8List? _drawWav;
  Uint8List? _gameOverWav;
  Uint8List? _gameOverDrawWav;

  bool _enabled = true;
  static const _kSoundKey = 'sound_enabled';

  // ── Public API ─────────────────────────────────────────────────────────

  bool get isEnabled => _enabled;

  /// Load persisted preference on startup.
  Future<void> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kSoundKey) ?? true;
    } catch (_) {}
  }

  /// Toggle sound on/off and persist the choice.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundKey, value);
    } catch (_) {}
  }

  /// Ascending ding-ding — "this is your shot to win!"
  Future<void> playMoneyBall() => _play(
        _moneyBallPlayer,
        _moneyBallWav ??= _wavFromNotes([
          (hz: 880,  ms: 160),  // A5
          (hz: 1108, ms: 280),  // C#6
        ]),
      );

  /// Descending buzz — "someone is about to be knocked out"
  Future<void> playElimination() => _play(
        _eliminationPlayer,
        _eliminationWav ??= _wavFromNotes([
          (hz: 440, ms: 140),  // A4
          (hz: 330, ms: 280),  // E4
        ]),
      );

  /// Falling chime — "this pocket could be a draw"
  Future<void> playDraw() => _play(
        _drawPlayer,
        _drawWav ??= _wavFromNotes([
          (hz: 523, ms: 170),  // C5
          (hz: 415, ms: 280),  // Ab4
        ]),
      );

  /// Triumphant fanfare C→E→G→C — "we have a winner!"
  Future<void> playGameOver() => _play(
        _gameOverPlayer,
        _gameOverWav ??= _wavFromNotes([
          (hz: 523,  ms: 110),  // C5
          (hz: 659,  ms: 110),  // E5
          (hz: 784,  ms: 110),  // G5
          (hz: 1047, ms: 340),  // C6
        ]),
      );

  /// Neutral 3-note close — "game over, it's a draw"
  Future<void> playGameOverDraw() => _play(
        _gameOverPlayer,
        _gameOverDrawWav ??= _wavFromNotes([
          (hz: 440, ms: 140),  // A4
          (hz: 523, ms: 140),  // C5
          (hz: 440, ms: 280),  // A4
        ]),
      );

  // ── Internals ──────────────────────────────────────────────────────────

  Future<void> _play(AudioPlayer player, Uint8List wav) async {
    if (!_enabled) return;
    try {
      await player.play(BytesSource(wav), volume: 0.75);
    } catch (_) {
      // Never crash the game for a missing sound.
    }
  }

  // ── WAV builder ────────────────────────────────────────────────────────

  /// Builds a 16-bit mono 44.1 kHz WAV containing [notes] played in sequence.
  /// A 15 ms linear fade-in and fade-out is applied to each note to prevent
  /// clicks.
  static Uint8List _wavFromNotes(
      List<({int hz, int ms})> notes) {
    const sampleRate = 44100;
    const fadeSamples = 661; // ~15 ms at 44100 Hz

    // Build all PCM samples as doubles first.
    final pcm = <double>[];
    for (final note in notes) {
      final count = (sampleRate * note.ms / 1000).round();
      for (int i = 0; i < count; i++) {
        final t = i / sampleRate;
        // Fade envelope.
        double env = 1.0;
        if (i < fadeSamples) env = i / fadeSamples;
        if (i > count - fadeSamples) env = (count - i) / fadeSamples;
        pcm.add(math.sin(2 * math.pi * note.hz * t) * env * 0.7);
      }
    }

    // Pack into WAV.
    final dataBytes = pcm.length * 2; // 16-bit LE
    final buf = ByteData(44 + dataBytes);

    _fourCC(buf, 0,  'RIFF');
    buf.setUint32( 4, 36 + dataBytes, Endian.little);
    _fourCC(buf, 8,  'WAVE');
    _fourCC(buf, 12, 'fmt ');
    buf.setUint32(16, 16,          Endian.little); // chunk size
    buf.setUint16(20,  1,          Endian.little); // PCM
    buf.setUint16(22,  1,          Endian.little); // mono
    buf.setUint32(24, sampleRate,  Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little); // byteRate
    buf.setUint16(32,  2,          Endian.little); // blockAlign
    buf.setUint16(34, 16,          Endian.little); // bitsPerSample
    _fourCC(buf, 36, 'data');
    buf.setUint32(40, dataBytes,   Endian.little);

    for (int i = 0; i < pcm.length; i++) {
      buf.setInt16(
        44 + i * 2,
        (pcm[i] * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }

    return buf.buffer.asUint8List();
  }

  static void _fourCC(ByteData buf, int offset, String s) {
    for (int i = 0; i < 4; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
