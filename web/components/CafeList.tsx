import type { CafeCard } from "@/types";

const NOISE_LABEL: Record<string, string> = {
  quiet: "🔇 조용함",
  "moderate-noise": "🔉 보통",
  lively: "🔊 활기참",
};

export default function CafeList({ cafes }: { cafes: CafeCard[] }) {
  return (
    <div style={{ marginTop: 24 }}>
      <h2 style={{ fontSize: 16, fontWeight: 600, marginBottom: 12 }}>추천 카페</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {cafes.map((cafe) => (
          <CafeCardItem key={cafe.id} cafe={cafe} />
        ))}
      </div>
    </div>
  );
}

function CafeCardItem({ cafe }: { cafe: CafeCard }) {
  const distanceText =
    cafe.distance_m < 1000
      ? `${cafe.distance_m}m`
      : `${(cafe.distance_m / 1000).toFixed(1)}km`;

  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 14,
        padding: 16,
        boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
        <p style={{ fontWeight: 600, fontSize: 16 }}>{cafe.name}</p>
        <span style={{ fontSize: 13, color: "#6b7280" }}>{distanceText}</span>
      </div>

      <p style={{ fontSize: 13, color: "#6b7280", marginTop: 4 }}>{cafe.address}</p>

      <p style={{ fontSize: 13, color: "#374151", marginTop: 8, fontStyle: "italic" }}>
        "{cafe.recommendation_reason}"
      </p>

      <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
        {cafe.noise_level && (
          <Tag>{NOISE_LABEL[cafe.noise_level] ?? cafe.noise_level}</Tag>
        )}
        {cafe.work_tags.slice(0, 3).map((tag) => (
          <Tag key={tag}>{tag}</Tag>
        ))}
      </div>

      {cafe.kakao_url && (
        <a
          href={cafe.kakao_url}
          target="_blank"
          rel="noopener noreferrer"
          style={{
            display: "inline-block",
            marginTop: 12,
            fontSize: 13,
            color: "#2563eb",
            fontWeight: 500,
          }}
        >
          카카오맵에서 보기 →
        </a>
      )}
    </div>
  );
}

function Tag({ children }: { children: React.ReactNode }) {
  return (
    <span
      style={{
        background: "#f3f4f6",
        borderRadius: 6,
        padding: "3px 8px",
        fontSize: 12,
        color: "#374151",
      }}
    >
      {children}
    </span>
  );
}
