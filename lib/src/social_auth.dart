import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'auth.dart';

// 프로젝트 루트의 dart_defines.json 에서 읽습니다 (--dart-define-from-file)
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000', // 안드로이드 에뮬레이터에서 본 내 PC
);
const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

enum SocialProvider {
  kakao('KAKAO', '카카오');

  const SocialProvider(this.code, this.label);
  final String code;
  final String label;
}

// 사용자가 로그인 창을 닫았을 때 (에러 메시지를 띄우지 않음)
class SocialLoginCanceled implements Exception {}

class SocialAuthException implements Exception {
  final String message;
  SocialAuthException(this.message);

  @override
  String toString() => message;
}

// 아직 가입하지 않은 소셜 사용자 정보 — 가입 화면으로 넘겨서 사용
class PendingSocialSignup {
  final SocialProvider provider;
  final String token;
  final String? name;
  final String? email;

  const PendingSocialSignup({
    required this.provider,
    required this.token,
    this.name,
    this.email,
  });
}

void initSocialAuth() {
  if (kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }
}

Future<String> _kakaoAccessToken() async {
  if (kakaoNativeAppKey.isEmpty) {
    throw SocialAuthException('카카오 앱 키가 설정되지 않았습니다.');
  }
  try {
    if (await isKakaoTalkInstalled()) {
      try {
        return (await UserApi.instance.loginWithKakaoTalk()).accessToken;
      } on PlatformException catch (e) {
        if (e.code == 'CANCELED') rethrow;
        // 카카오톡에 연결된 계정이 없으면 카카오계정으로 로그인
      }
    }
    return (await UserApi.instance.loginWithKakaoAccount()).accessToken;
  } on PlatformException catch (e) {
    if (e.code == 'CANCELED') throw SocialLoginCanceled();
    throw SocialAuthException('카카오 로그인에 실패했습니다.');
  }
}

Future<Map<String, dynamic>> _post(
  String path,
  Map<String, dynamic> body,
) async {
  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse('$apiBaseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  } catch (_) {
    throw SocialAuthException('서버에 연결할 수 없습니다.');
  }

  Map<String, dynamic> data;
  try {
    data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  } catch (_) {
    data = {};
  }
  if (response.statusCode >= 400) {
    throw SocialAuthException(
      data['message'] as String? ?? '요청을 처리하지 못했습니다.',
    );
  }
  return data;
}

void _completeLogin(Map<String, dynamic> data) {
  authToken = data['token'] as String;
  isLoggedIn.value = true;
}

// 소셜 로그인. 이미 가입된 사용자면 로그인 처리 후 null,
// 처음 온 사용자면 가입에 필요한 정보를 돌려줍니다.
Future<PendingSocialSignup?> signInWithSocial(SocialProvider provider) async {
  final token = switch (provider) {
    SocialProvider.kakao => await _kakaoAccessToken(),
  };
  final data = await _post('/auth/social/login', {
    'provider': provider.code,
    'token': token,
  });

  if (data['needsSignup'] == true) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    return PendingSocialSignup(
      provider: provider,
      token: token,
      name: profile['name'] as String?,
      email: profile['email'] as String?,
    );
  }
  _completeLogin(data);
  return null;
}

// 처음 온 소셜 사용자를 회원(MEMBER) 또는 회장(LEADER)으로 가입시킵니다
Future<void> completeSocialSignup(
  PendingSocialSignup pending, {
  required String role,
  required String name,
  required String phoneNumber,
}) async {
  final data = await _post('/auth/social/signup', {
    'provider': pending.provider.code,
    'token': pending.token,
    'role': role,
    'name': name,
    'phoneNumber': phoneNumber,
  });
  _completeLogin(data);
}
