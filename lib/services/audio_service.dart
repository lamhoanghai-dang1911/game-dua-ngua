import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// ============================================================================
/// AUDIO SERVICE: QUẢN LÝ TẬP TRUNG TOÀN BỘ ÂM THANH GAME ĐUA NGỰA
/// - Nhạc nền (BGM):
///   + Login & Register: Chow Yun Fat - God of Gamblers OST (loop)
///   + Home / Đặt cược & Deposit / Nạp tiền: background_music.mp3 (loop)
/// - Đường đua:
///   + Tiếng khán đài sân vận động: loop stadium_ambiance.mp3 trong suốt cuộc đua
///   + Tiếng đếm ngược xuất phát: stadium_crowd_start_race.mp3 reo 1 lần
///   + Tiếng vó ngựa chạy: loop horse_running.mp3 trong suốt quá trình ngựa chạy
/// - Đặt cược:
///   + money_sound.mp3 phát tức thì (0ms trễ) và KHÔNG ngắt BGM
/// - Kết thúc & Kết quả:
///   + crowd_cheering.mp3 reo lên 1 lần
/// ============================================================================
class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  // Các player riêng biệt cho từng luồng âm thanh
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _stadiumPlayer = AudioPlayer();
  final AudioPlayer _runningPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _betSoundPlayer = AudioPlayer();

  bool _isBgmPlaying = false;
  bool _isStadiumPlaying = false;
  bool _isRunningPlaying = false;
  bool _isMuted = false;

  bool get isMuted => _isMuted;
  bool get isBgmPlaying => _isBgmPlaying;
  bool get isStadiumPlaying => _isStadiumPlaying;
  bool get isRunningPlaying => _isRunningPlaying;

  String? _currentBgmTrack;

  // Đường dẫn tương đối từ thư mục assets/ (do AudioCache mặc định prefix là 'assets/')
  static const String loginBgmPath = 'sounds/god_of_gamblers.mp3';
  static const String mainBgmPath = 'sounds/background_music.mp3';
  static const String bgmPath = mainBgmPath;

  // File tiếng khán đài chuẩn không chứa khoảng trắng/dấu ngoặc
  static const String stadiumAmbiancePath = 'sounds/stadium_ambiance.mp3';
  static const String startRaceCrowdPath = 'sounds/stadium_crowd_start_race.mp3';
  static const String horseRunningPath = 'sounds/horse_running.mp3';
  static const String crowdCheeringPath = 'sounds/crowd_cheering.mp3';
  static const String moneySoundPath = 'sounds/money_sound.mp3';

  /// Khởi tạo ban đầu
  Future<void> init() async {
    try {
      // Cho phép phát đồng thời nhiều luồng âm thanh không bị gián đoạn hay ngắt tiếng nhau
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (e) {
      debugPrint('[AudioService] setAudioContext notice: $e');
    }

    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _stadiumPlayer.setReleaseMode(ReleaseMode.loop);
      await _runningPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _betSoundPlayer.setReleaseMode(ReleaseMode.release);

      // Đảm bảo loop liên tục không bị dừng khi hết file
      _stadiumPlayer.onPlayerComplete.listen((_) {
        if (_isStadiumPlaying && !_isMuted) {
          _stadiumPlayer.play(AssetSource(stadiumAmbiancePath));
        }
      });

      _runningPlayer.onPlayerComplete.listen((_) {
        if (_isRunningPlaying && !_isMuted) {
          _runningPlayer.play(AssetSource(horseRunningPath));
        }
      });
    } catch (e) {
      debugPrint('[AudioService] init error: $e');
    }
  }

  /// Bật / Tắt âm thanh
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    try {
      await _bgmPlayer.setVolume(muted ? 0.0 : 0.5);
      await _stadiumPlayer.setVolume(muted ? 0.0 : 0.95);
      await _runningPlayer.setVolume(muted ? 0.0 : 0.85);
      await _sfxPlayer.setVolume(muted ? 0.0 : 1.0);
      await _betSoundPlayer.setVolume(muted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('[AudioService] setMuted error: $e');
    }
  }

  /// 1a. Phát loop nhạc nền Chow Yun Fat - God of Gamblers OST cho LoginScreen & RegisterScreen
  Future<void> playLoginBgm() async {
    if (_isMuted) return;
    try {
      if (_isBgmPlaying &&
          _bgmPlayer.state == PlayerState.playing &&
          _currentBgmTrack == loginBgmPath) {
        return;
      }
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_isMuted ? 0.0 : 0.6);
      await _bgmPlayer.play(AssetSource(loginBgmPath));
      _isBgmPlaying = true;
      _currentBgmTrack = loginBgmPath;
    } catch (e) {
      debugPrint('[AudioService] playLoginBgm error: $e');
    }
  }

  /// 1b. Phát loop nhạc nền background_music.mp3 cho màn hình Đặt cược (Home) & Nạp tiền (Deposit)
  Future<void> playBgm() async {
    if (_isMuted) return;
    try {
      if (_isBgmPlaying &&
          _bgmPlayer.state == PlayerState.playing &&
          _currentBgmTrack == mainBgmPath) {
        return;
      }
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_isMuted ? 0.0 : 0.5);
      await _bgmPlayer.play(AssetSource(mainBgmPath));
      _isBgmPlaying = true;
      _currentBgmTrack = mainBgmPath;
    } catch (e) {
      debugPrint('[AudioService] playBgm error: $e');
    }
  }

  /// Dừng nhạc nền
  Future<void> stopBgm() async {
    try {
      if (_isBgmPlaying || _bgmPlayer.state == PlayerState.playing) {
        await _bgmPlayer.stop();
      }
      _isBgmPlaying = false;
      _currentBgmTrack = null;
    } catch (e) {
      debugPrint('[AudioService] stopBgm error: $e');
    }
  }

  /// 2. Vào trang cuộc đua -> Dừng BGM, loop tiếng sân vận động stadium_ambiance trong suốt cuộc đua
  Future<void> playStadiumAmbiance() async {
    if (_isBgmPlaying) {
      await stopBgm();
    }
    _isStadiumPlaying = true;
    if (_isMuted) return;
    try {
      if (_stadiumPlayer.state == PlayerState.playing) {
        await _stadiumPlayer.setVolume(_isMuted ? 0.0 : 0.95);
        return;
      }
      await _stadiumPlayer.setReleaseMode(ReleaseMode.loop);
      await _stadiumPlayer.setVolume(_isMuted ? 0.0 : 0.95);
      await _stadiumPlayer.play(AssetSource(stadiumAmbiancePath));
    } catch (e) {
      debugPrint('[AudioService] playStadiumAmbiance error: $e');
    }
  }

  /// Dừng tiếng sân vận động
  Future<void> stopStadiumAmbiance() async {
    try {
      _isStadiumPlaying = false;
      await _stadiumPlayer.stop();
    } catch (e) {
      debugPrint('[AudioService] stopStadiumAmbiance error: $e');
    }
  }

  /// 3a. Khi cuộc đua đếm ngược 3 2 1: stadium_crowd_start_race reo lên 1 lần
  Future<void> playStartRaceCrowd() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.setVolume(_isMuted ? 0.0 : 0.95);
      await _sfxPlayer.play(AssetSource(startRaceCrowdPath));

      // Đảm bảo tiếng khán đài sân vận động vẫn duy trì
      if (_isStadiumPlaying && _stadiumPlayer.state != PlayerState.playing) {
        await _stadiumPlayer.play(AssetSource(stadiumAmbiancePath));
      }
    } catch (e) {
      debugPrint('[AudioService] playStartRaceCrowd error: $e');
    }
  }

  /// 3b. Loop nhạc horse_running (tiếng vó ngựa) trong suốt quá trình ngựa chạy
  Future<void> startHorseRunning() async {
    _isRunningPlaying = true;
    if (_isMuted) return;
    try {
      if (_runningPlayer.state == PlayerState.playing) {
        await _runningPlayer.setVolume(_isMuted ? 0.0 : 0.85);
        return;
      }
      await _runningPlayer.setReleaseMode(ReleaseMode.loop);
      await _runningPlayer.setVolume(_isMuted ? 0.0 : 0.85);
      await _runningPlayer.play(AssetSource(horseRunningPath));
    } catch (e) {
      debugPrint('[AudioService] startHorseRunning error: $e');
    }
  }

  /// 3c. Phát song song tiếng khán đài sân vận động (stadium_ambiance) 
  /// và tiếng vó ngựa (horse_running) trong suốt quá trình ngựa chạy đua
  Future<void> startRaceRunningSounds() async {
    _isRunningPlaying = true;
    _isStadiumPlaying = true;
    if (_isMuted) return;

    try {
      // 1. Tiếng sân vận động stadium_ambiance (phát song song ở chế độ loop)
      await _stadiumPlayer.setReleaseMode(ReleaseMode.loop);
      await _stadiumPlayer.setVolume(_isMuted ? 0.0 : 0.95);
      if (_stadiumPlayer.state != PlayerState.playing) {
        await _stadiumPlayer.play(AssetSource(stadiumAmbiancePath));
      }

      // 2. Tiếng vó ngựa horse_running (phát song song ở chế độ loop)
      await _runningPlayer.setReleaseMode(ReleaseMode.loop);
      await _runningPlayer.setVolume(_isMuted ? 0.0 : 0.85);
      if (_runningPlayer.state != PlayerState.playing) {
        await _runningPlayer.play(AssetSource(horseRunningPath));
      }
    } catch (e) {
      debugPrint('[AudioService] startRaceRunningSounds error: $e');
    }
  }

  /// Dừng tiếng ngựa chạy
  Future<void> stopHorseRunning() async {
    try {
      _isRunningPlaying = false;
      await _runningPlayer.stop();
    } catch (e) {
      debugPrint('[AudioService] stopHorseRunning error: $e');
    }
  }

  /// 4. Khi kết thúc và hiện trang kết quả -> crowd_cheering reo lên 1 lần
  Future<void> playCrowdCheering() async {
    // Dừng tiếng vó ngựa
    await stopHorseRunning();
    // Dừng tiếng sân vận động nền để tiếng reo hò vinh danh nổi bật nhất
    await stopStadiumAmbiance();

    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.setVolume(_isMuted ? 0.0 : 1.0);
      await _sfxPlayer.play(AssetSource(crowdCheeringPath));
    } catch (e) {
      debugPrint('[AudioService] playCrowdCheering error: $e');
    }
  }

  /// 5. Phát âm thanh khi nạp xu / nhận tiền cứu trợ / nhận thưởng (money_sound.mp3)
  Future<void> playMoneySound() async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      await _sfxPlayer.setVolume(_isMuted ? 0.0 : 1.0);
      await _sfxPlayer.play(AssetSource(moneySoundPath));
    } catch (e) {
      debugPrint('[AudioService] playMoneySound error: $e');
    }
  }

  /// 6. Phát âm thanh khi user đặt cược vào con ngựa:
  /// - File money_sound.mp3 đã được tinh chỉnh bắt đầu ngay từ phần tiếng (loại bỏ đoạn im lặng ở đầu)
  /// - KHÔNG làm ngắt nhạc nền BGM
  Future<void> playBetMoneySound() async {
    if (_isMuted) return;
    try {
      await _betSoundPlayer.stop();
      await _betSoundPlayer.setReleaseMode(ReleaseMode.release);
      await _betSoundPlayer.setVolume(_isMuted ? 0.0 : 1.0);
      await _betSoundPlayer.play(AssetSource(moneySoundPath));

      // Đảm bảo nhạc nền BGM không bị ngắt hoặc tạm dừng khi đặt cược
      if (_isBgmPlaying && _bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.resume();
      }
    } catch (e) {
      debugPrint('[AudioService] playBetMoneySound error: $e');
    }
  }

  /// Dọn dẹp toàn bộ âm thanh cuộc đua khi rời RaceScreen
  Future<void> stopAllRaceSounds() async {
    await stopHorseRunning();
    await stopStadiumAmbiance();
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _bgmPlayer.dispose();
    _stadiumPlayer.dispose();
    _runningPlayer.dispose();
    _sfxPlayer.dispose();
    _betSoundPlayer.dispose();
  }
}
