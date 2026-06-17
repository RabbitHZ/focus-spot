import { auth } from "@/auth";
import { NextResponse } from "next/server";

export async function GET() {
  const session = await auth();
  if (!session?.id_token) {
    // id_token 없음 = 미로그인이거나 만료 → 클라이언트가 재로그인하도록 419 반환
    return NextResponse.json({ error: "token_expired" }, { status: 419 });
  }

  const res = await fetch(`${process.env.INTERNAL_API_URL ?? "http://localhost:8000"}/api/auth/google`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ id_token: session.id_token }),
  });

  if (!res.ok) {
    return NextResponse.json({ error: "Failed to get token" }, { status: 401 });
  }

  const data = await res.json();
  return NextResponse.json(data);
}
