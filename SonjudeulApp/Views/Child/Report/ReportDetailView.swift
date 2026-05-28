import SwiftUI

struct ReportDetailView: View {
    let report: Report
    @State private var appeared = false
    @State private var showShare = false

    private var shareText: String {
        var lines = ["📋 안부 리포트 - \(report.date)"]
        if !report.mentorName.isEmpty { lines.append("담당 멘토: \(report.mentorName)") }
        if !report.checklist.isEmpty { lines.append("\n✅ 교육 완료\n" + report.checklist.map { "• \($0)" }.joined(separator: "\n")) }
        if !report.mentorNote.isEmpty { lines.append("\n💬 멘토 한마디\n\(report.mentorNote)") }
        if !report.nextItems.isEmpty { lines.append("\n➡️ 다음 추천\n" + report.nextItems.joined(separator: ", ")) }
        lines.append("\n손주들 앱에서 확인하세요 🌿")
        return lines.joined(separator: "\n")
    }

    // Icon config per checklist item index
    let itemConfigs: [(icon: String, bg: Color)] = [
        ("iphone.gen2.fill",       Color(hex: "#E91E8C")),
        ("envelope.badge.fill",    Color(hex: "#1565C0")),
        ("bag.fill",               Color.sonjuPrimary),
        ("heart.fill",             Color.sonjuSuccess)
    ]

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Large top photo
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "#FFE0A0"), Color(hex: "#FFCB6B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        HStack(spacing: 30) {
                            // Elderly figure
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Color(hex: "#FFD5A0"))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable().scaledToFit().frame(width: 28)
                                            .foregroundColor(Color(hex: "#B07030"))
                                            .offset(y: 8)
                                    )
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "#C8853A"))
                                    .frame(width: 44, height: 60)
                            }

                            // Phone with smile
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#424242"))
                                    .frame(width: 40, height: 70)
                                RoundedRectangle(cornerRadius: 9)
                                    .fill(Color.white.opacity(0.95))
                                    .frame(width: 32, height: 56)
                                Text("😊")
                                    .font(.system(size: 20))
                            }

                            // Young figure
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Color(hex: "#FFCCA0"))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable().scaledToFit().frame(width: 30)
                                            .foregroundColor(Color(hex: "#9A5020"))
                                            .offset(y: 8)
                                    )
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.sonjuPrimary)
                                    .frame(width: 50, height: 66)
                            }
                        }

                        // Floating hearts
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.white.opacity(0.5))
                                    .font(.system(size: 24))
                                    .offset(x: -20, y: 20)
                            }
                            Spacer()
                        }
                    }
                    .frame(height: 220)
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.45), value: appeared)

                    VStack(spacing: 20) {
                        // Date + title
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.date.replacingOccurrences(of: "년 ", with: ".").replacingOccurrences(of: "월 ", with: ".").replacingOccurrences(of: "일", with: "") + " 방문 리포트")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Mentor info
                        if !report.mentorName.isEmpty {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color.sonjuPrimary.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text(String(report.mentorName.prefix(1)))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.sonjuPrimary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(report.mentorName) 멘토")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                    Text("방문 리포트")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuText)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }

                        // Checklist
                        if !report.checklist.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(Array(report.checklist.enumerated()), id: \.offset) { index, item in
                                    ReportCheckRow(
                                        icon: itemConfigs[index % itemConfigs.count].icon,
                                        bgColor: itemConfigs[index % itemConfigs.count].bg,
                                        text: item
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Mentor note
                        if !report.mentorNote.isEmpty {
                            SonjuCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "quote.bubble.fill")
                                            .foregroundColor(.sonjuPrimary)
                                        Text("멘토 한마디")
                                            .font(.sonjuHeadline)
                                            .foregroundColor(.sonjuText)
                                    }
                                    Text(report.mentorNote)
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuText)
                                        .lineSpacing(4)
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        // Next items
                        if !report.nextItems.isEmpty {
                            SonjuCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundColor(.sonjuPrimary)
                                        Text("다음 방문 추천")
                                            .font(.sonjuHeadline)
                                            .foregroundColor(.sonjuText)
                                    }
                                    FlowLayout(items: report.nextItems) { item in
                                        Text(item)
                                            .font(.sonjuCaption)
                                            .foregroundColor(.sonjuPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.sonjuPrimary.opacity(0.1))
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        AmberButton(title: "공유하기") {
                            showShare = true
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
        .navigationTitle("안부 리포트")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "calendar")
                    .foregroundColor(.sonjuPrimary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportDetailView(report: MockData.reports[0])
    }
}

struct ReportCheckRow: View {
    let icon: String
    let bgColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(bgColor)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.sonjuSuccess)
                .font(.system(size: 18))
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
