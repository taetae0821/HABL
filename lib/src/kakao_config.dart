/// 카카오 개발자센터(https://developers.kakao.com)에서 발급받은 JavaScript 키입니다.
///
/// 지금은 임시로 빈 값이며, 나중에 백엔드에서 키를 받아오는 로직으로 교체하면 됩니다.
/// 그 전까지 로컬에서 지도를 테스트하려면 아래처럼 실행 시 값을 주입하세요.
///
///   flutter run --dart-define=KAKAO_JS_KEY=실제_javascript_키
const String kakaoJavaScriptKey = String.fromEnvironment('KAKAO_JS_KEY');
