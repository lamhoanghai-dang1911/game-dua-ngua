import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/horse_model.dart';
import '../models/bet_model.dart';
import '../models/race_result_model.dart';
import '../widgets/race_rider_canvas.dart';
import '../widgets/race_track_canvas.dart';
import 'result_screen.dart';

/// ============================================================================
/// MODULE 4: MÀN HÌNH 2 - RACE SCREEN (MÔ PHỎNG ĐƯỜNG ĐUA)
/// - Không sử dụng Slider mặc định.
/// - Đường đua được vẽ bằng CustomPaint/Canvas, gồm 3 làn và 3 ngựa.
/// - Vị trí ngựa được cập nhật bằng progress + setState.
/// - Áp dụng Dart Async & Control Flow: Timer.periodic, Random, if/else.
/// - Đảm bảo dọn dẹp tài nguyên với dispose() để tránh rò rỉ bộ nhớ.
/// ============================================================================
class RaceScreen extends StatefulWidget {
  final List<Horse> horses;
  final List<Bet> bets;
  final int initialBalance;

  const RaceScreen({
    super.key,
    required this.horses,
    required this.bets,
    required this.initialBalance,
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> {
  static const double _raceDistanceMeters = 250;

  // Trạng thái tiến độ đua của từng ngựa (0.0 -> 1.0)
  late Map<int, double> _progressMap;
  late Map<int, double> _speedMap;
  bool _isRiderView = false;
  bool _hasMountedRiderView = false;

  // Trạng thái cuộc đua
  bool _isRacing = false;
  bool _isFinished = false;
  Horse? _winnerHorse;

  // Timer điều khiển vòng lặp mô phỏng
  Timer? _raceTimer;
  Timer? _resultTimer;
  final Random _random = Random();
  int _stepTick = 0;
  bool _isExitDialogOpen = false;
  bool _isNavigatingToResult = false;
  bool _hasLeftRace = false;

  // Trạng thái đếm ngược xuất phát (3, 2, 1, RUN!)
  int _countdown = 0;
  Timer? _countdownTimer;
  Timer? _startSignalTimer;
  bool _showStartSignal = false;

  @override
  void initState() {
    super.initState();
    _resetTrack();
    _enterLandscapeMode();
  }

  Future<void> _enterLandscapeMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Khởi tạo lại vị trí xuất phát cho cả 3 ngựa
  void _resetTrack() {
    _progressMap = {for (var horse in widget.horses) horse.id: 0.0};
    _speedMap = {for (var horse in widget.horses) horse.id: 0.0};
    _isRacing = false;
    _isFinished = false;
    _winnerHorse = null;
    _stepTick = 0;
  }

  @override
  void dispose() {
    // HỦY TIMER BẮT BUỘC ĐỂ TRÁNH RÒ RỈ BỘ NHỚ
    _raceTimer?.cancel();
    _countdownTimer?.cancel();
    _startSignalTimer?.cancel();
    _resultTimer?.cancel();
    _restorePortraitMode();
    super.dispose();
  }

  /// Bắt đầu đếm ngược rồi xuất phát
  void _startCountdown() {
    if (_isRacing || _isFinished || _countdown > 0) return;

    _startSignalTimer?.cancel();
    setState(() {
      _countdown = 3;
      _showStartSignal = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isExitDialogOpen) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _showStartSignal = true;
        });
        _launchRace();
        _startSignalTimer = Timer(const Duration(milliseconds: 720), () {
          if (!mounted) return;
          setState(() => _showStartSignal = false);
        });
      }
    });
  }

  /// Kích hoạt Timer chạy đua cho các chiến mã
  void _launchRace() {
    setState(() {
      _isRacing = true;
    });

    // Mỗi chu kỳ tick 70ms, các ngựa sẽ di chuyển một bước nhỏ hơn để cuộc đua kéo dài ~15 giây
    _raceTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isExitDialogOpen) return;

      setState(() {
        _stepTick++;
        Horse? localWinner;
        double earliestFinish = double.infinity;

        for (var horse in widget.horses) {
          final currentProgress = _progressMap[horse.id] ?? 0.0;

          // Giảm vận tốc trung bình để thời gian đua thực tế kéo dài khoảng 15 giây.
          // Base step dao động nhỏ để cuộc đua vẫn kịch tính nhưng không kết thúc quá nhanh.
          double step = 0.0025 + _random.nextDouble() * 0.0040;

          // Mỗi ngựa có một nhịp bứt tốc nhỏ, tự nhiên hơn so với bản cũ.
          if (_random.nextDouble() < 0.12) {
            step += 0.0015;
          }

          // Tạo sai khác nhẹ giữa 3 làn để cuộc đua nhìn thật hơn.
          step += (horse.id * 0.00012);

          // Ở đoạn cuối, ngựa có thể rướn nhẹ để tạo cảm giác sprint về đích.
          if (currentProgress > 0.82) {
            step += 0.0009;
          }

          final newProgress = currentProgress + step;
          final travelled = newProgress.clamp(0.0, 1.0) - currentProgress;
          final measuredSpeed = travelled * _raceDistanceMeters / 0.07 * 3.6;
          final previousSpeed = _speedMap[horse.id] ?? 0.0;
          _speedMap[horse.id] =
              previousSpeed + (measuredSpeed - previousSpeed) * 0.18;

          if (newProgress >= 1.0) {
            _progressMap[horse.id] = 1.0;
            // So sánh thời điểm vượt đích trong cùng tick, tránh ưu tiên làn đầu.
            final finishFraction = (1.0 - currentProgress) / step;
            if (finishFraction < earliestFinish) {
              earliestFinish = finishFraction;
              localWinner = horse;
            }
          } else {
            _progressMap[horse.id] = newProgress;
          }
        }

        // Nếu đã có ngựa cán đích
        if (localWinner != null && !_isFinished) {
          _isFinished = true;
          _isRacing = false;
          _winnerHorse = localWinner;
          _raceTimer?.cancel();

          // Chờ thêm một chút để người chơi nhìn rõ khoảnh khắc cán đích rồi chuyển sang ResultScreen
          _resultTimer = Timer(
            const Duration(milliseconds: 1400),
            _navigateToResultScreen,
          );
        }
      });
    });
  }

  /// Điều hướng sang Màn hình kết quả
  Future<void> _navigateToResultScreen() async {
    if (!mounted ||
        _hasLeftRace ||
        _winnerHorse == null ||
        _isExitDialogOpen ||
        _isNavigatingToResult) {
      return;
    }
    setState(() {
      _isNavigatingToResult = true;
    });
    _resultTimer?.cancel();

    final result = RaceResult(
      winnerHorse: _winnerHorse!,
      allHorses: widget.horses,
      bets: widget.bets,
      startingBalance: widget.initialBalance,
    );

    // Màn kết quả dùng giao diện dọc như HomeScreen.
    await _restorePortraitMode();
    if (!mounted || _hasLeftRace) return;

    // Chuyển sang ResultScreen
    final updatedBalance = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(raceResult: result)),
    );

    if (!mounted) return;

    // Khi người chơi chọn "Chơi tiếp" hoặc "Về trang chủ", pop trả số dư mới về HomeBettingScreen
    if (updatedBalance != null) {
      Navigator.pop(context, updatedBalance);
    } else {
      // Nếu người dùng bấm Back từ ResultScreen thì quay lại đường đua ngang.
      await _enterLandscapeMode();
      if (!mounted) return;
      setState(() {
        _isNavigatingToResult = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<int>(
      canPop: !_isRacing && _countdown == 0 && !_isNavigatingToResult,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _hasLeftRace = true;
          _countdownTimer?.cancel();
          _startSignalTimer?.cancel();
          _raceTimer?.cancel();
          _resultTimer?.cancel();
        } else {
          _handleExitRequested();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF10151B),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxHeight < 500 &&
                  constraints.maxWidth > constraints.maxHeight;
              return Column(
                children: [
                  _buildRaceHeader(compact: compact),
                  if (!compact) _buildStatusHeader(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 6 : 10,
                        compact ? 0 : 6,
                        compact ? 6 : 10,
                        compact ? 0 : 6,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          IndexedStack(
                            index: _isRiderView ? 1 : 0,
                            sizing: StackFit.expand,
                            children: [
                              TickerMode(
                                enabled: !_isRiderView,
                                child: RaceTrackCanvas(
                                  horses: widget.horses,
                                  progressMap: Map<int, double>.from(
                                    _progressMap,
                                  ),
                                  winnerHorseId: _winnerHorse?.id,
                                  isRacing:
                                      _isRacing &&
                                      !_isExitDialogOpen &&
                                      !_isRiderView,
                                  stepTick: _stepTick,
                                  countdown: _countdown,
                                ),
                              ),
                              if (_hasMountedRiderView)
                                TickerMode(
                                  enabled: _isRiderView,
                                  child: RaceRiderCanvas(
                                    horses: widget.horses,
                                    progressMap: Map<int, double>.from(
                                      _progressMap,
                                    ),
                                    speedMap: Map<int, double>.from(_speedMap),
                                    raceDistanceMeters: _raceDistanceMeters,
                                    winnerHorseId: _winnerHorse?.id,
                                    isRacing:
                                        _isRacing &&
                                        !_isExitDialogOpen &&
                                        _isRiderView,
                                    stepTick: _stepTick,
                                    countdown: _countdown,
                                  ),
                                ),
                            ],
                          ),
                          _RaceStartOverlay(
                            countdown: _countdown,
                            showGo: _showStartSignal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomControls(compact: compact),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRaceHeader({required bool compact}) {
    return Container(
      height: compact ? 54 : 62,
      margin: EdgeInsets.fromLTRB(8, 6, 8, compact ? 4 : 0),
      padding: const EdgeInsets.only(left: 7, right: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF21B222B), Color(0xF20B1016)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x24FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x52000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x18E2BC70),
            blurRadius: 18,
            offset: Offset(-8, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showTime = compact && constraints.maxWidth >= 580;
          final showLap = compact && constraints.maxWidth >= 780;
          final showBet = compact && constraints.maxWidth >= 1020;
          final narrow = constraints.maxWidth < 460;

          final children = <Widget>[
            IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              color: const Color(0xFFEBE7DF),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x12FFFFFF),
                side: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              onPressed: _isNavigatingToResult ? null : _handleExitRequested,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 540
                    ? constraints.maxWidth * 0.24
                    : 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isRiderView ? 'GÓC NHÌN KỴ SĨ' : 'ĐƯỜNG ĐUA TRỰC TIẾP',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFFF4F0E7),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildLiveStatus(),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: _buildViewSwitcher(narrow: narrow),
            ),
          ];

          if (showLap) {
            children.addAll([
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 70),
                child: _buildMetric(
                  label: 'VÒNG ĐUA',
                  value: '1 / 1',
                  icon: Icons.route_rounded,
                ),
              ),
            ]);
          }

          if (showTime) {
            children.addAll([
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: _buildMetric(
                  label: 'THỜI GIAN',
                  value: _elapsedTime,
                  icon: Icons.timer_outlined,
                ),
              ),
            ]);
          }

          if (showBet) {
            children.addAll([
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: _buildMetric(
                  label: 'TỔNG CƯỢC',
                  value:
                      '${widget.bets.fold<int>(0, (s, b) => s + b.amount)} xu',
                  icon: Icons.stars_rounded,
                  accent: true,
                ),
              ),
            ]);
          }

          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: children,
          );
        },
      ),
    );
  }

  Widget _buildViewSwitcher({required bool narrow}) {
    return Container(
      width: narrow ? 136 : 180,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xA8080D12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _isRiderView
                ? Alignment.centerRight
                : Alignment.centerLeft,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF2D18B), Color(0xFFC99746)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3DE2B866), blurRadius: 10),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildViewOption(
                rider: false,
                label: 'Góc ngang',
                icon: Icons.panorama_wide_angle_outlined,
                showIcon: !narrow,
              ),
              _buildViewOption(
                rider: true,
                label: 'Kỵ sĩ',
                icon: Icons.sports_motorsports_outlined,
                showIcon: !narrow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewOption({
    required bool rider,
    required String label,
    required IconData icon,
    required bool showIcon,
  }) {
    final selected = _isRiderView == rider;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            key: ValueKey(rider ? 'race-view-rider' : 'race-view-side'),
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              if (_isRiderView == rider) return;
              setState(() {
                _isRiderView = rider;
                if (rider) _hasMountedRiderView = true;
              });
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showIcon) ...[
                      Icon(
                        icon,
                        size: 15,
                        color: selected
                            ? const Color(0xFF272116)
                            : const Color(0xFFB8B8B1),
                      ),
                      const SizedBox(width: 4),
                    ],
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF241D12)
                            : const Color(0xFFB8B8B1),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStatus() {
    final status = _isFinished
        ? 'Đã về đích'
        : (_isRacing
              ? 'Đang tranh tài'
              : (_countdown > 0 ? 'Chuẩn bị xuất phát' : 'Sẵn sàng xuất phát'));
    final active = _isRacing || _countdown > 0;
    final statusColor = _isFinished
        ? const Color(0xFFF0C979)
        : active
        ? const Color(0xFF63E6A8)
        : const Color(0xFF91A0AB);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 2,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeInOut,
          width: active && _stepTick % 18 < 9 ? 8 : 6,
          height: active && _stepTick % 18 < 9 ? 8 : 6,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: active ? 0.55 : 0.2),
                blurRadius: active ? 9 : 4,
              ),
            ],
          ),
        ),
        Text(
          active ? 'LIVE' : 'GRID',
          style: TextStyle(
            color: statusColor,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFADB0B0), fontSize: 9),
          ),
        ),
      ],
    );
  }

  // Đồng bộ đồng hồ HUD với thời gian mô phỏng 70 ms của mỗi bước đua.
  String get _elapsedTime {
    final milliseconds = _stepTick * 70;
    final minutes = milliseconds ~/ 60000;
    final seconds = (milliseconds ~/ 1000) % 60;
    final hundredths = (milliseconds ~/ 10) % 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    bool accent = false,
  }) {
    final highlight = accent
        ? const Color(0xFFE5BE70)
        : const Color(0xFFAEB8C0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: 40,
      padding: const EdgeInsets.fromLTRB(7, 4, 10, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: accent
              ? const [Color(0x302F2516), Color(0x1810151B)]
              : const [Color(0x241D252C), Color(0x1210151B)],
        ),
        border: Border.all(color: highlight.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showIcon = constraints.maxWidth >= 88;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: highlight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: highlight),
                ),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF8F989F),
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          color: accent
                              ? const Color(0xFFE6C47E)
                              : const Color(0xFFF0EDE6),
                          fontSize: 13,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final children = <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: _buildMetric(
                label: 'VÒNG ĐUA',
                value: '1 / 1',
                icon: Icons.route_rounded,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: _buildMetric(
                label: 'THỜI GIAN',
                value: _elapsedTime,
                icon: Icons.timer_outlined,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: _buildMetric(
                label: 'TỔNG CƯỢC',
                value: '${widget.bets.fold<int>(0, (s, b) => s + b.amount)} xu',
                icon: Icons.stars_rounded,
                accent: true,
              ),
            ),
          ];

          return Wrap(spacing: 8, runSpacing: 8, children: children);
        },
      ),
    );
  }

  /// Nút bấm điều khiển: Xuất phát, Xem kết quả
  Widget _buildBottomControls({required bool compact}) {
    final actionEnabled =
        !_isNavigatingToResult && (_isFinished || _countdown == 0);
    final button = SizedBox(
      height: 46,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: _isRacing
            ? Container(
                key: const ValueKey('race-running-action'),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF202A27), Color(0xFF151B1B)],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: const Color(0x3A72D9A9)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1E72D9A9), blurRadius: 14),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF72D9A9),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ĐANG TRANH TÀI',
                      style: TextStyle(
                        color: Color(0xFFD9F5E7),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              )
            : DecoratedBox(
                key: ValueKey(
                  _isFinished ? 'race-result-action' : 'race-start-action',
                ),
                decoration: BoxDecoration(
                  gradient: actionEnabled
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF1D394), Color(0xFFC99543)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF494637), Color(0xFF302F28)],
                        ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: actionEnabled
                      ? const [
                          BoxShadow(
                            color: Color(0x36E2B866),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton.icon(
                  onPressed: _isNavigatingToResult
                      ? null
                      : _isFinished
                      ? _navigateToResultScreen
                      : (_countdown == 0 ? _startCountdown : null),
                  icon: Icon(
                    _isFinished
                        ? Icons.emoji_events_rounded
                        : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  label: Text(
                    _isFinished
                        ? 'XEM KẾT QUẢ'
                        : (_countdown > 0
                              ? 'XUẤT PHÁT SAU $_countdown'
                              : 'BẮT ĐẦU ĐUA'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: const Color(0xFF211B12),
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: const Color(0xFFE2D3AF),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                ),
              ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF21A2129), Color(0xF20C1117)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x20FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4A000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (compact && constraints.maxWidth >= 430) {
              final progressWidth = (constraints.maxWidth - 24 - 202).clamp(
                160.0,
                double.infinity,
              );
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  SizedBox(width: progressWidth, child: _buildRaceProgress()),
                  const SizedBox(width: 24),
                  SizedBox(width: 202, child: button),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRaceProgress(),
                const SizedBox(height: 10),
                button,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRaceProgress() {
    final progress = _progressMap.values.fold<double>(0, max).clamp(0.0, 1.0);
    return Semantics(
      label: 'Tiến độ ngựa dẫn đầu',
      value: '${(progress * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VẠCH XUẤT PHÁT',
                style: TextStyle(
                  color: Color(0xFF8F999F),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${(progress * 100).round()}%  •  VỀ ĐÍCH',
                style: TextStyle(
                  color: progress >= 1
                      ? const Color(0xFF75E0AC)
                      : const Color(0xFFE0BF79),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final railWidth = max(0.0, constraints.maxWidth - 18);
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, visualProgress, _) => SizedBox(
                  height: 18,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 9,
                        right: 9,
                        top: 7,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF343C42),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x4A000000),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 9,
                        width: railWidth * visualProgress,
                        top: 7,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8D6C34), Color(0xFFF0CF87)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x42E3BD71),
                                blurRadius: 7,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: railWidth * visualProgress,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3D794), Color(0xFFC38A37)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF282116),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x70E3BD71),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.sports_score_rounded,
                            size: 10,
                            color: Color(0xFF2B2318),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Hộp thoại xác nhận nếu muốn thoát khi đang đua dở
  void _handleExitRequested() {
    if (!mounted ||
        _hasLeftRace ||
        _isNavigatingToResult ||
        _isExitDialogOpen) {
      return;
    }
    if (_isRacing || _countdown > 0) {
      _showExitConfirmDialog();
    } else {
      _resultTimer?.cancel();
      Navigator.pop(context);
    }
  }

  Future<void> _showExitConfirmDialog() async {
    if (_isExitDialogOpen || !mounted) return;
    setState(() {
      _isExitDialogOpen = true;
    });
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Hủy cuộc đua?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cuộc đua đang diễn ra. Nếu rời khỏi màn hình bây giờ, kết quả vòng này sẽ bị hủy bỏ.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Ở lại',
              style: TextStyle(color: Color(0xFF38BDF8)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Rời đi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldLeave == true) {
      _countdownTimer?.cancel();
      _startSignalTimer?.cancel();
      _raceTimer?.cancel();
      _resultTimer?.cancel();
      Navigator.pop(context);
    } else {
      setState(() {
        _isExitDialogOpen = false;
      });
    }
  }
}

class _RaceStartOverlay extends StatelessWidget {
  final int countdown;
  final bool showGo;

  const _RaceStartOverlay({required this.countdown, required this.showGo});

  @override
  Widget build(BuildContext context) {
    final visible = countdown > 0 || showGo;
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: visible
            ? _RaceStartMoment(
                key: ValueKey(showGo ? 'go' : countdown),
                countdown: countdown,
                showGo: showGo,
              )
            : const SizedBox.expand(key: ValueKey('start-overlay-idle')),
      ),
    );
  }
}

class _RaceStartMoment extends StatelessWidget {
  final int countdown;
  final bool showGo;

  const _RaceStartMoment({
    super.key,
    required this.countdown,
    required this.showGo,
  });

  @override
  Widget build(BuildContext context) {
    final signalColor = showGo
        ? const Color(0xFF70E7AD)
        : const Color(0xFFF0C975);
    return Semantics(
      liveRegion: true,
      label: showGo ? 'Xuất phát' : 'Xuất phát sau $countdown',
      child: ColoredBox(
        color: const Color(0x72050A0F),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dialSize = min(
              constraints.maxHeight < 230 ? 116.0 : 154.0,
              constraints.maxHeight * 0.52,
            );
            return Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(showGo ? 'go-motion' : 'countdown-$countdown'),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: showGo ? 680 : 900),
                curve: Curves.linear,
                builder: (context, progress, child) {
                  final entrance = Curves.easeOutBack.transform(
                    (progress * 2.5).clamp(0.0, 1.0),
                  );
                  return Transform.scale(
                    scale: 0.78 + entrance * 0.22,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: dialSize,
                      height: dialSize,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(
                          showGo ? 'go-ring' : 'countdown-ring-$countdown',
                        ),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: showGo ? 680 : 900),
                        builder: (context, progress, _) => CustomPaint(
                          painter: _StartDialPainter(
                            progress: progress,
                            color: signalColor,
                            expanding: showGo,
                          ),
                          child: Center(
                            child: Container(
                              width: dialSize * 0.72,
                              height: dialSize * 0.72,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    signalColor.withValues(alpha: 0.2),
                                    const Color(0xE60D141A),
                                  ],
                                ),
                                border: Border.all(
                                  color: signalColor.withValues(alpha: 0.28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: signalColor.withValues(alpha: 0.2),
                                    blurRadius: 24,
                                  ),
                                ],
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    showGo ? 'GO!' : '$countdown',
                                    style: TextStyle(
                                      color: showGo
                                          ? const Color(0xFFF0FFF7)
                                          : const Color(0xFFFFF6DE),
                                      fontSize: showGo ? 44 : 62,
                                      height: 0.95,
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      shadows: [
                                        Shadow(
                                          color: signalColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight < 230 ? 7 : 11),
                    _StartingLights(countdown: countdown, showGo: showGo),
                    const SizedBox(height: 7),
                    Text(
                      showGo ? 'XUẤT PHÁT' : 'GIỮ NHỊP • SẴN SÀNG',
                      style: TextStyle(
                        color: showGo
                            ? const Color(0xFFE7FFF2)
                            : const Color(0xFFD9DFE2),
                        fontSize: constraints.maxHeight < 230 ? 8 : 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StartingLights extends StatelessWidget {
  final int countdown;
  final bool showGo;

  const _StartingLights({required this.countdown, required this.showGo});

  @override
  Widget build(BuildContext context) {
    final activeLights = showGo ? 3 : (4 - countdown).clamp(1, 3);
    const colors = [Color(0xFFF16F69), Color(0xFFF2C66E), Color(0xFF70E7AD)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final active = index < activeLights;
        final color = showGo ? colors.last : colors[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          width: active ? 9 : 7,
          height: active ? 9 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : const Color(0xFF45515A),
            border: Border.all(color: const Color(0x42FFFFFF)),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.72),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _StartDialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool expanding;

  const _StartDialPainter({
    required this.progress,
    required this.color,
    required this.expanding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 - 7;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x42FFFFFF),
    );

    final arcProgress = expanding ? progress : 1 - progress;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.25), color, color],
      ).createShader(rect);
    canvas.drawArc(rect, -pi / 2, pi * 2 * arcProgress, false, arcPaint);

    canvas.drawArc(
      rect,
      -pi / 2,
      pi * 2 * arcProgress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  @override
  bool shouldRepaint(covariant _StartDialPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      expanding != oldDelegate.expanding;
}
