import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// BONUS / SERVICE: PERSISTENCE WITH SHARED PREFERENCES
/// Quản lý việc lưu và đọc số dư tài khoản của người chơi.
/// Tích hợp cơ chế fallback an toàn: Nếu SharedPreferences gặp lỗi (ví dụ môi trường desktop thiếu symlink),
/// app sẽ tự động chuyển sang lưu trữ bộ nhớ tạm (In-memory) mà không bị gián đoạn hay crash.
/// ============================================================================
class StorageService {
  static const String _keyBalance = 'player_total_balance';
  static const int defaultInitialBalance = 100;

  // Bộ nhớ đệm fallback
  static int _memoryBalance = defaultInitialBalance;

  /// Đọc số dư từ bộ nhớ lưu trữ
  static Future<int> getBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final balance = prefs.getInt(_keyBalance);
      if (balance != null) {
        _memoryBalance = balance;
        return balance;
      }
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences read fallback to memory: $e');
    }
    return _memoryBalance;
  }

  /// Lưu số dư mới
  static Future<void> saveBalance(int balance) async {
    _memoryBalance = balance;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBalance, balance);
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences write fallback to memory: $e');
    }
  }

  /// Đặt lại số dư về mặc định (100 xu)
  static Future<int> resetBalance() async {
    _memoryBalance = defaultInitialBalance;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyBalance, defaultInitialBalance);
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences reset fallback to memory: $e');
    }
    return defaultInitialBalance;
  }
}
