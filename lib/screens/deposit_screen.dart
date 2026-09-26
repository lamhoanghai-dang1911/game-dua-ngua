import 'package:flutter/material.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  // Danh sách các gói nạp xu demo
  final List<Map<String, dynamic>> _depositPackages = [
    {'coins': 50, 'price': '20.000đ', 'badge': 'Cơ bản'},
    {'coins': 100, 'price': '50.000đ', 'badge': 'Phổ biến', 'isPopular': true},
    {'coins': 500, 'price': '200.000đ', 'badge': 'Đại gia'},
    {'coins': 1000, 'price': '350.000đ', 'badge': 'Siêu VIP', 'isVip': true},
  ];

  // Danh sách phương thức thanh toán demo
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'momo', 'name': 'Ví MoMo', 'icon': Icons.account_balance_wallet_rounded},
    {'id': 'vnpay', 'name': 'VNPAY QR', 'icon': Icons.qr_code_scanner_rounded},
    {'id': 'bank', 'name': 'Ngân hàng Nội địa (ATM)', 'icon': Icons.credit_card_rounded},
  ];

  int _selectedPackageIndex = 1; // Mặc định chọn gói 2
  String _selectedPaymentId = 'momo'; // Mặc định chọn MoMo

  @override
  Widget build(BuildContext context) {
    final selectedPackage = _depositPackages[_selectedPackageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text(
          'NẠP XU KHỞI NGHIỆP',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner giới thiệu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(76),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 40, color: Color(0xFFFBBF24)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ưu đãi nạp lần đầu x2',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nhận ngay thêm xu thưởng tương ứng khi thực hiện nạp tiền!',
                          style: TextStyle(fontSize: 12, color: Color(0xFFBFDBFE)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tiêu đề chọn gói
            const Text(
              '1. CHỌN GÓI NẠP XU',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Grid danh sách các gói nạp
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: _depositPackages.length,
              itemBuilder: (context, index) {
                final package = _depositPackages[index];
                final isSelected = _selectedPackageIndex == index;
                final isPopular = package['isPopular'] == true;
                final isVip = package['isVip'] == true;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPackageIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF151F32),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF334155),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on_rounded,
                                      color: Color(0xFFFBBF24), size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${package['coins']} Xu',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                package['price'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF4ADE80) : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge góc trên bên phải
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isVip
                                  ? const Color(0xFFEF4444)
                                  : isPopular
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              package['badge'],
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Tiêu đề phương thức thanh toán
            const Text(
              '2. PHƯƠNG THỨC THANH TOÁN',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Danh sách các phương thức thanh toán
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                final isSelected = _selectedPaymentId == method['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentId = method['id'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF151F32),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(method['icon'], color: isSelected ? const Color(0xFF38BDF8) : Colors.white70),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            method['name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white38,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Nút bấm xác nhận nạp tiền
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Chỉ mô phỏng lưu trữ thông báo thành công mà không gọi API thực tế
                  _showSuccessDialog(selectedPackage['coins']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'XÁC NHẬN THANH TOÁN - ${selectedPackage['price']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog thông báo nạp thành công mô phỏng
  void _showSuccessDialog(int coins) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Giao Dịch Thành Công!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Tài khoản của bạn đã được cộng thêm +$coins Xu vào số dư tạm thời.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Đóng dialog
                Navigator.pop(context, coins); // Quay lại trang trước và trả về số xu cộng thêm
              },
              child: const Text(
                'Tuyệt vời',
                style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
