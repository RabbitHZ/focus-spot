import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "서비스 이용약관 | FocusSpot",
};

export default function TermsPage() {
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
          서비스 이용약관
        </h1>
        <p style={{ fontSize: 13, color: "#9CA3AF", marginBottom: 40 }}>
          최종 수정일: 2026년 7월 3일
        </p>

        <Section title="제1조 (목적)">
          <p>이 약관은 FocusSpot(이하 "서비스")이 제공하는 카페 추천 서비스의 이용 조건 및 절차, 이용자와 서비스 운영자의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.</p>
        </Section>

        <Section title="제2조 (정의)">
          <ul>
            <li><strong>서비스</strong>: FocusSpot이 운영하는 iOS 앱 및 웹 서비스 일체</li>
            <li><strong>이용자</strong>: 서비스에 접속하여 이 약관에 따라 서비스를 이용하는 회원 및 비회원</li>
            <li><strong>회원</strong>: Google 계정으로 로그인하여 서비스를 이용하는 자</li>
          </ul>
        </Section>

        <Section title="제3조 (약관의 효력 및 변경)">
          <ul>
            <li>이 약관은 서비스 화면에 게시하거나 기타 방법으로 이용자에게 공지함으로써 효력이 발생합니다.</li>
            <li>서비스는 합리적인 사유가 있을 경우 이 약관을 변경할 수 있으며, 변경된 약관은 공지 후 7일 이내에 효력이 발생합니다.</li>
          </ul>
        </Section>

        <Section title="제4조 (서비스의 제공)">
          <p>FocusSpot은 다음과 같은 서비스를 제공합니다.</p>
          <ul>
            <li>Apple HealthKit 연동을 통한 건강 데이터 기반 컨디션 분석</li>
            <li>컨디션에 맞는 카페 추천 (위치 기반)</li>
            <li>카페 상세 정보 및 지도 연동</li>
          </ul>
        </Section>

        <Section title="제5조 (서비스 이용)">
          <ul>
            <li>서비스는 Google 계정 로그인 후 이용할 수 있습니다.</li>
            <li>위치 정보 제공은 선택 사항이며, 제공하지 않을 경우 기본 위치(강남)로 추천이 제공됩니다.</li>
            <li>HealthKit 접근 권한은 선택 사항이며, 미제공 시 수동 모드로 컨디션을 선택할 수 있습니다.</li>
          </ul>
        </Section>

        <Section title="제6조 (이용자의 의무)">
          <p>이용자는 다음 행위를 해서는 안 됩니다.</p>
          <ul>
            <li>서비스를 통해 허위 정보를 유포하는 행위</li>
            <li>서비스의 운영을 방해하는 행위</li>
            <li>다른 이용자의 정보를 수집하거나 저장하는 행위</li>
            <li>서비스를 역엔지니어링하거나 무단으로 복제하는 행위</li>
          </ul>
        </Section>

        <Section title="제7조 (서비스의 중단)">
          <ul>
            <li>서비스는 시스템 점검, 증설 및 교체, 천재지변 등 불가항력적 사유로 일시적으로 중단될 수 있습니다.</li>
            <li>서비스 중단으로 인한 손해에 대해 고의 또는 중대한 과실이 없는 한 책임을 지지 않습니다.</li>
          </ul>
        </Section>

        <Section title="제8조 (면책 조항)">
          <ul>
            <li>컨디션 분석 결과 및 카페 추천은 참고용이며, 의료적 판단의 근거로 사용할 수 없습니다.</li>
            <li>카페 정보(영업시간, 혼잡도 등)는 실시간으로 변경될 수 있으며 정확성을 보장하지 않습니다.</li>
          </ul>
        </Section>

        <Section title="제9조 (준거법 및 관할)">
          <p>이 약관은 대한민국 법률에 따라 규율되며, 서비스 이용으로 발생한 분쟁에 대해서는 대한민국 법원을 관할 법원으로 합니다.</p>
        </Section>

        <Section title="제10조 (문의)">
          <ul>
            <li><strong>이메일</strong>: sistarv80@gmail.com</li>
          </ul>
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
