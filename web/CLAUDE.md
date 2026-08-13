# web/CLAUDE.md

Next.js 14 웹 프론트엔드 작업 지침.

## 커맨드

```bash
pnpm dev          # 개발 서버 (localhost:3000)
pnpm build        # 프로덕션 빌드
pnpm lint         # ESLint
pnpm type-check   # TypeScript 타입 체크
```

## 디렉토리 구조

```
web/
├── app/            # Next.js App Router 페이지
│   ├── page.tsx    # 메인 화면 (카페 추천)
│   ├── privacy/    # 개인정보처리방침
│   └── terms/      # 이용약관
├── components/     # 재사용 UI 컴포넌트
├── lib/            # API 클라이언트, 유틸리티
│   └── api.ts      # FastAPI 연동 함수
├── types/          # TypeScript 타입 정의
│   └── index.ts
└── design/         # 디자인 에셋 (SVG 등)
```

## 코딩 규칙

- App Router 사용. Pages Router 패턴 사용 금지.
- 서버 컴포넌트 기본, 클라이언트 상태가 필요한 경우에만 `"use client"`.
- API 호출은 `lib/api.ts`에 집중한다.
- 새 의존성: `pnpm add <package>`
- 타입은 `types/index.ts`에 정의한다.

## API 연동

백엔드 기본 URL: `http://localhost:8000` (개발) / 환경변수 `NEXT_PUBLIC_API_URL`

## 주요 화면

| 경로 | 설명 |
|------|------|
| `/` | 메인 (컨디션 카드 + 카페 추천 리스트) |
| `/privacy` | 개인정보처리방침 |
| `/terms` | 이용약관 |
