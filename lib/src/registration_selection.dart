import 'package:flutter/material.dart';
import 'package:habl/src/signup.dart';

class Registration extends StatelessWidget {
  const Registration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
                '동호회 세상에 \n오신 것을 환영해요🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )),
        body: Column(
          children: [
            SizedBox(width: 20,height: 5),
            Text("당신에게 맞는 타입을 선택하고 즐겁게 활동해보세요.",
            style: TextStyle(color: Colors.grey),), 
            SizedBox(width: 20,height: 5),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              ElevatedButton.icon(
              onPressed: () {Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Signup()),
                  );},
              icon: const Icon(Icons.person),
              label: const Text('동호회 회원으로 가입하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), 
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () { 
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const Signup()),
                  );},
              icon: const Icon(Icons.star),
              label: const Text('동호회 회장으로 가입하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), 
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
            crossAxisAlignment: CrossAxisAlignment.start, // 여러 줄일 때 아이콘을 첫 줄에 맞춤
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(                                   // 글자가 길어도 자동 줄바꿈
                child: Text(
                  '어느 쪽을 선택해도 모임 활동은 자유롭게 시작할 수 있으니 부담 없이 골라보세요!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
              ),
            ],
          ),
           ],
          ),
          ),
          ],
        ),
    );
  }
}