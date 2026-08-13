import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lat: Double?
    @Published var lng: Double?
    @Published var error: String?
    @Published var status: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        status = manager.authorizationStatus
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        lat = coord.latitude
        lng = coord.longitude
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "위치를 가져올 수 없어요. 다시 시도해주세요."
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied {
            error = "위치 권한이 차단되어 있어요. 설정 → 개인 정보 보호 → 위치 서비스에서 허용해주세요."
        }
    }
}

struct LocationView: View {
    let onBack: () -> Void
    let onLocation: (Double, Double) -> Void

    @StateObject private var locationManager = LocationManager()
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            // 지도 일러스트
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                // 배경
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(C.lavender))

                // 그리드
                var grid = Path()
                stride(from: CGFloat(0), to: w, by: 44).forEach { x in
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: h))
                }
                stride(from: CGFloat(0), to: h, by: 44).forEach { y in
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: w, y: y))
                }
                ctx.stroke(grid, with: .color(C.green.opacity(0.12)), lineWidth: 1)

                // 도로 1 (가로, -7도)
                ctx.drawLayer { c in
                    c.translateBy(x: w / 2, y: h * 0.36)
                    c.rotate(by: .degrees(-7))
                    var road = Path()
                    road.addRect(CGRect(x: -(w / 2 + 20), y: -10, width: w + 40, height: 20))
                    c.fill(road, with: .color(Color.white.opacity(0.92)))
                }
                // 도로 2 (세로, 5도)
                ctx.drawLayer { c in
                    c.translateBy(x: 130, y: h / 2)
                    c.rotate(by: .degrees(5))
                    var road = Path()
                    road.addRect(CGRect(x: -10, y: -h / 2, width: 20, height: h))
                    c.fill(road, with: .color(Color.white.opacity(0.92)))
                }
                // 도로 3 (가로 하단, 3도)
                ctx.drawLayer { c in
                    c.translateBy(x: w / 2, y: h * 0.78)
                    c.rotate(by: .degrees(3))
                    var road = Path()
                    road.addRect(CGRect(x: -(w / 2 + 20), y: -7, width: w + 40, height: 14))
                    c.fill(road, with: .color(Color.white.opacity(0.8)))
                }

                // 핑크 마커 2개
                for pt in [CGPoint(x: 56, y: 80), CGPoint(x: 250, y: 250)] {
                    let r: CGFloat = 6.5
                    ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r*2, height: r*2)), with: .color(C.rose))
                    ctx.stroke(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r*2, height: r*2)), with: .color(.white), lineWidth: 3)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 300)
            .clipped()
            .overlay(alignment: .center) {
                // 중앙 하트 핀
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(C.grad)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(45))
                            .shadow(color: C.greenDeep.opacity(0.4), radius: 16, y: 8)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(C.ink)
                    }
                    Triangle()
                        .fill(C.green)
                        .frame(width: 14, height: 8)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                KickLabel(text: "STEP 3 / 3")
                    .padding(.bottom, 10)

                Text("근처 카페를\n찾을게요")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(C.ink)
                    .lineSpacing(2)
                    .padding(.bottom, 12)

                Text("위치를 켜면 지금 컨디션에 맞는 카페를\n가까운 순으로 보여드려요.")
                    .font(.system(size: 15.5))
                    .foregroundColor(C.sub)
                    .lineSpacing(3)

                if let error = locationManager.error {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#B03030"))
                        .lineSpacing(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "#FFF0F0"))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#F8CCCC"), lineWidth: 1))
                        .padding(.top, 16)
                }

                Spacer()

                VStack(spacing: 14) {
                    PrimaryButton(
                        label: isLoading ? "위치 확인 중…" : "위치 허용",
                        icon: isLoading ? nil : "location.fill",
                        bg: isLoading ? C.faint : C.ink
                    ) {
                        guard !isLoading else { return }
                        isLoading = true
                        locationManager.request()
                    }

                    Button(action: {
                        onLocation(37.4979, 127.0276)
                    }) {
                        Text("지금은 안 할게요")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(C.sub)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .frame(maxHeight: .infinity)
        }
        .background(C.surface.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(C.ink)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(13)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
            }
            .padding(.leading, 18)
            .padding(.top, 44)
        }
        .onChange(of: locationManager.lat) { _, lat in
            guard let lat, let lng = locationManager.lng else { return }
            isLoading = false
            onLocation(lat, lng)
        }
        .onChange(of: locationManager.error) { _, _ in
            isLoading = false
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}

