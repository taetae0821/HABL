import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'src/Formclub.dart';
import 'src/kakao_config.dart';

void main() {
  AuthRepository.initialize(appKey: kakaoJavaScriptKey);
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Formclub(),
    );
  }
}
