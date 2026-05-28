import SwiftUI

struct ReportListView: View {
    @EnvironmentObject var reportStore: ReportStore
    @EnvironmentObject var auth: AuthViewModel

    private var myReports: [Report] {
        guard let id = auth.currentUser?.id else { return reportStore.reports }
        return reportStore.reports(forChild: id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                Group {
                    if myReports.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 52))
                                .foregroundColor(.sonjuPrimary.opacity(0.4))
                            Text("아직 리포트가 없어요")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                            Text("수업이 완료되면\n안부 리포트가 이곳에 쌓여요")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuSecondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 16) {
                                ForEach(myReports) { report in
                                    NavigationLink(destination: ReportDetailView(report: report)) {
                                        ReportListCard(report: report)
                                    }
                                    .buttonStyle(PressButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("안부 리포트")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    let store = ReportStore()
    MockData.reports.forEach { store.add($0) }
    return ReportListView()
        .environmentObject(store)
        .environmentObject(AuthViewModel())
}

struct ReportListCard: View {
    let report: Report

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#FFE0A0"), Color(hex: "#FFCB6B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                HStack(spacing: 16) {
                    Image(systemName: "person.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 30)
                        .foregroundColor(.white.opacity(0.7))
                    Image(systemName: "iphone.gen2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 36)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(height: 100)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.date)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    Text(report.mentorName.isEmpty ? report.summary : "\(report.mentorName) 멘토 방문")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.sonjuSecondary)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
    }
}
