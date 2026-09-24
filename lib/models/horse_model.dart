import 'package:flutter/material.dart';

/// ============================================================================
/// MODULE 2 & 3: DART ESSENTIALS & ADVANCED OOP
/// Lớp Horse đại diện cho một đối tượng ngựa đua.
/// - Áp dụng tính đóng gói (Encapsulation) với các thuộc tính 'final'.
/// - Sử dụng Named Parameters và Constructor chuẩn trong Dart.
/// - Hỗ trợ copyWith để tạo đối tượng mới bất biến (Immutability).
/// ============================================================================
class Horse {
  final int id;
  final String name;
  final String nickname;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final double oddsMultiplier; // Tỷ lệ cược (ví dụ: 2.0 = 1 ăn 2)
  final double progress; // Tiến độ trên đường đua: 0.0 (xuất phát) -> 1.0 (về đích)

  const Horse({
    required this.id,
    required this.name,
    required this.nickname,
    required this.primaryColor,
    required this.secondaryColor,
    this.icon = Icons.pets,
    this.oddsMultiplier = 2.0,
    this.progress = 0.0,
  });

  /// Kiểm tra xem ngựa đã chạm đích chưa
  bool get hasFinished => progress >= 1.0;

  /// Tạo bản sao với giá trị progress mới trong lúc đua
  Horse copyWith({
    double? progress,
    double? oddsMultiplier,
  }) {
    return Horse(
      id: id,
      name: name,
      nickname: nickname,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      icon: icon,
      oddsMultiplier: oddsMultiplier ?? this.oddsMultiplier,
      progress: progress ?? this.progress,
    );
  }

  /// Danh sách 3 chiến mã mặc định cho cuộc đua
  static List<Horse> get defaultHorses => const [
        Horse(
          id: 1,
          name: 'Xích Thố',
          nickname: 'Tia Chớp Đỏ #1',
          primaryColor: Color(0xFFE53935), // Đỏ rực
          secondaryColor: Color(0xFFFF8A80),
          icon: Icons.flash_on_rounded,
          oddsMultiplier: 2.0,
        ),
        Horse(
          id: 2,
          name: 'Kim Mao',
          nickname: 'Bão Vàng Hoàng Kim #2',
          primaryColor: Color(0xFFF57F17), // Vàng hổ phách
          secondaryColor: Color(0xFFFFD54F),
          icon: Icons.military_tech_rounded,
          oddsMultiplier: 2.0,
        ),
        Horse(
          id: 3,
          name: 'Bạch Long',
          nickname: 'Cuồng Phong Xanh #3',
          primaryColor: Color(0xFF0288D1), // Xanh dương hoàng gia
          secondaryColor: Color(0xFF81D4FA),
          icon: Icons.air_rounded,
          oddsMultiplier: 2.0,
        ),
      ];
}
