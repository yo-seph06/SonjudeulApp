import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let floatingSymbols: [String]
    let title: String
    let subtitle: String
    let accentColor: Color
    let bgColors: [Color]
}

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "figure.and.child.holdinghands",
            floatingSymbols: ["heart.fill", "star.fill", "house.fill"],
            title: "부모님 댁에\n손주가 찾아갑니다",
            subtitle: "검증된 대학생 멘토가 직접 방문해\n눈높이에 맞게 스마트폰을 알려드려요",
            accentColor: Color(hex: "#F5A623"),
            bgColors: [Color(hex: "#FFF8ED"), Color(hex: "#FFE4B2")]
        ),
        OnboardingPage(
            symbol: "iphone.and.arrow.forward",
            floatingSymbols: ["wifi", "message.fill", "camera.fill"],
            title: "1대1 맞춤\n스마트폰 교육",
            subtitle: "기초부터 배달앱, 보이스피싱 예방까지\n필요한 것만 골라서 배워요",
            accentColor: Color(hex: "#5B9EF4"),
            bgColors: [Color(hex: "#F0F6FF"), Color(hex: "#C8DFFF")]
        ),
        OnboardingPage(
            symbol: "photo.on.rectangle.angled",
            floatingSymbols: ["bell.fill", "checkmark.circle.fill", "doc.richtext.fill"],
            title: "교육 후 안부 리포트를\n받아보세요",
            subtitle: "부모님의 밝은 모습 사진과 교육 결과를\n앱 알림으로 바로 전달해드려요",
            accentColor: Color(hex: "#4CAF7D"),
            bgColors: [Color(hex: "#F0FFF6"), Color(hex: "#B8F0CE")]
        )
    ]

    var body: some View {
        ZStack {
            // 페이지별 배경
            LinearGradient(
                colors: pages[currentPage].bgColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // 상단 건너뛰기
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                auth.completeOnboarding()
                            }
                        } label: {
                            Text("건너뛰기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(pages[currentPage].accentColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(pages[currentPage].accentColor.opacity(0.12))
                                .cornerRadius(20)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: currentPage)
                    }
                }
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // 페이지 콘텐츠
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 하단 영역
                VStack(spacing: 20) {
                    // 인디케이터 점
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(currentPage == i
                                      ? pages[currentPage].accentColor
                                      : pages[currentPage].accentColor.opacity(0.25))
                                .frame(width: currentPage == i ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // 버튼
                    if currentPage == pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                auth.completeOnboarding()
                            }
                        } label: {
                            Text("시작하기")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [pages[currentPage].accentColor,
                                                 pages[currentPage].accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: pages[currentPage].accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PressButtonStyle())
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("다음")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [pages[currentPage].accentColor,
                                             pages[currentPage].accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: pages[currentPage].accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(PressButtonStyle())
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
                .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }
}

// MARK: - 페이지 뷰

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    // 플로팅 아이콘 위치
    private let floatPositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-118, -60, 18),
        (118, -80, 15),
        (-100,  70, 14),
        ( 110,  60, 16),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // 일러스트 영역
            ZStack {
                // 배경 카드
                RoundedRectangle(cornerRadius: 36)
                    .fill(page.accentColor.opacity(0.13))
                    .frame(width: 240, height: 240)

                RoundedRectangle(cornerRadius: 28)
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 200, height: 200)

                // 메인 아이콘
                Image(systemName: page.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(page.accentColor)
                    .shadow(color: page.accentColor.opacity(0.3), radius: 10, x: 0, y: 4)

                // 플로팅 미니 아이콘
                ForEach(Array(page.floatingSymbols.prefix(3).enumerated()), id: \.offset) { i, sym in
                    let pos = floatPositions[i]
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: pos.size + 16, height: pos.size + 16)
                            .shadow(color: page.accentColor.opacity(0.2), radius: 8, x: 0, y: 3)
                        Image(systemName: sym)
                            .font(.system(size: pos.size))
                            .foregroundColor(page.accentColor)
                    }
                    .offset(x: pos.x, y: pos.y)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.65).delay(0.2 + Double(i) * 0.1),
                        value: appeared
                    )
                }
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.05), value: appeared)

            Spacer().frame(height: 48)

            // 텍스트
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .offset(y: appeared ? 0 : 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.15), value: appeared)

                Text(page.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#6B6B6B"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .offset(y: appeared ? 0 : 12)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45).delay(0.25), value: appeared)
            }
            .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
        .onAppear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
