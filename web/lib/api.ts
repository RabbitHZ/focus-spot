import type { CafeCard, ConditionResult, RecommendResponse } from "@/types";

const BASE = "/api";

let cachedToken: string | null = null;

async function getFocusSpotToken(): Promise<string | null> {
  if (cachedToken) return cachedToken;
  const res = await fetch("/api/focusspot-token");
  if (res.status === 419) {
    // Google id_token 만료 — NextAuth 세션도 무효화해 재로그인 유도
    const { signIn } = await import("next-auth/react");
    signIn("google");
    return null;
  }
  if (!res.ok) return null;
  const data = await res.json();
  cachedToken = data.access_token ?? null;
  return cachedToken;
}

export function clearToken() {
  cachedToken = null;
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await getFocusSpotToken();
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail ?? "요청 실패");
  }
  return res.json();
}

export const api = {
  condition: {
    current: () => request<ConditionResult>("/condition/current"),
    history: () =>
      request<{ records: Array<{ recorded_at: string; mode: string; label: string; confidence: number }> }>(
        "/condition/history"
      ),
  },

  cafes: {
    recommend: (lat: number, lng: number, radiusKm = 1.0) =>
      request<RecommendResponse>(`/cafes/recommend?lat=${lat}&lng=${lng}&radius_km=${radiusKm}`),
    get: (id: number) => request<CafeCard>(`/cafes/${id}`),
  },
};
