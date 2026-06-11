import SwiftUI

struct SplashView: View {
    @State private var pulse = false
    @State private var logoScale = 0.4
    @State private var logoOpacity = 0.0
    @State private var titleOpacity = 0.0
    @State private var titleOffset: CGFloat = 18
    @State private var taglineOpacity = 0.0
    @State private var dotPhase = 0

    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 그라디언트 배경
            LinearGradient(
                colors: [Color(hex: "#FFF8ED"), Color(hex: "#FFDEA0"), Color(hex: "#F5A623").opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 배경 글로우
            Circle()
                .fill(Color.sonjuPrimary.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                // 로고 영역
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.sonjuPrimary.opacity(pulse ? 0 : 0.22 - Double(i) * 0.06), lineWidth: 1.5)
                            .frame(
                                width: pulse ? CGFloat(150 + i * 50) : CGFloat(104 + i * 18),
                                height: pulse ? CGFloat(150 + i * 50) : CGFloat(104 + i * 18)
                            )
                            .animation(
                                .easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.24),
                                value: pulse
                            )
                    }

                    Circle()
                        .fill(Color.sonjuPrimary.opacity(0.14))
                        .frame(width: 108, height: 108)

                    Circle()
                        .fill(Color.sonjuPrimary.opacity(0.08))
                        .frame(width: 130, height: 130)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.sonjuPrimary)
                        .shadow(color: Color.sonjuPrimary.opacity(0.35), radius: 14, x: 0, y: 5)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 36)

                // 앱 이름
                Text("손주들")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                Spacer().frame(height: 8)

                // 태그라인
                Text("효도를 일상의 서비스로")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#6B6B6B"))
                    .opacity(taglineOpacity)

                Spacer()

                // 로딩 점
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.sonjuPrimary.opacity(dotPhase == i ? 0.9 : 0.3))
                            .frame(width: 7, height: 7)
                            .scaleEffect(dotPhase == i ? 1.25 : 0.9)
                            .animation(.easeInOut(duration: 0.28), value: dotPhase)
                    }
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.58).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                pulse = true
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.5)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.72)) {
                taglineOpacity = 1.0
            }
        }
        .onReceive(timer) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}

#Preview { SplashView() }
