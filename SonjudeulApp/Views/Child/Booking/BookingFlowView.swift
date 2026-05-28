import SwiftUI

struct BookingFlowView: View {
    @StateObject var bookingVM = BookingViewModel()
    @Environment(\.dismiss) var dismiss

    var stepIndex: Int {
        switch bookingVM.currentStep {
        case .plan:        return 0
        case .bookingInfo: return 1
        case .complete:    return 2
        }
    }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                if bookingVM.currentStep != .complete {
                    StepProgressBar(current: stepIndex + 1, total: 2)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }

                Group {
                    switch bookingVM.currentStep {
                    case .plan:
                        PlanSelectView(bookingVM: bookingVM)
                    case .bookingInfo:
                        ParentInfoView(bookingVM: bookingVM)
                    case .complete:
                        BookingCompleteView(bookingVM: bookingVM)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id(bookingVM.currentStep)
                .animation(.spring(response: 0.4), value: bookingVM.currentStep)
            }
        }
        .environmentObject(bookingVM)
        .navigationTitle(stepTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if bookingVM.currentStep == .bookingInfo {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.sonjuSecondary)
                    }
                }
            }
        }
    }

    var stepTitle: String {
        switch bookingVM.currentStep {
        case .plan:        return "서비스 선택"
        case .bookingInfo: return "예약하기"
        case .complete:    return ""
        }
    }
}

struct StepProgressBar: View {
    let current: Int
    let total: Int

    var progress: Double { Double(current) / Double(total) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("STEP \(current)/\(total)")
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuPrimary)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sonjuDivider)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.sonjuPrimary)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}
