import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "figure.and.child.holdinghands",
            title: "부모님 댁에\n손주가 찾아갑니다",
            subtitle: "검증된 대학생 멘토가 직접 방문해\n눈높이에 맞게 스마트폰을 알려드려요"
        ),
        OnboardingPage(
            symbol: "iphone.and.arrow.forward",
            title: "1대1 맞춤\n스마트폰 교육",
            subtitle: "기초부터 배달앱, 보이스피싱 예방까지\n필요한 것만 골라서 배워요"
        ),
        OnboardingPage(
            symbol: "photo.on.rectangle.angled",
            title: "교육 후 안부 리포트를\n받아보세요",
            subtitle: "부모님의 밝은 모습 사진과 교육 결과를\n앱 알림으로 바로 전달해드려요"
        )
    ]

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 16) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.sonjuPrimary : Color.sonjuPrimary.opacity(0.3))
                                .frame(width: currentPage == index ? 20 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)

                    if currentPage == pages.count - 1 {
                        AmberButton(title: "시작하기") {
                            auth.completeOnboarding()
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                    } else {
                        Button("건너뛰기") {
                            auth.completeOnboarding()
                        }
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                        .frame(height: 52)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .animation(.easeInOut, value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.sonjuPrimary.opacity(0.12))
                    .frame(width: 200, height: 200)
                Image(systemName: page.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.sonjuPrimary)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.sonjuLargeTitle)
                    .foregroundColor(.sonjuText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(page.subtitle)
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
