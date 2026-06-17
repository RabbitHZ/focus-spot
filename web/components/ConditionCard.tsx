import type { ConditionResult } from "@/types";

const MODE_CONFIG: Record<string, { emoji: string; color: string; bg: string }> = {
  focus:     { emoji: "🎯", color: "#2563eb", bg: "#eff6ff" },
  drowsy:    { emoji: "😴", color: "#7c3aed", bg: "#f5f3ff" },
  fatigue:   { emoji: "😓", color: "#dc2626", bg: "#fef2f2" },
  energized: { emoji: "⚡", color: "#d97706", bg: "#fffbeb" },
  recovery:  { emoji: "🌿", color: "#16a34a", bg: "#f0fdf4" },
};

export default function ConditionCard({ condition }: { condition: ConditionResult }) {
  const cfg = MODE_CONFIG[condition.mode] ?? { emoji: "❓", color: "#6b7280", bg: "#f3f4f6" };

  return (
    <div style={{
      background: cfg.bg,
      borderRadius: "var(--radius)",
      padding: 20,
      border: `1px solid ${cfg.color}22`,
    }}>
      <p style={{ fontSize: 12, color: "var(--text-sub)", marginBottom: 6 }}>현재 내 컨디션</p>

      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <span style={{ fontSize: 40 }}>{cfg.emoji}</span>
        <div>
          <p style={{ fontSize: 22, fontWeight: 800, color: cfg.color }}>{condition.label}</p>
          <p style={{ fontSize: 13, color: "#374151", marginTop: 2 }}>{condition.cafe_hint}</p>
        </div>
      </div>

      <div style={{ marginTop: 14 }}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
          <span style={{ fontSize: 12, color: "var(--text-sub)" }}>신뢰도</span>
          <span style={{ fontSize: 12, fontWeight: 600, color: cfg.color }}>{condition.confidence}%</span>
        </div>
        <div style={{ height: 6, background: "#e5e7eb", borderRadius: 3, overflow: "hidden" }}>
          <div style={{
            height: "100%",
            width: `${condition.confidence}%`,
            background: cfg.color,
            borderRadius: 3,
            transition: "width 0.5s ease",
          }} />
        </div>
      </div>
    </div>
  );
}
