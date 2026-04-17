import 'package:flutter/material.dart';
import 'page1.dart'; // Import file page1

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(), // Chỉnh lại theme sáng cho giống bản gốc
      home: const LibraryScreen(),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // GestureDetector giúp bắt sự kiện nhấn trên toàn bộ màn hình
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Page1()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Thư viện tài liệu',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '4 tài liệu · 12.5 MB',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildFileItem('📄', 'Tài liệu Toán Cao Cấp', 'PDF · 45 trang · 2.4 MB', 'PDF', '2 ngày trước'),
                      _buildFileItem('📑', 'Slide Vật Lý Đại Cương', 'PPTX · 120 trang · 8.1 MB', 'PPTX', '1 tuần trước'),
                      _buildFileItem('📝', 'Bài tập Hóa Hữu Cơ', 'DOCX · 30 trang · 1.2 MB', 'DOCX', '2 tuần trước'),
                      _buildFileItem('📄', 'Đề thi mẫu Sinh học', 'PDF · 10 trang · 0.8 MB', 'PDF', '3 tuần trước'),
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

  // Hàm helper để tạo item danh sách nhanh và sạch hơn
  Widget _buildFileItem(String icon, String title, String subtitle, String type, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475569))),
              Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }
}