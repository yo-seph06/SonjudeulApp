import SwiftUI

/// 신청 3페이지: 멘토 리포트와 같은 과목 목록(LessonSubject.all)에서 수업 과목을 2개 이상 고른다.
struct SubjectSelectView: View {
    @ObservedObject var bookingVM: BookingViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel

    @State private var saveErrorMessage: String?

    private var selectedCount: Int { bookingVM.selectedSubjects.count }
    private var hasEnough: Bool { selectedCount >= LessonSubject.minimumSelection }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("수업받을 과목을 선택해 주세요.")
                        .font(.sonjuTitle)
                        .foregroundColor(.sonjuText)
                    Text("멘토에게 수업받고 싶은 과목을 2개 이상 선택해 주세요. 선택한 과목을 기준으로 수업과 리포트가 진행됩니다.")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 선택 개수
                HStack(spacing: 8) {
                    Image(systemName: hasEnough ? "checkmark.circle.fill" : "hand.tap.fill")
                        .foregroundColor(hasEnough ? .sonjuSuccess : .sonjuPrimary)
                    Text("\(selectedCount)개 선택")
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)
                    Text("(최소 \(LessonSubject.minimumSelection)개)")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    Spacer()
                    if selectedCount > 0 {
                        Button("선택 해제") { bookingVM.selectedSubjectIDs = [] }
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background((hasEnough ? Color.sonjuSuccess : Color.sonjuPrimary).opacity(0.1))
                .cornerRadius(12)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(LessonSubject.all) { subject in
                        subjectCard(subject)
                    }
                }

                if !hasEnough {
                    Label("수업 과목을 최소 \(LessonSubject.minimumSelection)개 이상 선택해 주세요.",
                          systemImage: "exclamationmark.circle.fill")
                        .font(.sonjuCaption)
                        .foregroundColor(.red)
                }

                AmberButton(title: "결제하기", disabled: !hasEnough) {
                    requestPayment()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .alert("신청 정보 확인", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func subjectCard(_ subject: LessonSubject) -> some View {
        let selected = bookingVM.selectedSubjectIDs.contains(subject.id)
        return Button {
            withAnimation(.spring(response: 0.25)) { bookingVM.toggleSubject(subject) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: subject.icon)
                        .font(.system(size: 20))
                        .foregroundColor(selected ? .sonjuPrimary : .sonjuSecondary)
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(selected ? .sonjuPrimary : .sonjuDivider)
                }
                Text(subject.name)
                    .font(.sonjuBody.weight(selected ? .semibold : .regular))
                    .foregroundColor(.sonjuText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .background(selected ? Color.sonjuPrimary.opacity(0.1) : Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.sonjuPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PressButtonStyle())
        .accessibilityLabel(subject.name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 결제 연동 전이라 결제하기는 신청 저장으로 처리된다.
    /// 실제 결제(PG)를 붙일 때도 아래 검증을 모두 통과한 뒤에만 결제를 요청한다.
    private func requestPayment() {
        if let error = bookingVM.subjectError {
            saveErrorMessage = error
            return
        }
        guard let info = bookingVM.makeParentInfo(), let location = bookingVM.parentLocation else {
            // 부모님 정보가 빠졌으면 이전 단계로 돌려보낸다
            saveErrorMessage = "부모님 정보를 다시 확인해 주세요."
            withAnimation { bookingVM.currentStep = .bookingInfo }
            return
        }
        let subjects = bookingVM.selectedSubjects
        if let childId = auth.currentUser?.id {
            let detail = bookingVM.addressDetail.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                try bookingStore.addChildRequest(BookingRecord(
                    date: BookingStore.displayDateText(bookingVM.visitDate),
                    rawDate: bookingVM.visitDate,
                    plan: bookingVM.planName,
                    status: "멘토 찾는 중",
                    childId: childId,
                    parentLocation: location,
                    parentAddressDetail: detail.isEmpty ? nil : detail,
                    parentInfo: info,
                    locationConsentAt: Date(),
                    subjects: subjects
                ))
            } catch let error as BookingRequestError {
                saveErrorMessage = error.message
                return
            } catch {
                saveErrorMessage = BookingRequestError.saveFailed.message
                return
            }
        }
        withAnimation { bookingVM.nextStep() }
    }
}

/// 과목 이름을 칩으로 나열한다 (멘토 화면에서 신청 과목 표시용)
struct SubjectChips: View {
    let subjects: [LessonSubject]

    var body: some View {
        FlowLayout(items: subjects.map(\.name)) { name in
            Text(name)
                .font(.sonjuCaption.weight(.semibold))
                .foregroundColor(.sonjuDeep)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.sonjuPrimary.opacity(0.12))
                .cornerRadius(14)
        }
    }
}

#Preview {
    SubjectSelectView(bookingVM: BookingViewModel())
        .environmentObject(BookingStore())
        .environmentObject(AuthViewModel())
}
