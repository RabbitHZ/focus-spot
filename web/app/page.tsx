"use client";

import { useEffect, useState } from "react";
import { api } from "@/lib/api";
import type { CafeCard, ConditionResult } from "@/types";
import ConditionCard from "@/components/ConditionCard";
import CafeList from "@/components/CafeList";

export default function HomePage() {
  const [condition, setCondition] = useState<ConditionResult | null>(null);
  const [cafes, setCafes] = useState<CafeCard[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    api.condition.current().then(setCondition).catch(() => null);
  }, []);

  async function handleRecommend() {
    setLoading(true);
    setError(null);
    try {
      const pos = await new Promise<GeolocationPosition>((res, rej) =>
        navigator.geolocation.getCurrentPosition(res, rej)
      );
      const result = await api.cafes.recommend(
        pos.coords.latitude,
        pos.coords.longitude
      );
      setCafes(result.cafes);
    } catch (e) {
      setError(e instanceof Error ? e.message : "추천에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main style={{ maxWidth: 480, margin: "0 auto", padding: "24px 16px" }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>FocusSpot</h1>

      {condition && <ConditionCard condition={condition} />}

      <button
        onClick={handleRecommend}
        disabled={loading}
        style={{
          width: "100%",
          padding: "14px",
          marginTop: 16,
          background: "#2563eb",
          color: "#fff",
          border: "none",
          borderRadius: 12,
          fontSize: 16,
          fontWeight: 600,
          cursor: loading ? "not-allowed" : "pointer",
          opacity: loading ? 0.7 : 1,
        }}
      >
        {loading ? "추천 중..." : "지금 추천 카페 보기"}
      </button>

      {error && (
        <p style={{ color: "#ef4444", marginTop: 12, fontSize: 14 }}>{error}</p>
      )}

      {cafes.length > 0 && <CafeList cafes={cafes} />}
    </main>
  );
}
