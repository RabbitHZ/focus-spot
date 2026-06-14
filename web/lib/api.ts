import type { CafeCard, ConditionResult, RecommendResponse } from "@/types";

const BASE = "/api";

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token");
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = getToken();
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
  auth: {
    login: (email: string, password: string) =>
      request<{ access_token: string }>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      }),
    register: (email: string, password: string) =>
      request<{ access_token: string }>("/auth/register", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      }),
  },

  condition: {
    current: () => request<ConditionResult>("/condition/current"),
    history: () => request<{ records: Array<{ recorded_at: string; mode: string; label: string; confidence: number }> }>("/condition/history"),
  },

  cafes: {
    recommend: (lat: number, lng: number, radiusKm = 1.0) =>
      request<RecommendResponse>(
        `/cafes/recommend?lat=${lat}&lng=${lng}&radius_km=${radiusKm}`
      ),
    get: (id: number) => request<CafeCard>(`/cafes/${id}`),
  },
};
