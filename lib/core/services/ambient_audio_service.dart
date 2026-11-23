import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

enum AmbientSound {
  off,
  rain,
  cafe,
  whiteNoise;

  String get label => switch (this) {
        AmbientSound.off => 'Off',
        AmbientSound.rain => 'Rain',
        AmbientSound.cafe => 'Cafe',
        AmbientSound.whiteNoise => 'White Noise',
      };

  String? get assetPath => switch (this) {
        AmbientSound.off => null,
        AmbientSound.rain => 'assets/audio/rain.mp3',
        AmbientSound.cafe => 'assets/audio/cafe.mp3',
        AmbientSound.whiteNoise => 'assets/audio/white_noise.mp3',
      };
}

@immutable
class AmbientAudioState {
  const AmbientAudioState({
    required this.sound,
    required this.isPlaying,
  });

  final AmbientSound sound;
  final bool isPlaying;
}

abstract class AmbientAudioService {
  AmbientSound get currentSound;
  bool get isPlaying;
  Stream<AmbientAudioState> watchState();

  Future<void> init();
  Future<void> selectSound(AmbientSound sound, {bool autoPlay = true});
  Future<void> togglePlay();
  Future<void> stop();
  Future<void> playChime();
  Future<void> dispose();
}

class _StudySpaceAudioHandler extends BaseAudioHandler {
  _StudySpaceAudioHandler(this._player, this._onPlayingChanged);

  final AudioPlayer _player;
  final void Function(bool playing) _onPlayingChanged;

  Future<void> loadAsset(String assetPath, String title) async {
    mediaItem.add(
      MediaItem(
        id: assetPath,
        album: 'StudySpace Focus',
        title: title,
        artist: 'Ambient Sound',
      ),
    );
    await _player.setAsset(assetPath);
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(0.75);
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause, MediaControl.stop],
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
    _onPlayingChanged(true);
    await _player.play();
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play, MediaControl.stop],
        playing: false,
        processingState: AudioProcessingState.ready,
      ),
    );
    _onPlayingChanged(false);
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    _onPlayingChanged(false);
    await super.stop();
  }
}

class BackgroundAmbientAudioService implements AmbientAudioService {
  final _controller = StreamController<AmbientAudioState>.broadcast();
  AudioPlayer? _ambientPlayer;
  AudioPlayer? _chimePlayer;
  _StudySpaceAudioHandler? _handler;
  AmbientSound _currentSound = AmbientSound.rain;
  bool _isPlaying = false;
  bool _initialized = false;

  @override
  AmbientSound get currentSound => _currentSound;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<AmbientAudioState> watchState() => _controller.stream;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(AmbientAudioState(sound: _currentSound, isPlaying: _isPlaying));
    }
  }

  @override
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      _ambientPlayer = AudioPlayer();
      _chimePlayer = AudioPlayer(handleAudioSessionActivation: false);
      _handler = await AudioService.init(
        builder: () => _StudySpaceAudioHandler(_ambientPlayer!, (playing) {
          if (_isPlaying != playing) {
            _isPlaying = playing;
            _emit();
          }
        }),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.studyspace.studyspace.ambient',
          androidNotificationChannelName: 'StudySpace Ambient Sound',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Fallback safely on non-mobile test hosts.
    }
  }

  @override
  Future<void> selectSound(AmbientSound sound, {bool autoPlay = true}) async {
    _currentSound = sound;
    if (sound == AmbientSound.off) {
      await stop();
      return;
    }
    if (!_initialized) await init();
    try {
      final path = sound.assetPath!;
      if (_handler != null) {
        await _handler!.loadAsset(path, '${sound.label} · Focus');
        if (autoPlay) {
          await _handler!.play();
          _isPlaying = true;
        } else {
          _isPlaying = false;
        }
      } else if (_ambientPlayer != null) {
        await _ambientPlayer!.setAsset(path);
        await _ambientPlayer!.setLoopMode(LoopMode.one);
        if (autoPlay) {
          await _ambientPlayer!.play();
          _isPlaying = true;
        } else {
          _isPlaying = false;
        }
      }
    } catch (_) {
      _isPlaying = false;
    }
    _emit();
  }

  @override
  Future<void> togglePlay() async {
    if (_currentSound == AmbientSound.off) {
      await selectSound(AmbientSound.rain, autoPlay: true);
      return;
    }
    if (_isPlaying) {
      try {
        await _handler?.pause();
        if (_handler == null) await _ambientPlayer?.pause();
      } catch (_) {}
      _isPlaying = false;
      _emit();
    } else {
      await selectSound(_currentSound, autoPlay: true);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _handler?.stop();
      if (_handler == null) await _ambientPlayer?.stop();
    } catch (_) {}
    _isPlaying = false;
    _emit();
  }

  @override
  Future<void> playChime() async {
    try {
      _chimePlayer ??= AudioPlayer(handleAudioSessionActivation: false);
      await _chimePlayer!.setAsset('assets/audio/chime.mp3');
      await _chimePlayer!.setVolume(0.8);
      unawaited(_chimePlayer!.play());
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _ambientPlayer?.dispose();
    await _chimePlayer?.dispose();
    await _controller.close();
  }
}

final ambientAudioServiceProvider = Provider<AmbientAudioService>((ref) {
  final service = BackgroundAmbientAudioService();
  ref.onDispose(service.dispose);
  return service;
});
