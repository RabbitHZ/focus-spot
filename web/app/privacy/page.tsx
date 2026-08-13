import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "개인정보처리방침 | FocusSpot",
};

export default function PrivacyPage() {
  return (
    <main style={{ maxWidth: 680, width: "100%", margin: "0 auto" }}>
      <div style={{
        background: "rgba(255,255,255,0.82)",
        backdropFilter: "blur(20px)",
        borderRadius: 24,
        border: "1px solid rgba(0,0,0,0.07)",
        padding: "48px 40px",
      }}>
        <Link href="/" style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          fontSize: 13, color: "#6B7280", marginBottom: 32,
          fontWeight: 500,
        }}>
          ← FocusSpot으로 돌아가기
        </Link>

        <h1 style={{ fontSize: 26, fontWeight: 700, color: "#1a1a1a", marginBottom: 8 }}>
          개인정보처리방침
        </h1>
        <p style={{ fontSize: 13, color: "#9CA3AF", marginBottom: 40 }}>
          최종 수정일: 2026년 7월 3일
        </p>

        <Section title="1. 수집하는 개인정보 항목">
          <p>FocusSpot은 서비스 제공을 위해 다음과 같은 정보를 수집합니다.</p>
          <ul>
            <li><strong>필수 항목</strong>: 이메일 주소, 이름 (Google 로그인을 통해 수집)</li>
            <li><strong>선택 항목</strong>: 위치 정보 (카페 추천 시 사용자 동의 후 수집)</li>
            <li><strong>건강 데이터</strong>: Apple HealthKit을 통한 심박수, 수면 시간, 혈중 산소 포화도, 걸음 수 (기기 내부에서만 처리, 서버 저장 후 분석에 사용)</li>
          </ul>
        </Section>

        <Section title="2. 개인정보 수집 및 이용 목적">
          <ul>
            <li>컨디션 분석 및 카페 추천 서비스 제공</li>
            <li>회원 식별 및 서비스 이용 기록 관리</li>
            <li>서비스 품질 개선 및 신규 기능 개발</li>
          </ul>
        </Section>

        <Section title="3. 개인정보 보유 및 이용 기간">
          <ul>
            <li>회원 탈퇴 시 즉시 삭제 (단, 관련 법령에 따라 일정 기간 보관이 필요한 경우 해당 기간 보관)</li>
            <li>건강 데이터: 수집 후 90일 보관 후 자동 삭제</li>
            <li>위치 정보: 요청 시마다 수집 후 즉시 파기 (저장하지 않음)</li>
          </ul>
        </Section>

        <Section title="4. 개인정보의 제3자 제공">
          <p>FocusSpot은 원칙적으로 이용자의 개인정보를 제3자에게 제공하지 않습니다. 다만, 다음의 경우는 예외로 합니다.</p>
          <ul>
            <li>이용자가 사전에 동의한 경우</li>
            <li>법령의 규정에 의거하거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우</li>
          </ul>
        </Section>

        <Section title="5. 개인정보 처리 위탁">
          <ul>
            <li><strong>Google LLC</strong>: 소셜 로그인 인증 (Google OAuth 2.0)</li>
            <li><strong>Apple Inc.</strong>: HealthKit 데이터 접근 중개</li>
          </ul>
        </Section>

        <Section title="6. 이용자의 권리와 행사 방법">
          <p>이용자는 언제든지 다음 권리를 행사할 수 있습니다.</p>
          <ul>
            <li>개인정보 열람, 수정, 삭제 요청</li>
            <li>개인정보 처리 정지 요청</li>
            <li>앱 내 마이페이지 → 로그아웃 후 탈퇴 문의로 삭제 요청 가능</li>
          </ul>
        </Section>

        <Section title="7. 개인정보 보호를 위한 기술적 조치">
          <ul>
            <li>HTTPS 암호화 통신</li>
            <li>JWT 기반 인증 토큰 사용</li>
            <li>비밀번호 미저장 (소셜 로그인 전용)</li>
          </ul>
        </Section>

        <Section title="8. 개인정보 보호책임자">
          <p>개인정보 관련 문의는 아래로 연락해 주세요.</p>
          <ul>
            <li><strong>이메일</strong>: sistarv80@gmail.com</li>
          </ul>
        </Section>

        <Section title="9. 개인정보처리방침 변경">
          <p>이 방침은 법령 또는 서비스 변경에 따라 업데이트될 수 있으며, 변경 시 앱 내 공지 또는 이 페이지를 통해 안내합니다.</p>
        </Section>
      </div>
    </main>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section style={{ marginBottom: 36 }}>
      <h2 style={{
        fontSize: 15, fontWeight: 700, color: "#1a1a1a",
        marginBottom: 12, paddingBottom: 8,
        borderBottom: "1px solid rgba(0,0,0,0.06)",
      }}>
        {title}
      </h2>
      <div style={{
        fontSize: 14, color: "#4B5563", lineHeight: 1.8,
        display: "flex", flexDirection: "column", gap: 8,
      }}>
        {children}
      </div>
    </section>
  );
}
