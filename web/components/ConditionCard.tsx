import type { ConditionResult } from "@/types";

const MODE_EMOJI: Record<string, string> = {
  focus: "🎯",
  drowsy: "😴",
  fatigue: "😓",
  energized: "⚡",
  recovery: "🌿",
};

const MODE_COLOR: Record<string, string> = {
  focus: "#2563eb",
  drowsy: "#7c3aed",
  fatigue: "#dc2626",
  energized: "#d97706",
  recovery: "#16a34a",
};

export default function ConditionCard({ condition }: { condition: ConditionResult }) {
  const color = MODE_COLOR[condition.mode] ?? "#6b7280";
  const emoji = MODE_EMOJI[condition.mode] ?? "❓";

  return (
    <div
      style={{
        background: "#fff",
        borderRadius: 16,
        padding: 20,
        borderLeft: `4px solid ${color}`,
        boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <span style={{ fontSize: 32 }}>{emoji}</span>
        <div>
          <p style={{ fontSize: 12, color: "#6b7280" }}>현재 컨디션</p>
          <p style={{ fontSize: 20, fontWeight: 700, color }}>{condition.label}</p>
        </div>
      </div>
      <p style={{ marginTop: 10, fontSize: 14, color: "#374151" }}>{condition.cafe_hint}</p>
      <p style={{ marginTop: 6, fontSize: 12, color: "#9ca3af" }}>신뢰도 {condition.confidence}%</p>
    </div>
  );
}
