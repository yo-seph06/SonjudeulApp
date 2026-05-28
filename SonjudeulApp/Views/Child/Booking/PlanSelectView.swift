import SwiftUI

struct PlanSelectView: View {
    @ObservedObject var bookingVM: BookingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                IllustratedPlanCard(
                    plan: .oneDay,
                    isSelected: bookingVM.selectedPlan == .oneDay,
                    illustrationColors: [Color(hex: "#FFF0D0"), Color(hex: "#FFE4A0")],
                    illustrationContent: AnyView(OneDayIllustration()),
                    title: "원데이 효도",
                    subtitle: "(1회 방문)",
                    price: "19,800원",
                    features: ["1회 2시간 방문 교육", "안부 리포트 포함"]
                ) { bookingVM.selectedPlan = .oneDay }

                IllustratedPlanCard(
                    plan: .subscription,
                    isSelected: bookingVM.selectedPlan == .subscription,
                    illustrationColors: [Color(hex: "#E8F5FF"), Color(hex: "#C8E6FF")],
                    illustrationContent: AnyView(SubscriptionIllustration()),
                    title: "안심 정기 구독",
                    subtitle: "(월 2회)",
                    price: "35,000원/월",
                    features: ["매주 1회 방문", "상세 리포트 제공"]
                ) { bookingVM.selectedPlan = .subscription }

                AmberButton(title: "다음") {
                    withAnimation { bookingVM.nextStep() }
                }
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

// MARK: — Illustrated Card

#Preview {
    PlanSelectView(bookingVM: BookingViewModel())
}

struct IllustratedPlanCard: View {
    let plan: PlanType
    let isSelected: Bool
    let illustrationColors: [Color]
    let illustrationContent: AnyView
    let title: String
    let subtitle: String
    let price: String
    let features: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Illustration header
                ZStack(alignment: .topTrailing) {
                    LinearGradient(
                        colors: illustrationColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    illustrationContent
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.sonjuPrimary)
                            .font(.system(size: 28))
                            .padding(12)
                    }
                }
                .frame(height: 120)
                .clipped()

                // Content
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.sonjuText)
                            Text(subtitle)
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        Text(price)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.sonjuPrimary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.sonjuSuccess)
                                Text(feature)
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuText)
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.sonjuPrimary : Color.clear, lineWidth: 2.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(PressButtonStyle())
    }
}

// MARK: — Illustrations

struct OneDayIllustration: View {
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.sonjuPrimary)
            Image(systemName: "figure.and.child.holdinghands")
                .font(.system(size: 44))
                .foregroundColor(.sonjuDeep)
        }
    }
}

struct SubscriptionIllustration: View {
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#2196F3"))
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.sonjuPrimary)
        }
    }
}
