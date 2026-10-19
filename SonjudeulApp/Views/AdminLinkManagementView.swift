import SwiftUI

// MARK: - 자녀·멘토 연결 관리

/// 관리자 전용: 자녀·멘토 연결 현황 확인, 연결 및 해제
struct AdminLinkManagementView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var linkStore = MemberLinkStore.shared
    @State private var members: [MemberSummary] = []
    @State private var accessDenied = false
    @State private var side: MemberSide = .child
    @State private var linkFilter: LinkFilter = .all
    @State private var searchText = ""

    enum LinkFilter: String, CaseIterable {
        case all = "전체", linked = "연결됨", unlinked = "미연결"
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sideMembers: [MemberSummary] {
        members.filter { $0.memberType == side.memberType }
    }

    private var rows: [MemberSummary] {
        let query = trimmedSearch
        return sideMembers.filter { member in
            let linked = LinkLookup.counterparts(of: member, in: members, store: linkStore)
            switch linkFilter {
            case .all:      break
            case .linked:   if linked.isEmpty { return false }
            case .unlinked: if !linked.isEmpty { return false }
            }
            guard !query.isEmpty else { return true }
            // 본인 또는 연결된 상대의 이름·아이디로 검색
            return ([member] + linked).contains {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.username.localizedCaseInsensitiveContains(query)
            }
        }
    }

    private func unlinkedCount(_ type: MemberType) -> Int {
        members.filter {
            $0.memberType == type && LinkLookup.counterparts(of: $0, in: members, store: linkStore).isEmpty
        }.count
    }

    private var activeLinkCount: Int {
        let ids = Set(members.map(\.id))
        return linkStore.links.filter { ids.contains($0.childId) && ids.contains($0.mentorId) }.count
    }

    var body: some View {
        Group {
            if accessDenied || !auth.isAdmin {
                AdminAccessDeniedView()
            } else {
                content
            }
        }
        .navigationTitle("자녀·멘토 연결 관리")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: LinkMemberRoute.self) { route in
            AdminMemberLinkDetailView(memberId: route.memberId, members: members)
        }
        .onAppear(perform: reload)
    }

    private var content: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        LinkSummaryTile(title: "연결", count: activeLinkCount)
                        LinkSummaryTile(title: "미연결 자녀", count: unlinkedCount(.child))
                        LinkSummaryTile(title: "미연결 멘토", count: unlinkedCount(.mentor))
                    }
                    .padding(.horizontal, 8)

                    Picker("회원 유형", selection: $side) {
                        ForEach(MemberSide.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)

                    Picker("연결 상태", selection: $linkFilter) {
                        ForEach(LinkFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)

                    LinkSearchField(text: $searchText, placeholder: "이름 또는 아이디로 검색")

                    SonjuCard {
                        VStack(alignment: .leading, spacing: 0) {
                            if rows.isEmpty {
                                Text(trimmedSearch.isEmpty ? "표시할 회원이 없어요" : "검색 결과가 없습니다.")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(rows) { member in
                                    NavigationLink(value: LinkMemberRoute(memberId: member.id)) {
                                        LinkOverviewRow(
                                            member: member,
                                            linked: LinkLookup.counterparts(of: member, in: members, store: linkStore)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    if member.id != rows.last?.id {
                                        Divider().background(Color.sonjuDivider)
                                    }
                                }
                            }
                        }
                    }

                    Text("연결 정책: 자녀 1명당 담당 멘토 1명, 멘토는 여러 자녀를 맡을 수 있어요")
                        .font(.system(size: 11))
                        .foregroundColor(.sonjuSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .refreshable { reload() }
        }
    }

    private func reload() {
        guard auth.isAdmin else {
            members = []
            accessDenied = true
            return
        }
        do {
            members = try UserStore.shared.memberList(requestedBy: auth.currentUser?.id)
            accessDenied = false
        } catch {
            members = []
            accessDenied = true
        }
    }
}

// MARK: - 회원별 연결 상세 (연결 / 해제)

private struct AdminMemberLinkDetailView: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject private var linkStore = MemberLinkStore.shared
    let memberId: UUID
    let members: [MemberSummary]

    @State private var showPicker = false
    @State private var pendingUnlink: PendingUnlink?
    @State private var errorMessage: String?

    private struct PendingUnlink: Identifiable {
        let id: UUID   // MemberLink.id
        let child: MemberSummary
        let mentor: MemberSummary
    }

    private var member: MemberSummary? { members.first { $0.id == memberId } }

    var body: some View {
        Group {
            if !auth.isAdmin {
                AdminAccessDeniedView()
            } else if let member, let side = MemberSide(member.memberType) {
                content(member, side: side)
            } else {
                ZStack {
                    Color.sonjuBackground.ignoresSafeArea()
                    Text("회원 정보를 찾을 수 없어요")
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)
                }
            }
        }
        .navigationTitle("연결 관리")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ member: MemberSummary, side: MemberSide) -> some View {
        let linked = LinkLookup.links(of: member, in: members, store: linkStore)
        let reachedLimit = side == .child && linked.count >= MemberLinkStore.maxMentorsPerChild
        let canLink = !member.isPendingDeletion && !reachedLimit

        return ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("대상 회원")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                                .padding(.bottom, 8)
                            LinkInfoRow(label: "이름", value: member.name)
                            Divider().background(Color.sonjuDivider)
                            LinkInfoRow(label: "아이디", value: member.username)
                            Divider().background(Color.sonjuDivider)
                            LinkInfoRow(label: "회원 유형", value: member.memberType.label)
                            Divider().background(Color.sonjuDivider)
                            LinkInfoRow(label: "계정 상태", value: member.isPendingDeletion ? "탈퇴 대기" : "정상",
                                        color: member.isPendingDeletion ? .red : .sonjuSuccess)
                        }
                    }

                    SonjuCard {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("연결된 \(side.counterpart.title)")
                                .font(.sonjuHeadline)
                                .foregroundColor(.sonjuText)
                                .padding(.bottom, 8)
                            if linked.isEmpty {
                                Text(side.emptyMessage)
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuSecondary)
                                    .padding(.vertical, 10)
                            } else {
                                ForEach(linked, id: \.link.id) { item in
                                    HStack(spacing: 12) {
                                        MemberNameLabel(member: item.other)
                                        Spacer(minLength: 8)
                                        Button("해제") {
                                            pendingUnlink = side == .child
                                                ? PendingUnlink(id: item.link.id, child: member, mentor: item.other)
                                                : PendingUnlink(id: item.link.id, child: item.other, mentor: member)
                                        }
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                    .padding(.vertical, 10)
                                    if item.link.id != linked.last?.link.id {
                                        Divider().background(Color.sonjuDivider)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(spacing: 8) {
                        AmberButton(title: "\(side.counterpart.title) 연결하기", disabled: !canLink) {
                            showPicker = true
                        }
                        if member.isPendingDeletion {
                            caption("탈퇴 대기 중인 회원은 새로 연결할 수 없어요")
                        } else if reachedLimit {
                            caption("자녀 1명에게는 담당 멘토 1명만 연결할 수 있어요. 변경하려면 기존 연결을 먼저 해제해주세요.")
                        }
                    }

                    if let errorMessage {
                        caption(errorMessage).foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showPicker) {
            LinkCandidatePicker(target: member, side: side, members: members)
                .environmentObject(auth)
        }
        .alert("연결 해제", isPresented: Binding(
            get: { pendingUnlink != nil },
            set: { if !$0 { pendingUnlink = nil } }
        ), presenting: pendingUnlink) { target in
            Button("취소", role: .cancel) {}
            Button("해제", role: .destructive) { unlink(target) }
        } message: { target in
            Text("자녀 \(target.child.name) (\(target.child.username))\n멘토 \(target.mentor.name) (\(target.mentor.username))\n\n두 회원의 연결을 해제할까요?")
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.sonjuCaption)
            .foregroundColor(.sonjuSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func unlink(_ target: PendingUnlink) {
        do {
            try linkStore.unlink(linkId: target.id, requestedBy: auth.currentUser?.id)
            errorMessage = nil
        } catch let error as MemberLinkError {
            errorMessage = error.message
        } catch {
            errorMessage = MemberLinkError.saveFailed.message
        }
    }
}

// MARK: - 연결할 상대 선택

private struct LinkCandidatePicker: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var linkStore = MemberLinkStore.shared
    let target: MemberSummary
    let side: MemberSide
    let members: [MemberSummary]

    @State private var searchText = ""
    @State private var selected: MemberSummary?
    @State private var errorMessage: String?

    private var candidates: [MemberSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyLinked = Set(LinkLookup.counterparts(of: target, in: members, store: linkStore).map(\.id))
        return members.filter { other in
            other.memberType == side.counterpart.memberType
                && !alreadyLinked.contains(other.id)
                && (query.isEmpty
                    || other.name.localizedCaseInsensitiveContains(query)
                    || other.username.localizedCaseInsensitiveContains(query))
        }
    }

    /// 선택할 수 없는 이유 (nil이면 선택 가능)
    private func blockedReason(_ other: MemberSummary) -> String? {
        if other.isPendingDeletion { return "탈퇴 대기" }
        if side == .mentor,
           linkStore.mentorIds(ofChild: other.id).count >= MemberLinkStore.maxMentorsPerChild {
            return "담당 멘토 있음"
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Text("대상")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                            MemberNameLabel(member: target)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 4)

                        LinkSearchField(text: $searchText, placeholder: "\(side.counterpart.title) 이름 또는 아이디로 검색")

                        SonjuCard {
                            VStack(alignment: .leading, spacing: 0) {
                                if candidates.isEmpty {
                                    Text(searchText.isEmpty ? "연결할 수 있는 \(side.counterpart.title)가 없어요" : "검색 결과가 없습니다.")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 24)
                                } else {
                                    ForEach(candidates) { other in
                                        let reason = blockedReason(other)
                                        Button { selected = other } label: {
                                            HStack(spacing: 12) {
                                                MemberNameLabel(member: other)
                                                Spacer(minLength: 8)
                                                if let reason {
                                                    BadgeView(text: reason, color: .sonjuSecondary)
                                                } else {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(.sonjuPrimary)
                                                }
                                            }
                                            .padding(.vertical, 10)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(reason != nil)
                                        .opacity(reason == nil ? 1 : 0.6)
                                        if other.id != candidates.last?.id {
                                            Divider().background(Color.sonjuDivider)
                                        }
                                    }
                                }
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.sonjuCaption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("\(side.counterpart.title) 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(.sonjuText)
                }
            }
            .alert("회원 연결", isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            ), presenting: selected) { other in
                Button("취소", role: .cancel) {}
                Button("연결") { link(other) }
            } message: { other in
                let (child, mentor) = side == .child ? (target, other) : (other, target)
                Text("자녀 \(child.name) (\(child.username))\n멘토 \(mentor.name) (\(mentor.username))\n\n두 회원을 연결할까요?")
            }
        }
    }

    private func link(_ other: MemberSummary) {
        let (childId, mentorId) = side == .child ? (target.id, other.id) : (other.id, target.id)
        do {
            try linkStore.link(childId: childId, mentorId: mentorId, requestedBy: auth.currentUser?.id)
            dismiss()
        } catch let error as MemberLinkError {
            errorMessage = error.message
        } catch {
            errorMessage = MemberLinkError.saveFailed.message
        }
    }
}

// MARK: - 공통

private struct LinkMemberRoute: Hashable {
    let memberId: UUID
}

enum MemberSide: CaseIterable {
    case child, mentor

    init?(_ type: MemberType) {
        switch type {
        case .child:  self = .child
        case .mentor: self = .mentor
        case .admin:  return nil
        }
    }

    var memberType: MemberType { self == .child ? .child : .mentor }
    var title: String { self == .child ? "자녀" : "멘토" }
    var counterpart: MemberSide { self == .child ? .mentor : .child }
    var emptyMessage: String { self == .child ? "연결된 멘토가 없습니다." : "연결된 자녀가 없습니다." }
}

/// 관리자 연결(MemberLinkStore)을 회원 명단과 맞춰 보는 도우미. 명단에 없는(영구 삭제된) 회원은 제외한다.
enum LinkLookup {
    static func links(of member: MemberSummary, in members: [MemberSummary],
                      store: MemberLinkStore) -> [(link: MemberLink, other: MemberSummary)] {
        store.links.compactMap { link in
            let otherId: UUID
            switch member.memberType {
            case .child:  guard link.childId == member.id else { return nil }; otherId = link.mentorId
            case .mentor: guard link.mentorId == member.id else { return nil }; otherId = link.childId
            case .admin:  return nil
            }
            return members.first { $0.id == otherId }.map { (link, $0) }
        }
    }

    static func counterparts(of member: MemberSummary, in members: [MemberSummary],
                             store: MemberLinkStore) -> [MemberSummary] {
        links(of: member, in: members, store: store).map(\.other)
    }
}

/// 이름 + 아이디 (+ 탈퇴 대기 표시)
struct MemberNameLabel: View {
    let member: MemberSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(member.name)
                    .font(.sonjuBody.weight(.semibold))
                    .foregroundColor(.sonjuText)
                if member.isPendingDeletion {
                    Text("탈퇴 대기")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            Text(member.username)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct LinkOverviewRow: View {
    let member: MemberSummary
    let linked: [MemberSummary]

    private var side: MemberSide { MemberSide(member.memberType) ?? .child }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                MemberNameLabel(member: member)
                if linked.isEmpty {
                    Text(side.emptyMessage)
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                } else {
                    ForEach(linked) { other in
                        HStack(spacing: 6) {
                            BadgeView(text: side.counterpart.title,
                                      color: side.counterpart == .mentor ? Color(hex: "#2196F3") : .sonjuPrimary)
                            Text("\(other.name) · \(other.username)")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.sonjuSecondary)
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
    }
}

private struct LinkInfoRow: View {
    let label: String
    let value: String
    var color: Color = .sonjuText

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(.sonjuBody)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}

private struct LinkSummaryTile: View {
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

private struct LinkSearchField: View {
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
