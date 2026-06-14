import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "FocusSpot",
  description: "내 컨디션에 맞는 카페를 찾아드려요",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
