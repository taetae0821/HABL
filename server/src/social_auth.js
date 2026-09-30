// 앱에서 받은 소셜 토큰을 각 제공자에게 직접 확인해서 사용자 정보를 돌려줍니다.
// 확인에 실패하면 null 을 돌려줍니다.

const kakaoAppId = process.env.KAKAO_APP_ID?.trim();

export const SOCIAL_PROVIDERS = ["KAKAO"];

export function isProviderConfigured(provider) {
  if (provider === "KAKAO") return Boolean(kakaoAppId);
  return false;
}

async function verifyKakao(accessToken) {
  const headers = { Authorization: `Bearer ${accessToken}` };

  // 다른 앱에서 발급된 토큰으로 로그인하지 못하도록 우리 앱의 토큰인지 확인합니다
  const infoResponse = await fetch(
    "https://kapi.kakao.com/v1/user/access_token_info",
    { headers },
  );
  if (!infoResponse.ok) return null;
  const info = await infoResponse.json();
  if (String(info.app_id) !== kakaoAppId) return null;

  const meResponse = await fetch("https://kapi.kakao.com/v2/user/me", {
    headers,
  });
  if (!meResponse.ok) return null;
  const me = await meResponse.json();
  const account = me.kakao_account ?? {};

  return {
    providerId: String(me.id),
    email:
      account.is_email_valid && account.is_email_verified
        ? account.email
        : null,
    name: account.profile?.nickname ?? me.properties?.nickname ?? null,
  };
}

export async function verifySocialToken(provider, token) {
  if (typeof token !== "string" || token.length === 0) return null;
  if (provider === "KAKAO") return verifyKakao(token);
  return null;
}
