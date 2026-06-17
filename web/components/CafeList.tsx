import type { CafeCard } from "@/types";

const NOISE_LABEL: Record<string, { label: string; icon: string; color: string }> = {
  quiet: { label: "조용함", icon: "🔇", color: "#16a34a" },
  "moderate-noise": { label: "보통", icon: "🔉", color: "#d97706" },
  lively: { label: "활기참", icon: "🔊", color: "#dc2626" },
};

const WORK_TAG_LABEL: Record<string, string> = {
  "work-friendly": "💻 업무 가능",
  "fast-wifi": "📶 빠른 와이파이",
  "power-outlet": "🔌 콘센트",
  "no-laptop": "🚫 노트북 불가",
  "easy-to-seat": "🪑 자리 여유",
  "specialty-coffee": "☕ 스페셜티",
  "decaf-available": "🌿 디카페인",
  "non-coffee": "🧃 논커피",
};

export default function CafeList({ cafes }: { cafes: CafeCard[] }) {
  return (
    <div style={{ marginTop: 24 }}>
      <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 12, color: "var(--text)" }}>
        추천 카페 {cafes.length}곳
      </h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {cafes.map((cafe, i) => (
          <CafeCardItem key={cafe.id} cafe={cafe} rank={i + 1} />
        ))}
      </div>
    </div>
  );
}

function CafeCardItem({ cafe, rank }: { cafe: CafeCard; rank: number }) {
  const distanceText = cafe.distance_m < 1000
    ? `${cafe.distance_m}m`
    : `${(cafe.distance_m / 1000).toFixed(1)}km`;

  const noise = cafe.noise_level ? NOISE_LABEL[cafe.noise_level] : null;

  return (
    <div style={{
      background: "var(--card)",
      borderRadius: "var(--radius)",
      padding: 16,
      boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
    }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{
            width: 24, height: 24, borderRadius: "50%",
            background: rank === 1 ? "#2563eb" : "#e5e7eb",
            color: rank === 1 ? "#fff" : "#6b7280",
            fontSize: 12, fontWeight: 700,
            display: "flex", alignItems: "center", justifyContent: "center",
            flexShrink: 0,
          }}>{rank}</span>
          <p style={{ fontWeight: 700, fontSize: 16 }}>{cafe.name}</p>
        </div>
        <span style={{ fontSize: 13, color: "var(--text-sub)", whiteSpace: "nowrap", marginLeft: 8 }}>
          📍 {distanceText}
        </span>
      </div>

      <p style={{ fontSize: 13, color: "var(--text-sub)", marginTop: 4, paddingLeft: 32 }}>
        {cafe.address}
      </p>

      <p style={{
        fontSize: 13, color: "#374151", marginTop: 10,
        padding: "8px 12px",
        background: "#f0f7ff",
        borderRadius: 8,
        borderLeft: "3px solid #2563eb",
      }}>
        "{cafe.recommendation_reason}"
      </p>

      <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap", alignItems: "center" }}>
        {noise && (
          <span style={{
            display: "flex", alignItems: "center", gap: 4,
            background: "#f3f4f6", borderRadius: 20,
            padding: "4px 10px", fontSize: 12, fontWeight: 500,
            color: noise.color,
          }}>
            {noise.icon} {noise.label}
          </span>
        )}
        {cafe.work_tags.slice(0, 3).map((tag) => (
          <span key={tag} style={{
            background: "#f3f4f6", borderRadius: 20,
            padding: "4px 10px", fontSize: 12, color: "#374151",
          }}>
            {WORK_TAG_LABEL[tag] ?? tag}
          </span>
        ))}
      </div>

      {cafe.kakao_url && (
        <a
          href={cafe.kakao_url}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            display: "inline-flex", alignItems: "center", gap: 4,
            marginTop: 12, fontSize: 13, color: "#2563eb", fontWeight: 600,
          }}
        >
          카카오맵에서 보기 →
        </a>
      )}
    </div>
  );
}
