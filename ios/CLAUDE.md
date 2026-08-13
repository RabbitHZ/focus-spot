# ios/CLAUDE.md

Swift/SwiftUI + HealthKit 컴패니언 앱 작업 지침.

## 빌드 & 실행

Xcode에서 `ios/FocusSpot/FocusSpot.xcodeproj` (또는 `.xcworkspace`) 열기.

```bash
# CLI 빌드 (시뮬레이터)
xcodebuild -scheme FocusSpot -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## 디렉토리 구조

```
ios/FocusSpot/Sources/
├── App/
│   ├── FocusSpotApp.swift    # 앱 진입점
│   ├── ContentView.swift     # 루트 뷰
│   ├── AuthManager.swift     # JWT 인증 관리
│   └── SyncManager.swift     # 30분 주기 동기화
├── Networking/
│   └── APIClient.swift       # 백엔드 API 클라이언트
└── Models/
    └── ConditionResult.swift # 컨디션 응답 모델
```

## 코딩 규칙

- SwiftUI + Combine 패턴 사용.
- HealthKit 권한 요청은 앱 첫 실행 시 한 번만.
- JWT 토큰은 Keychain에 저장 (UserDefaults 사용 금지).
- 네트워크 요청은 `APIClient.swift`에 집중한다.
- 백그라운드 동기화: `BGTaskScheduler` 활용, 30분 간격.

## HealthKit 수집 데이터

- 수면 시간 / 수면 단계
- 안정 시 심박수
- 호흡수
- 혈중 산소 포화도 (SpO2)
- 활동량 / 걸음 수
