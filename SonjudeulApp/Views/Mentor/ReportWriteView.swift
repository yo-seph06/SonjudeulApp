import SwiftUI

struct ReportWriteView: View {
    let booking: BookingRecord?

    @EnvironmentObject var reportStore: ReportStore
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var reportVM: ReportViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showSuccess = false

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let booking {
                        SonjuCard {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundColor(.sonjuPrimary)
                                    .font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(booking.date)
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                    Text(booking.plan)
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuText)
                                }
                                Spacer()
                            }
                        }
                    }

                    // Photo picker area
                    VStack(alignment: .leading, spacing: 12) {
                        Text("부모님 사진 추가")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        HStack(spacing: 12) {
                            ForEach(0..<3) { index in
                                PhotoSlot(index: index)
                            }
                        }
                    }

                    Divider().background(Color.sonjuDivider)

                    // Checklist
                    VStack(alignment: .leading, spacing: 12) {
                        Text("교육 완료 항목")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        VStack(spacing: 0) {
                            ForEach(reportVM.curriculumItems, id: \.self) { item in
                                CheckRow(
                                    title: item,
                                    isChecked: reportVM.completedItems.contains(item),
                                    onToggle: { reportVM.toggleCompleted(item) }
                                )
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    Divider().background(Color.sonjuDivider)

                    // Mentor note
                    VStack(alignment: .leading, spacing: 12) {
                        Text("멘토 한마디")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        TextEditor(text: $reportVM.mentorNote)
                            .font(.sonjuBody)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.sonjuDivider, lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if reportVM.mentorNote.isEmpty {
                                        Text("오늘 수업은 어떠셨나요?")
                                            .font(.sonjuBody)
                                            .foregroundColor(.sonjuSecondary.opacity(0.6))
                                            .padding(16)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    }
                                }
                            )
                    }

                    Divider().background(Color.sonjuDivider)

                    // Next recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("다음 방문 추천 항목")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        FlowLayout(items: reportVM.recommendItems) { item in
                            Button {
                                reportVM.toggleRecommendation(item)
                            } label: {
                                Text(item)
                                    .font(.sonjuCaption)
                                    .foregroundColor(reportVM.nextRecommendations.contains(item) ? .white : .sonjuPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        reportVM.nextRecommendations.contains(item)
                                            ? Color.sonjuPrimary
                                            : Color.sonjuPrimary.opacity(0.12)
                                    )
                                    .cornerRadius(20)
                            }
                            .buttonStyle(PressButtonStyle())
                        }
                    }

                    AmberButton(title: "리포트 전송하기") {
                        submitReport()
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            // Success overlay
            if showSuccess {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.sonjuPrimary.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundColor(.sonjuPrimary)
                    }
                    Text("완료했습니다! 🎉")
                        .font(.sonjuLargeTitle)
                        .foregroundColor(.sonjuText)
                    Text("리포트가 자녀분께 전달되었어요")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                }
                .padding(40)
                .background(Color.sonjuCard)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationTitle("리포트 작성")
        .navigationBarTitleDisplayMode(.large)
        .animation(.spring(response: 0.4), value: showSuccess)
    }

    private func submitReport() {
        let mentorName = auth.currentUser?.name ?? "멘토"
        let dateStr: String = {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "yyyy년 M월 d일"
            return f.string(from: Date())
        }()

        let report = Report(
            date: booking?.date ?? dateStr,
            summary: "\(Array(reportVM.completedItems).prefix(2).joined(separator: ", ")) 교육 완료",
            mentorName: mentorName,
            mentorNote: reportVM.mentorNote.isEmpty ? "오늘도 수고하셨어요!" : reportVM.mentorNote,
            checklist: Array(reportVM.completedItems),
            nextItems: Array(reportVM.nextRecommendations),
            bookingId: booking?.id,
            childId: booking?.childId,
            mentorId: auth.currentUser?.id
        )

        reportStore.add(report)
        reportVM.sendReport()

        if let bookingId = booking?.id {
            bookingStore.markReportWritten(id: bookingId)
        }

        withAnimation {
            showSuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }
}

#Preview {
    let booking = BookingRecord(date: "2025년 5월 28일", rawDate: Date(),
                                plan: "원데이 효도", status: "방문 완료")
    return NavigationStack {
        ReportWriteView(booking: booking)
            .environmentObject(ReportStore())
            .environmentObject(BookingStore())
            .environmentObject(AuthViewModel())
            .environmentObject(ReportViewModel())
    }
}

struct PhotoSlot: View {
    let index: Int
    @State private var hasPhoto = false

    var body: some View {
        Button {
            hasPhoto = true
        } label: {
            ZStack {
                if hasPhoto {
                    LinearGradient(
                        colors: [Color.sonjuPrimary.opacity(0.3), Color.sonjuDeep.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                } else {
                    Color.sonjuDivider
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .foregroundColor(.sonjuSecondary)
                            .font(.system(size: 20))
                        Text("사진 추가")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                }
            }
            .frame(height: 90)
            .cornerRadius(12)
        }
        .buttonStyle(PressButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
