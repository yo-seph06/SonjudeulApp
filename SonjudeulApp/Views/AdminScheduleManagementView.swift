import SwiftUI

// MARK: - 일정 관리 (관리자)

/// 관리자 전용 일정 관리.
/// - 방문 일정(BookingRecord, 자녀·멘토 공유): 상세 조회, 미완료 일정의 날짜·시간 변경과 삭제
/// - 개인 일정(ScheduleEvent, 작성자 본인 전용): 건수만 표시 (제목·메모는 저장소에서도 관리자에게 주지 않음)
/// - 휴대전화 캘린더 일정: 각 회원이 로그인한 화면에서만 메모리로 읽으므로 관리자는 볼 수 없음
struct AdminScheduleManagementView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var scheduleStore: ScheduleStore
    @State private var members: [MemberSummary] = []
    @State private var accessDenied = false
    @State private var period: Period = .upcoming
    @State private var searchText = ""
    @State private var now = Date()

    enum Period: String, CaseIterable {
        case upcoming = "다가오는 일정", past = "지난 일정"
    }

    /// 저장소에서 권한을 확인한 뒤 받은 방문 일정 (id 기준 1건씩)
    private var visits: [BookingRecord] {
        guard let all = try? bookingStore.adminVisits(requestedBy: auth.currentUser?.id) else { return [] }
        var seen = Set<UUID>()
        return all.filter { seen.insert($0.id).inserted }
    }

    private var upcomingVisits: [BookingRecord] {
        visits.filter { $0.rawDate >= now }.sorted { $0.rawDate < $1.rawDate }
    }

    private var pastVisits: [BookingRecord] {
        visits.filter { $0.rawDate < now }.sorted { $0.rawDate > $1.rawDate }
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var rows: [BookingRecord] {
        let base = period == .upcoming ? upcomingVisits : pastVisits
        let query = VisitSearch.normalize(trimmedSearch)
        guard !query.isEmpty else { return base }
        return base.filter { VisitSearch.matches($0, query: query, members: members) }
    }

    private var personalCounts: (total: Int, upcoming: Int)? {
        scheduleStore.personalScheduleCounts(requestedBy: auth.currentUser?.id, now: now)
    }

    var body: some View {
        Group {
            if accessDenied || !auth.isAdmin {
                AdminAccessDeniedView()
            } else {
                content
            }
        }
        .navigationTitle("일정 관리")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
    }

    private var content: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        ScheduleSummaryTile(title: "다가오는 방문", count: upcomingVisits.count)
                        ScheduleSummaryTile(title: "지난 방문", count: pastVisits.count)
                        ScheduleSummaryTile(title: "개인 일정", count: personalCounts?.total ?? 0)
                    }
                    .padding(.horizontal, 8)

                    personalScheduleNotice

                    Picker("기간", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)

                    ScheduleSearchField(text: $searchText, placeholder: "날짜(예: 10월 20일) 또는 일정 제목")

                    SonjuCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("방문 일정")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                                .padding(.bottom, 4)
                            if rows.isEmpty {
                                Text(trimmedSearch.isEmpty
                                     ? (period == .upcoming ? "다가오는 방문 일정이 없어요" : "지난 방문 일정이 없어요")
                                     : "검색 결과가 없습니다.")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(rows) { visit in
                                    // isPresented로 열린 화면이라 값 기반 링크를 쓰면 이 화면이 한 번 더 쌓이므로 목적지를 직접 지정한다
                                    NavigationLink {
                                        AdminVisitDetailView(visitId: visit.id, members: members)
                                    } label: {
                                        VisitOverviewRow(visit: visit, members: members)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if visit.id != rows.last?.id {
                                        Divider().background(Color.sonjuDivider)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("이 기기에 저장된 일정만 표시돼요. 휴대전화 캘린더 일정은 각 회원의 기기에서만 읽기 때문에 관리자 화면에서 볼 수 없어요.")
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

    private var personalScheduleNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.sonjuPrimary)
                .frame(width: 32, height: 32)
                .background(Color.sonjuPrimary.opacity(0.12))
                .cornerRadius(10)
            VStack(alignment: .leading, spacing: 4) {
                Text("개인 일정 \(personalCounts?.total ?? 0)건 · 다가오는 일정 \(personalCounts?.upcoming ?? 0)건")
                    .font(.sonjuBody.weight(.semibold))
                    .foregroundColor(.sonjuText)
                Text("개인 일정은 작성자 본인만 볼 수 있어 제목·메모 등 내용은 표시하지 않아요.")
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
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
        do {
            members = try UserStore.shared.memberList(requestedBy: auth.currentUser?.id, now: now)
            accessDenied = false
        } catch {
            members = []
            accessDenied = true
        }
    }
}

// MARK: - 방문 일정 상세

private struct AdminVisitDetailView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @Environment(\.dismiss) private var dismiss
    let visitId: UUID
    let members: [MemberSummary]

    @State private var showReschedule = false
    @State private var showDeleteAlert = false
    @State private var errorMessage: String?

    private static let noInfo = "정보 없음"

    private var visit: BookingRecord? {
        (try? bookingStore.adminVisits(requestedBy: auth.currentUser?.id))?.first { $0.id == visitId }
    }

    var body: some View {
        Group {
            if !auth.isAdmin {
                AdminAccessDeniedView()
            } else if let visit {
                content(visit)
            } else {
                ZStack {
                    Color.sonjuBackground.ignoresSafeArea()
                    VStack(spacing: 10) {
                        Text("일정을 찾을 수 없어요")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        Text("이미 삭제된 일정일 수 있어요")
                            .font(.sonjuBody)
                            .foregroundColor(.sonjuSecondary)
                    }
                }
            }
        }
        .navigationTitle("일정 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ visit: BookingRecord) -> some View {
        let editable = BookingStore.isAdminEditable(visit)
        let people = VisitPeople(visit: visit, members: members)

        return ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    detailSection("일정 정보") {
                        ScheduleInfoRow(label: "일정 구분", value: "방문 일정 (자녀·멘토 공유)")
                        divider
                        ScheduleInfoRow(label: "일정 제목", value: VisitText.title(visit))
                        divider
                        ScheduleInfoRow(label: "날짜", value: VisitText.day(visit.rawDate))
                        divider
                        ScheduleInfoRow(label: "시작 시간", value: VisitText.time(visit.rawDate))
                        divider
                        ScheduleInfoRow(label: "종료 시간", value: Self.noInfo)
                        divider
                        ScheduleInfoRow(label: "장소", value: Self.noInfo)
                        divider
                        ScheduleInfoRow(label: "설명", value: Self.noInfo)
                        divider
                        ScheduleInfoRow(label: "상태", value: visit.status, color: visit.statusColor)
                    }

                    detailSection("관련 회원") {
                        ScheduleInfoRow(label: "자녀", value: people.childText ?? Self.noInfo)
                        divider
                        ScheduleInfoRow(label: "멘토", value: people.mentorText ?? Self.noInfo)
                    }

                    detailSection("방문 기록") {
                        ScheduleInfoRow(label: "리포트", value: visit.reportWritten ? "작성됨" : "미작성")
                        divider
                        ScheduleInfoRow(label: "평점", value: visit.rating.map { "★ \($0) / 5" } ?? Self.noInfo)
                        divider
                        ScheduleInfoRow(label: "후기",
                                        value: visit.reviewComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                            ? Self.noInfo : visit.reviewComment)
                    }

                    if editable {
                        VStack(spacing: 10) {
                            AmberButton(title: "날짜·시간 변경", isSecondary: true) { showReschedule = true }
                            Button { showDeleteAlert = true } label: {
                                Text("일정 삭제")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(14)
                            }
                        }
                    } else {
                        Text("방문 완료된 일정은 평점·리포트·멘토 통계에 쓰여 수정하거나 삭제할 수 없어요.")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.sonjuCaption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showReschedule) {
            VisitRescheduleView(visit: visit, people: people)
                .environmentObject(auth)
                .environmentObject(bookingStore)
        }
        .alert("일정 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) { delete(visit) }
        } message: {
            Text("\(VisitText.title(visit))\n\(VisitText.day(visit.rawDate)) \(VisitText.time(visit.rawDate))\n자녀: \(people.childText ?? Self.noInfo)\n멘토: \(people.mentorText ?? Self.noInfo)\n\n이 일정을 삭제할까요? 삭제하면 되돌릴 수 없어요.")
        }
    }

    private var divider: some View { Divider().background(Color.sonjuDivider) }

    private func detailSection<Content: View>(_ title: String,
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

    private func delete(_ visit: BookingRecord) {
        do {
            try bookingStore.adminDelete(id: visit.id, requestedBy: auth.currentUser?.id)
            AdminAlertStore.shared.record(
                key: "visit-delete:\(visit.id)", category: .adminAction, title: "방문 일정 삭제",
                message: "\(VisitText.title(visit)) 일정(\(visit.date))을 삭제했어요.",
                target: .scheduleManagement, isRead: true)
            errorMessage = nil
            dismiss()
        } catch let error as VisitAdminError {
            errorMessage = error.message
        } catch {
            errorMessage = VisitAdminError.saveFailed.message
        }
    }
}

// MARK: - 날짜·시간 변경

private struct VisitRescheduleView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @Environment(\.dismiss) private var dismiss
    let visit: BookingRecord
    let people: VisitPeople

    @State private var newDate: Date
    @State private var showConfirm = false
    @State private var errorMessage: String?

    init(visit: BookingRecord, people: VisitPeople) {
        self.visit = visit
        self.people = people
        _newDate = State(initialValue: max(visit.rawDate, Date().addingTimeInterval(3600)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("변경할 일정")
                                    .font(.sonjuHeadline)
                                    .foregroundColor(.sonjuText)
                                    .padding(.bottom, 8)
                                ScheduleInfoRow(label: "일정 제목", value: VisitText.title(visit))
                                Divider().background(Color.sonjuDivider)
                                ScheduleInfoRow(label: "현재 일시", value: visit.date)
                                Divider().background(Color.sonjuDivider)
                                ScheduleInfoRow(label: "자녀", value: people.childText ?? "정보 없음")
                                Divider().background(Color.sonjuDivider)
                                ScheduleInfoRow(label: "멘토", value: people.mentorText ?? "정보 없음")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("새 날짜")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        DatePicker("", selection: $newDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .accentColor(.sonjuPrimary)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(16)

                        HStack {
                            Text("새 시작 시간")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                            Spacer()
                            DatePicker("", selection: $newDate, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .accentColor(.sonjuPrimary)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                        }

                        AmberButton(title: "변경하기") { showConfirm = true }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("날짜·시간 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.sonjuText)
                }
            }
            .alert("일정 변경", isPresented: $showConfirm) {
                Button("취소", role: .cancel) {}
                Button("변경") { save() }
            } message: {
                Text("\(VisitText.title(visit))\n자녀: \(people.childText ?? "정보 없음")\n멘토: \(people.mentorText ?? "정보 없음")\n\n변경 전: \(visit.date)\n변경 후: \(BookingStore.displayDateText(newDate)) (\(VisitText.time(newDate)))\n\n일정을 변경할까요?")
            }
        }
    }

    private func save() {
        do {
            try bookingStore.adminReschedule(id: visit.id, to: newDate, requestedBy: auth.currentUser?.id)
            AdminAlertStore.shared.record(
                key: "visit-reschedule:\(visit.id):\(Int(newDate.timeIntervalSince1970))", category: .adminAction,
                title: "방문 일정 변경",
                message: "\(VisitText.title(visit)) 일정을 \(visit.date)에서 \(BookingStore.displayDateText(newDate))(으)로 변경했어요.",
                target: .scheduleManagement, isRead: true)
            dismiss()
        } catch let error as VisitAdminError {
            errorMessage = error.message
        } catch {
            errorMessage = VisitAdminError.saveFailed.message
        }
    }
}

// MARK: - 공통

/// 방문 일정의 관련 회원. 회원 명단에서 ID로 찾고, 없으면 예약에 저장된 멘토 이름만 쓴다.
private struct VisitPeople {
    let childText: String?
    let mentorText: String?

    init(visit: BookingRecord, members: [MemberSummary]) {
        let child = visit.childId.flatMap { id in members.first { $0.id == id } }
        let mentor = visit.mentorId.flatMap { id in members.first { $0.id == id } }
        childText = child.map { "\($0.name) (\($0.username))" }
        let storedName = visit.mentorName.trimmingCharacters(in: .whitespaces)
        mentorText = mentor.map { "\($0.name) (\($0.username))" } ?? (storedName.isEmpty ? nil : storedName)
    }
}

private enum VisitText {
    static func title(_ visit: BookingRecord) -> String {
        let plan = visit.plan.trimmingCharacters(in: .whitespaces)
        return plan.isEmpty ? "방문 일정" : "방문 · \(plan)"
    }

    static func day(_ date: Date) -> String { format(date, "yyyy년 M월 d일 (E)") }
    static func time(_ date: Date) -> String { format(date, "a h:mm") }

    static func format(_ date: Date, _ pattern: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = pattern
        return f.string(from: date)
    }
}

/// 날짜(여러 표기)·일정 제목·관련 회원 이름/아이디로 검색. 공백은 무시한다.
private enum VisitSearch {
    static func normalize(_ text: String) -> String {
        text.lowercased().filter { !$0.isWhitespace }
    }

    static func matches(_ visit: BookingRecord, query: String, members: [MemberSummary]) -> Bool {
        let d = visit.rawDate
        var fields = [visit.date, VisitText.title(visit), visit.status,
                      VisitText.format(d, "yyyy-MM-dd"), VisitText.format(d, "yyyy.MM.dd"),
                      VisitText.format(d, "yyyy.M.d"), VisitText.format(d, "M/d"),
                      VisitText.format(d, "MM/dd"), VisitText.format(d, "M월 d일"),
                      VisitText.format(d, "yyyy년 M월 d일")]
        let people = VisitPeople(visit: visit, members: members)
        fields += [people.childText, people.mentorText].compactMap { $0 }
        return fields.contains { normalize($0).contains(query) }
    }
}

private struct VisitOverviewRow: View {
    let visit: BookingRecord
    let members: [MemberSummary]

    var body: some View {
        let people = VisitPeople(visit: visit, members: members)
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(VisitText.title(visit))
                        .font(.sonjuBody.weight(.semibold))
                        .foregroundColor(.sonjuText)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    BadgeView(text: visit.status, color: visit.statusColor)
                        .fixedSize()
                }
                Text("\(VisitText.day(visit.rawDate)) · \(VisitText.time(visit.rawDate)) 시작")
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("자녀 \(people.childText ?? "정보 없음") · 멘토 \(people.mentorText ?? "정보 없음")")
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.sonjuSecondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
    }
}

private struct ScheduleInfoRow: View {
    let label: String
    let value: String
    var color: Color = .sonjuText

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.sonjuBody)
                .foregroundColor(value == "정보 없음" ? .sonjuSecondary : color)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
    }
}

private struct ScheduleSummaryTile: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.sonjuTitle)
                .foregroundColor(.sonjuText)
            Text(title)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.sonjuCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

private struct ScheduleSearchField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.sonjuSecondary)
            TextField(placeholder, text: $text)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
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
}
