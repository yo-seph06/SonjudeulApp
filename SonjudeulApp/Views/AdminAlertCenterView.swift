import SwiftUI

// MARK: - 알림 센터 (관리자)

/// 관리자 전용 앱 내부 알림 센터. 푸시 알림은 보내지 않는다.
struct AdminAlertCenterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var alertStore = AdminAlertStore.shared
    @State private var members: [MemberSummary] = []
    @State private var accessDenied = false
    @State private var filter: Filter = .all
    @State private var now = Date()

    enum Filter: String, CaseIterable {
        case all = "전체", unread = "읽지 않음"
    }

    private var adminId: UUID? { auth.currentUser?.id }

    private var alerts: [AdminAlert] {
        let all = alertStore.alerts(requestedBy: adminId)
        return filter == .all ? all : all.filter { !$0.isRead }
    }

    private var unreadCount: Int { alertStore.unreadCount(requestedBy: adminId) }

    var body: some View {
        Group {
            if accessDenied || !auth.isAdmin {
                AdminAccessDeniedView()
            } else {
                content
            }
        }
        .navigationTitle("알림 센터")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if auth.isAdmin && unreadCount > 0 {
                    Button("모두 읽음") { alertStore.markAllRead(requestedBy: adminId) }
                        .foregroundColor(.sonjuDeep)
                }
            }
        }
        .onAppear(perform: reload)
    }

    private var content: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        AlertSummaryTile(title: "읽지 않음", count: unreadCount, highlight: unreadCount > 0)
                        AlertSummaryTile(title: "전체 알림", count: alertStore.alerts(requestedBy: adminId).count)
                    }
                    .padding(.horizontal, 8)

                    Picker("구분", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)

                    SonjuCard {
                        VStack(alignment: .leading, spacing: 0) {
                            if alerts.isEmpty {
                                Text(filter == .all ? "알림이 없어요" : "읽지 않은 알림이 없어요")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(alerts) { alert in
                                    row(alert)
                                    if alert.id != alerts.last?.id {
                                        Divider().background(Color.sonjuDivider)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("앱 안에서 확인한 회원·연결 데이터와 관리자 작업으로만 알림을 만들어요. 푸시 알림은 보내지 않아요.")
                        .font(.system(size: 11))
                        .foregroundColor(.sonjuSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .refreshable { reload() }
        }
    }

    @ViewBuilder
    private func row(_ alert: AdminAlert) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if let target = alert.target {
                // isPresented로 열린 화면이므로 값 기반 링크 대신 목적지를 직접 지정한다
                NavigationLink {
                    destination(for: target)
                } label: {
                    AlertRowContent(alert: alert, showsChevron: true)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded {
                    alertStore.setRead(true, id: alert.id, requestedBy: adminId)
                })
            } else {
                Button {
                    alertStore.setRead(true, id: alert.id, requestedBy: adminId)
                } label: {
                    AlertRowContent(alert: alert, showsChevron: false)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                alertStore.setRead(!alert.isRead, id: alert.id, requestedBy: adminId)
            } label: {
                Image(systemName: alert.isRead ? "envelope.badge" : "envelope.open")
                    .font(.system(size: 16))
                    .foregroundColor(.sonjuSecondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(alert.isRead ? "읽지 않음으로 표시" : "읽음으로 표시")
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private func destination(for target: AdminAlert.Target) -> some View {
        switch target {
        case .member(let id):
            AdminMemberDetailView(member: members.first { $0.id == id }, allMembers: members, now: now)
        case .linkManagement:
            AdminLinkManagementView()
        case .scheduleManagement:
            AdminScheduleManagementView()
        }
    }

    private func reload() {
        now = Date()
        guard auth.isAdmin else {
            members = []
            accessDenied = true
            return
        }
        do {
            members = try UserStore.shared.memberList(requestedBy: adminId, now: now)
            accessDenied = false
            alertStore.refresh(requestedBy: adminId, now: now)
        } catch {
            members = []
            accessDenied = true
        }
    }
}

// MARK: - 구성 요소

private struct AlertRowContent: View {
    let alert: AdminAlert
    let showsChevron: Bool

    private var icon: (name: String, color: Color) {
        switch alert.category {
        case .signup:        return ("person.badge.plus", .sonjuSuccess)
        case .deletion:      return ("person.crop.circle.badge.xmark", .red)
        case .link:          return ("link.badge.plus", Color(hex: "#2196F3"))
        case .dataIntegrity: return ("exclamationmark.triangle.fill", .orange)
        case .security:      return ("lock.shield.fill", .sonjuDeep)
        case .adminAction:   return ("checkmark.seal.fill", .sonjuSecondary)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(icon.color)
                .frame(width: 34, height: 34)
                .background(icon.color.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if !alert.isRead {
                        Circle()
                            .fill(Color.sonjuPrimary)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("읽지 않음")
                    }
                    Text(alert.title)
                        .font(.sonjuBody.weight(alert.isRead ? .regular : .semibold))
                        .foregroundColor(.sonjuText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(alert.message)
                    .font(.sonjuCaption)
                    .foregroundColor(alert.isRead ? .sonjuSecondary : .sonjuText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(alert.category.label)
                    Text("·")
                    Text(DeletionPolicy.dateTimeText(alert.occurredAt))
                    Text("·")
                    Text(alert.isRead ? "읽음" : "읽지 않음")
                }
                .font(.system(size: 11))
                .foregroundColor(.sonjuSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sonjuSecondary)
                    .padding(.top, 10)
            }
        }
        .padding(.vertical, 12)
    }
}

private struct AlertSummaryTile: View {
    let title: String
    let count: Int
    var highlight = false

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.sonjuTitle)
                .foregroundColor(highlight ? .sonjuDeep : .sonjuText)
            Text(title)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.sonjuCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
