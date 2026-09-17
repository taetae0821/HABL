import 'package:flutter/material.dart';

class ClubPromotionPage extends StatelessWidget {
  const ClubPromotionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==========================================
            // 1. 상단 이미지 + 아이콘 버튼 (작성하신 영역)
            // ==========================================
            Stack(
              children: [
                // 배경 이미지
                Image.asset(
                  'assets/badminton_img.png',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),

                // 왼쪽 뒤로가기 버튼
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                    ),
                  ),
                ),

                // 오른쪽 공유 버튼
                Positioned(
                  top: 40,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: IconButton(
                      icon: const Icon(Icons.ios_share, color: Colors.black),
                      onPressed: () {
                        // 공유 기능 동작
                      },
                    ),
                  ),
                ),
              ],
            ),

            // ==========================================
            // 2. 하단 텍스트 영역 (새로 추가되는 부분)
            // ==========================================
            Transform.translate(
              offset: const Offset(0, -20), // 이미지를 살짝 덮도록 위로 20px 올림
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,

                  // 이미지와 맞닿는 윗쪽 모서리를 둥글게 처리
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
                  children: [
                    // ① 태그 (성동구 대표 배드민턴 클럽)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEFF), // 연보라색 배경
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '성동구 대표 배드민턴 클럽',
                        style: TextStyle(
                          color: Color(0xFF4A4EED),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // 간격
                    // ② 큰 제목 (스매시 파크 성동 🏸)
                    const Text(
                      '스매시 파크 성동 🏸',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16), // 간격
                    // ③ 본문 설명글
                    const Text(
                      '함께 땀 흘리며 스트레스를 날릴 동료들을 찾습니다! 초보부터 실력자까지 어우러져 편안한 분위기에서 즐기는 모임입니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5, // 줄간격 넓히기
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
