import 'package:flutter/material.dart';
import 'page2.dart'; // Đảm bảo bạn tạo file này

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: InkWell( // Sử dụng InkWell để bắt sự kiện nhấn toàn màn hình
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Page2()),
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Đánh dấu',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '3 trang đã lưu',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildBookmarkItem('📄', 'Trang 42 — Toán Cao Cấp', 'Công thức tích phân từng phần'),
                      _buildBookmarkItem('📑', 'Chương 5 — Vật Lý', 'Định luật Newton'),
                      _buildBookmarkItem('📝', 'Bài 12 — Hóa Hữu Cơ', 'Phản ứng este hóa'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget con để hiển thị từng dòng đánh dấu
  Widget _buildBookmarkItem(String icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          const Text('🔖', style: TextStyle(fontSize: 18, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}