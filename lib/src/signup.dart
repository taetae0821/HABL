import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정만들기'),
      ),
      body: Column(
        children: [
          TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: '이름을 입력하세요',
          ),
        ),
        SafeArea(child: Text('이메일'),),
         TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: '이메일주소',
          ),
        ),
        ],
      )
    );
  }
}