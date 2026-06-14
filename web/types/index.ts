export type ConditionMode = "focus" | "drowsy" | "fatigue" | "energized" | "recovery";

export interface ConditionResult {
  mode: ConditionMode;
  label: string;
  confidence: number;
  cafe_hint: string;
}

export interface CafeCard {
  id: number;
  name: string;
  address: string;
  distance_m: number;
  noise_level: string | null;
  lighting: string | null;
  work_tags: string[];
  kakao_url: string | null;
  recommendation_reason: string;
  score: number;
}

export interface RecommendResponse {
  mode: ConditionMode;
  mode_label: string;
  cafes: CafeCard[];
}
