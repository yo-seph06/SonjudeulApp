import SwiftUI

/// 관리자 계정으로 로그인했을 때만 표시되는 루트 화면
struct AdminRootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            AdminMemberListView()
        }
        .tint(.sonjuPrimary)
    }
}

// MARK: - 회원가입자 명단

struct AdminMemberListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var reportStore: ReportStore
    @EnvironmentObject var scheduleStore: ScheduleStore
    @State private var members: [MemberSummary] = []
    @State private var now = Date()
    @State private var accessDenied = false
    @State private var filter: Filter = .all
    @State private var searchText = ""
    @State private var showLogoutAlert = false
    @State private var showPasswordSheet = false
    @State private var showLinkManagement = false
    @State private var showScheduleManagement = false

    enum Filter: String, CaseIterable {
        case all = "전체", child = "자녀", mentor = "멘토", pending = "탈퇴 대기"
    }

    private var pendingMembers: [MemberSummary] {
        members.filter(\.isPendingDeletion)
            .sorted { ($0.scheduledDeletionAt ?? .distantFuture) < ($1.scheduledDeletionAt ?? .distantFuture) }
    }

    private var filtered: [MemberSummary] {
        switch filter {
        case .all:     return members
        case .child:   return members.filter { $0.memberType == .child && !$0.isPendingDeletion }
        case .mentor:  return members.filter { $0.memberType == .mentor && !$0.isPendingDeletion }
        case .pending: return pendingMembers
        }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 선택한 필터 안에서 이름 또는 아이디로 검색 (대소문자 구분 없음)
    private var searched: [MemberSummary] {
        let query = trimmedSearch
        guard !query.isEmpty else { return filtered }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.username.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        Group {
            // 화면 진입 시에도 저장소 기준으로 권한을 다시 확인한다
            if accessDenied || !auth.isAdmin {
                AdminAccessDeniedView()
            } else {
                content
            }
        }
        .onAppear(perform: reload)
        // 화면을 켜둔 동안에도 1분마다 남은 기간을 다시 계산하고, 기한이 지난 계정을 영구 삭제한다
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in reload() }
    }

    private var content: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 요약
                    HStack(spacing: 10) {
                        summaryTile("전체", members.count)
                        summaryTile("자녀", members.filter { $0.memberType == .child && !$0.isPendingDeletion }.count)
                        summaryTile("멘토", members.filter { $0.memberType == .mentor && !$0.isPendingDeletion }.count)
                        summaryTile("탈퇴 대기", pendingMembers.count)
                    }
                    .padding(.horizontal, 24)

                    linkManagementEntry
                        .padding(.horizontal, 16)

                    scheduleManagementEntry
                        .padding(.horizontal, 16)

                    if !pendingMembers.isEmpty {
                        pendingSection
                            .padding(.horizontal, 16)
                    }

                    Picker("구분", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    searchField
                        .padding(.horizontal, 16)

                    SonjuCard {
                        VStack(spacing: 0) {
                            MemberTableRow(number: "번호", role: "구분", name: "이름",
                                           username: "아이디", date: "가입일", isHeader: true)
                            Divider().background(Color.sonjuDivider)

                            if searched.isEmpty {
                                Text(trimmedSearch.isEmpty ? "표시할 회원이 없어요" : "검색 결과가 없습니다.")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(searched) { member in
                                    NavigationLink(value: member.id) {
                                        MemberTableRow(
                                            number: "\(member.number)",
                                            role: member.memberType.label,
                                            name: member.name,
                                            username: member.username,
                                            date: member.createdAt.map(Self.dateText) ?? "-",
                                            isPendingDeletion: member.isPendingDeletion
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if member.id != searched.last?.id {
                                        Divider().background(Color.sonjuDivider)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Text("비밀번호와 연락처 등 민감한 정보는 표시하지 않아요")
                        .font(.system(size: 11))
                        .foregroundColor(.sonjuSecondary)
                        .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
            .refreshable { reload() }
        }
        .navigationTitle("회원 관리")
        .navigationBarTitleDisplayMode(.large)
        // 목록 화면은 스택에 남아 있으므로 돌아와도 검색어와 필터가 유지된다
        .navigationDestination(for: UUID.self) { memberId in
            AdminMemberDetailView(member: members.first { $0.id == memberId },
                                  allMembers: members, now: now)
        }
        .navigationDestination(isPresented: $showLinkManagement) {
            AdminLinkManagementView()
        }
        .navigationDestination(isPresented: $showScheduleManagement) {
            AdminScheduleManagementView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showLinkManagement = true } label: {
                        Label("자녀·멘토 연결 관리", systemImage: "link")
                    }
                    Button { showScheduleManagement = true } label: {
                        Label("일정 관리", systemImage: "calendar")
                    }
                    Button { showPasswordSheet = true } label: {
                        Label("관리자 비밀번호 변경", systemImage: "key.fill")
                    }
                    Button(role: .destructive) { showLogoutAlert = true } label: {
                        Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.sonjuText)
                }
            }
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive) { auth.logout() }
        } message: {
            Text("정말 로그아웃 하시겠어요?")
        }
        .sheet(isPresented: $showPasswordSheet) {
            AdminPasswordChangeView()
                .environmentObject(auth)
        }
    }

    /// 탈퇴 대기 회원: 이름 · 유형 · 상태 · 탈퇴 신청일 · 영구 삭제까지
    private var pendingSection: some View {
        SonjuCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("탈퇴 대기 회원")
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)
                    Spacer()
                    Text("\(DeletionPolicy.gracePeriodDays)일 후 영구 삭제")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                }
                .padding(.bottom, 10)

                PendingTableRow(name: "이름", type: "유형", status: "상태",
                                requested: "탈퇴 신청일", remaining: "영구 삭제까지", isHeader: true)
                Divider().background(Color.sonjuDivider)
                ForEach(pendingMembers) { member in
                    PendingTableRow(
                        name: member.name,
                        type: member.memberType.label,
                        status: "탈퇴 대기",
                        requested: member.deletionRequestedAt.map(Self.shortDateText) ?? "-",
                        remaining: member.scheduledDeletionAt.map {
                            DeletionPolicy.remainingLabel(until: $0, now: now)
                        } ?? "-",
                        detail: member.scheduledDeletionAt.map {
                            "\(member.username) · \(DeletionPolicy.dateTimeText($0)) 삭제 예정"
                        }
                    )
                    if member.id != pendingMembers.last?.id {
                        Divider().background(Color.sonjuDivider)
                    }
                }
            }
        }
    }

    private var linkManagementEntry: some View {
        adminMenuEntry(title: "자녀·멘토 연결 관리", systemImage: "link") { showLinkManagement = true }
    }

    private var scheduleManagementEntry: some View {
        adminMenuEntry(title: "일정 관리", systemImage: "calendar") { showScheduleManagement = true }
    }

    private func adminMenuEntry(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sonjuPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.sonjuPrimary.opacity(0.12))
                    .cornerRadius(10)
                Text(title)
                    .font(.sonjuHeadline)
                    .foregroundColor(.sonjuText)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.sonjuSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.sonjuCard)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.sonjuSecondary)
            TextField("이름 또는 아이디로 검색", text: $searchText)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.sonjuSecondary)
                }
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.sonjuDivider, lineWidth: 1)
        )
    }

    private func summaryTile(_ title: String, _ count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.sonjuTitle)
                .foregroundColor(.sonjuText)
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

    private func reload() {
        now = Date()
        guard auth.isAdmin else {
            members = []
            accessDenied = true
            return
        }
        // 화면에서 숨기기 전에 실제 데이터에서 유예기간이 끝난 계정을 영구 삭제한다
        AccountPurger.purgeExpiredAccounts(bookingStore: bookingStore, reportStore: reportStore,
                                           scheduleStore: scheduleStore, now: now)
        do {
            members = try UserStore.shared.memberList(requestedBy: auth.currentUser?.id, now: now)
            accessDenied = false
        } catch {
            members = []
            accessDenied = true
        }
    }

    private static func shortDateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "MM/dd HH:mm"
        return f.string(from: date)
    }

    fileprivate static func dateText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

private struct MemberTableRow: View {
    let number: String
    let role: String
    let name: String
    let username: String
    let date: String
    var isHeader = false
    var isPendingDeletion = false

    var body: some View {
        HStack(spacing: 6) {
            Text(number).frame(width: 30, alignment: .leading)
            Group {
                if isHeader {
                    Text(role)
                } else {
                    BadgeView(text: isPendingDeletion ? "탈퇴 대기" : role,
                              color: isPendingDeletion ? .red
                                  : (role == "멘토" ? Color(hex: "#2196F3") : .sonjuPrimary))
                }
            }
            .frame(width: isPendingDeletion ? 70 : 52, alignment: .leading)
            Text(name).frame(maxWidth: .infinity, alignment: .leading)
            Text(username).frame(maxWidth: .infinity, alignment: .leading)
            Text(date).frame(width: 78, alignment: .trailing)
        }
        .font(isHeader ? .system(size: 12, weight: .semibold) : .system(size: 13))
        .foregroundColor(isHeader ? .sonjuSecondary : (isPendingDeletion ? .sonjuSecondary : .sonjuText))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.vertical, isHeader ? 8 : 12)
    }
}

private struct PendingTableRow: View {
    let name: String
    let type: String
    let status: String
    let requested: String
    let remaining: String
    var detail: String? = nil
    var isHeader = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(name).frame(maxWidth: .infinity, alignment: .leading)
                Text(type).frame(width: 34, alignment: .leading)
                Text(status).frame(width: 56, alignment: .leading)
                    .foregroundColor(isHeader ? .sonjuSecondary : .red)
                Text(requested).frame(width: 74, alignment: .leading)
                Text(remaining).frame(width: 78, alignment: .trailing)
                    .foregroundColor(isHeader ? .sonjuSecondary : .sonjuDeep)
                    .fontWeight(isHeader ? .semibold : .bold)
            }
            if let detail {
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(.sonjuSecondary)
            }
        }
        .font(isHeader ? .system(size: 12, weight: .semibold) : .system(size: 13))
        .foregroundColor(isHeader ? .sonjuSecondary : .sonjuText)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.vertical, isHeader ? 8 : 10)
    }
}

// MARK: - 회원 상세

/// 관리자 전용 회원 상세 (조회만 가능). 비밀번호·연락처 등 민감한 정보는 표시하지 않는다.
private struct AdminMemberDetailView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @ObservedObject private var linkStore = MemberLinkStore.shared
    /// 목록이 다시 불러와지는 동안 영구 삭제되면 nil
    let member: MemberSummary?
    let allMembers: [MemberSummary]
    let now: Date

    private static let noInfo = "정보 없음"

    /// 예약 기록에서 연결된 상대 회원 (중복 제거, 처음 연결된 순서 유지)
    private struct LinkedMember: Identifiable {
        let id: UUID
        let name: String
        let username: String?
    }

    var body: some View {
        Group {
            if !auth.isAdmin {
                AdminAccessDeniedView()
            } else if let member {
                content(member)
            } else {
                notFound
            }
        }
        .navigationTitle("회원 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ member: MemberSummary) -> some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    section("기본 정보") {
                        infoRow("이름", member.name)
                        rowDivider
                        infoRow("아이디", member.username)
                        rowDivider
                        infoRow("회원 유형", member.memberType.label)
                        rowDivider
                        infoRow("가입일", member.createdAt.map(AdminMemberListView.dateText) ?? Self.noInfo)
                        rowDivider
                        infoRow("계정 상태", statusLabel(member.status),
                                color: member.isPendingDeletion ? .red : .sonjuSuccess)
                    }

                    if member.isPendingDeletion {
                        section("탈퇴 정보") {
                            infoRow("탈퇴 요청일",
                                    member.deletionRequestedAt.map(DeletionPolicy.dateTimeText) ?? Self.noInfo)
                            rowDivider
                            infoRow("삭제 예정일",
                                    member.scheduledDeletionAt.map(DeletionPolicy.dateTimeText) ?? Self.noInfo)
                            rowDivider
                            infoRow("남은 기간",
                                    member.scheduledDeletionAt.map {
                                        DeletionPolicy.remainingLabel(until: $0, now: now)
                                    } ?? Self.noInfo,
                                    color: .sonjuDeep)
                        }
                    }

                    // 관리자가 지정한 연결 (자녀·멘토 연결 관리)
                    if let side = MemberSide(member.memberType) {
                        adminLinkSection(member, side: side)
                    }

                    switch member.memberType {
                    case .child:  linkedSection("예약 기록상 멘토", linkedMentors(of: member.id))
                    case .mentor: linkedSection("예약 기록상 자녀", linkedChildren(of: member.id))
                    case .admin:  EmptyView()
                    }

                    Text("비밀번호와 연락처 등 민감한 정보는 표시하지 않아요")
                        .font(.system(size: 11))
                        .foregroundColor(.sonjuSecondary)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
    }

    private var notFound: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 44))
                    .foregroundColor(.sonjuPrimary.opacity(0.6))
                Text("회원 정보를 찾을 수 없어요")
                    .font(.sonjuHeadline)
                    .foregroundColor(.sonjuText)
                Text("이미 영구 삭제된 회원일 수 있어요")
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
            }
            .padding(24)
        }
    }

    // MARK: 연결 정보 (예약 기록 기준)

    private func linkedMentors(of childId: UUID) -> [LinkedMember] {
        var seen = Set<UUID>()
        return bookingStore.bookings.compactMap { booking in
            guard booking.childId == childId, let mentorId = booking.mentorId,
                  seen.insert(mentorId).inserted else { return nil }
            if let mentor = allMembers.first(where: { $0.id == mentorId }) {
                return LinkedMember(id: mentorId, name: mentor.name, username: mentor.username)
            }
            // 명단에 없는 멘토는 예약에 저장된 이름만 표시한다
            let name = booking.mentorName.trimmingCharacters(in: .whitespaces)
            return LinkedMember(id: mentorId, name: name.isEmpty ? Self.noInfo : name, username: nil)
        }
    }

    private func linkedChildren(of mentorId: UUID) -> [LinkedMember] {
        var seen = Set<UUID>()
        return bookingStore.bookings.compactMap { booking in
            guard booking.mentorId == mentorId, let childId = booking.childId,
                  seen.insert(childId).inserted else { return nil }
            let child = allMembers.first { $0.id == childId }
            return LinkedMember(id: childId, name: child?.name ?? Self.noInfo, username: child?.username)
        }
    }

    private func adminLinkSection(_ member: MemberSummary, side: MemberSide) -> some View {
        let linked = LinkLookup.counterparts(of: member, in: allMembers, store: linkStore)
        return section("연결된 \(side.counterpart.title)") {
            if linked.isEmpty {
                Text(side.emptyMessage)
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(linked) { other in
                    infoRow(other.name, other.username)
                    if other.id != linked.last?.id { rowDivider }
                }
            }
        }
    }

    private func linkedSection(_ title: String, _ linked: [LinkedMember]) -> some View {
        section(title) {
            if linked.isEmpty {
                Text(Self.noInfo)
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(linked) { item in
                    infoRow(item.name, item.username ?? Self.noInfo)
                    if item.id != linked.last?.id { rowDivider }
                }
            }
        }
    }

    // MARK: 공통 UI

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        SonjuCard {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.sonjuHeadline)
                    .foregroundColor(.sonjuText)
                    .padding(.bottom, 8)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func infoRow(_ label: String, _ value: String, color: Color = .sonjuText) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(.sonjuBody)
                .foregroundColor(value == Self.noInfo ? .sonjuSecondary : color)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
    }

    private var rowDivider: some View {
        Divider().background(Color.sonjuDivider)
    }

    private func statusLabel(_ status: AccountStatus) -> String {
        switch status {
        case .active:          return "정상"
        case .deletionPending: return "탈퇴 대기"
        case .deleted:         return "삭제됨"
        }
    }
}

// MARK: - 접근 차단

struct AdminAccessDeniedView: View {
    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.sonjuPrimary.opacity(0.6))
                Text("접근 권한이 없어요")
                    .font(.sonjuHeadline)
                    .foregroundColor(.sonjuText)
                Text("회원 관리는 관리자만 이용할 수 있어요")
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
            }
        }
    }
}

// MARK: - 관리자 비밀번호 변경

private struct AdminPasswordChangeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var message = ""
    @State private var done = false

    private var canSave: Bool {
        !current.isEmpty && newPassword.count >= 8 && newPassword == confirm
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    field("현재 비밀번호", $current)
                    field("새 비밀번호 (8자 이상)", $newPassword)
                    field("새 비밀번호 확인", $confirm)
                    if !message.isEmpty {
                        Text(message)
                            .font(.sonjuCaption)
                            .foregroundColor(done ? .sonjuSuccess : .red)
                    }
                    AmberButton(title: "변경하기", disabled: !canSave) {
                        do {
                            try auth.changePassword(current: current, new: newPassword)
                            done = true
                            message = "비밀번호가 변경되었어요"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss() }
                        } catch {
                            done = false
                            message = "현재 비밀번호가 올바르지 않아요"
                        }
                    }
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("비밀번호 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.sonjuText)
                }
            }
        }
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
            SecureField(label, text: text)
                .font(.sonjuBody)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.sonjuDivider, lineWidth: 1)
                )
        }
    }
}

#Preview {
    AdminRootView()
        .environmentObject(AuthViewModel())
        .environmentObject(BookingStore())
        .environmentObject(ReportStore())
        .environmentObject(ScheduleStore())
}
