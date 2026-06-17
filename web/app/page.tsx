"use client";

import { useEffect, useState } from "react";
import { useSession, signIn, signOut } from "next-auth/react";
import { api } from "@/lib/api";
import type { CafeCard, ConditionResult } from "@/types";
import ConditionCard from "@/components/ConditionCard";
import CafeList from "@/components/CafeList";

const RADIUS_OPTIONS = [
  { label: "500m", value: 0.5 },
  { label: "1km", value: 1.0 },
  { label: "2km", value: 2.0 },
];

export default function HomePage() {
  const { data: session, status } = useSession();
  const [condition, setCondition] = useState<ConditionResult | null>(null);
  const [cafes, setCafes] = useState<CafeCard[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [radius, setRadius] = useState(1.0);

  useEffect(() => {
    if (status === "authenticated") {
      api.condition.current().then(setCondition).catch(() => null);
    }
  }, [status]);

  async function getLocation(): Promise<{ lat: number; lng: number }> {
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        (pos) => resolve({ lat: pos.coords.latitude, lng: pos.coords.longitude }),
        () => {
          // 위치 실패 시 서울 강남 기본값
          resolve({ lat: 37.4979, lng: 127.0276 });
        },
        { timeout: 5000 }
      );
    });
  }

  async function handleRecommend() {
    setLoading(true);
    setError(null);
    setCafes([]);
    try {
      const { lat, lng } = await getLocation();
      const result = await api.cafes.recommend(lat, lng, radius);
      if (result.cafes.length === 0) {
        setError(`반경 내 카페가 없습니다. 반경을 넓혀보세요.`);
      } else {
        setCafes(result.cafes);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "추천에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  if (status === "loading") {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <p style={{ color: "var(--text-sub)" }}>로딩 중...</p>
      </div>
    );
  }

  if (status === "unauthenticated") {
    return (
      <div style={{
        minHeight: "100vh", display: "flex", alignItems: "center",
        justifyContent: "center", padding: 16,
      }}>
        <div style={{
          width: "100%", maxWidth: 400,
          background: "var(--card)", borderRadius: 24,
          padding: 40, boxShadow: "0 8px 32px rgba(0,0,0,0.1)", textAlign: "center",
        }}>
          <div style={{ fontSize: 56, marginBottom: 16 }}>☕</div>
          <h1 style={{ fontSize: 26, fontWeight: 800, marginBottom: 8 }}>FocusSpot</h1>
          <p style={{ fontSize: 14, color: "var(--text-sub)", marginBottom: 32, lineHeight: 1.6 }}>
            내 컨디션에 맞는<br />집중하기 좋은 카페를 찾아드려요
          </p>
          <button
            onClick={() => signIn("google")}
            style={{
              width: "100%", display: "flex", alignItems: "center",
              justifyContent: "center", gap: 10, padding: "14px 20px",
              background: "#fff", color: "#1a1a1a",
              border: "1px solid var(--border)", borderRadius: 12,
              fontSize: 15, fontWeight: 600, cursor: "pointer",
              boxShadow: "0 1px 4px rgba(0,0,0,0.08)",
            }}
          >
            <GoogleIcon />
            Google로 로그인
          </button>
        </div>
      </div>
    );
  }

  return (
    <main style={{ maxWidth: 480, margin: "0 auto", padding: "20px 16px 40px" }}>
      {/* 헤더 */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
        <h1 style={{ fontSize: 22, fontWeight: 800 }}>☕ FocusSpot</h1>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          {session?.user?.image && (
            <img
              src={session.user.image}
              alt="profile"
              style={{ width: 32, height: 32, borderRadius: "50%", border: "2px solid var(--border)" }}
            />
          )}
          <button
            onClick={() => signOut()}
            style={{
              fontSize: 13, color: "var(--text-sub)",
              background: "none", border: "none", cursor: "pointer",
            }}
          >
            로그아웃
          </button>
        </div>
      </div>

      {/* 컨디션 카드 */}
      {condition
        ? <ConditionCard condition={condition} />
        : (
          <div style={{
            background: "var(--card)", borderRadius: "var(--radius)",
            padding: 20, textAlign: "center", color: "var(--text-sub)", fontSize: 14,
          }}>
            😴 건강 데이터가 없습니다.<br />iOS 앱에서 동기화해주세요.
          </div>
        )
      }

      {/* 반경 설정 */}
      <div style={{ marginTop: 16 }}>
        <p style={{ fontSize: 13, color: "var(--text-sub)", marginBottom: 8 }}>검색 반경</p>
        <div style={{ display: "flex", gap: 8 }}>
          {RADIUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              onClick={() => setRadius(opt.value)}
              style={{
                flex: 1, padding: "8px 0",
                background: radius === opt.value ? "#2563eb" : "var(--card)",
                color: radius === opt.value ? "#fff" : "var(--text-sub)",
                border: `1px solid ${radius === opt.value ? "#2563eb" : "var(--border)"}`,
                borderRadius: 10, fontSize: 13, fontWeight: 600, cursor: "pointer",
                transition: "all 0.15s",
              }}
            >
              {opt.label}
            </button>
          ))}
        </div>
      </div>

      {/* 추천 버튼 */}
      <button
        onClick={handleRecommend}
        disabled={loading}
        style={{
          width: "100%", padding: "15px",
          marginTop: 12,
          background: loading ? "#93c5fd" : "#2563eb",
          color: "#fff", border: "none", borderRadius: 12,
          fontSize: 16, fontWeight: 700,
          cursor: loading ? "not-allowed" : "pointer",
          transition: "background 0.15s",
        }}
      >
        {loading ? "⏳ 추천 중..." : "지금 추천 카페 보기"}
      </button>

      {error && (
        <p style={{
          color: "#dc2626", marginTop: 12, fontSize: 13,
          padding: "10px 14px", background: "#fef2f2",
          borderRadius: 8, lineHeight: 1.5,
        }}>
          {error}
        </p>
      )}

      {cafes.length > 0 && <CafeList cafes={cafes} />}
    </main>
  );
}

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18">
      <path fill="#4285F4" d="M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18z"/>
      <path fill="#34A853" d="M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2a4.8 4.8 0 0 1-7.18-2.54H1.83v2.07A8 8 0 0 0 8.98 17z"/>
      <path fill="#FBBC05" d="M4.5 10.52a4.8 4.8 0 0 1 0-3.04V5.41H1.83a8 8 0 0 0 0 7.18z"/>
      <path fill="#EA4335" d="M8.98 4.18c1.17 0 2.23.4 3.06 1.2l2.3-2.3A8 8 0 0 0 1.83 5.4L4.5 7.49a4.77 4.77 0 0 1 4.48-3.3z"/>
    </svg>
  );
}
