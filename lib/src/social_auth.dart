import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'api_client.dart';
import 'auth_api.dart';

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

// 소셜 로그인. 이미 가입된 사용자면 로그인 처리 후 null,
// 처음 온 사용자면 가입에 필요한 정보를 돌려줍니다.
Future<PendingSocialSignup?> signInWithSocial(SocialProvider provider) async {
  final token = switch (provider) {
    SocialProvider.kakao => await _kakaoAccessToken(),
  };
  final data = await apiPost('/auth/social/login', {
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
  final loginToken = data['token'];
  if (loginToken is! String || loginToken.isEmpty) {
    throw SocialAuthException('로그인 응답에 토큰이 없습니다.');
  }
  await completeLogin(loginToken);
  return null;
}

// 처음 온 소셜 사용자를 회원(MEMBER) 또는 회장(LEADER)으로 가입시킵니다
Future<void> completeSocialSignup(
  PendingSocialSignup pending, {
  required String role,
  required String name,
  required String phoneNumber,
}) async {
  final data = await apiPost('/auth/social/signup', {
    'provider': pending.provider.code,
    'token': pending.token,
    'role': role,
    'name': name,
    'phoneNumber': phoneNumber,
  });
  final token = data['token'];
  if (token is! String || token.isEmpty) {
    throw SocialAuthException('회원가입 응답에 토큰이 없습니다.');
  }
  await completeLogin(token);
}
