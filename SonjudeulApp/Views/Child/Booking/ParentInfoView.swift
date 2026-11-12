import SwiftUI

struct ParentInfoView: View {
    @ObservedObject var bookingVM: BookingViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel

    @State private var showLocationPicker = false
    @State private var triedSubmit = false
    @State private var saveErrorMessage: String?

    private enum FormFieldID: Hashable {
        case name, age, phone, relationship, location, consent
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Calendar
                    VStack(alignment: .leading, spacing: 10) {
                        Text("방문 날짜 선택")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)

                        DatePicker(
                            "",
                            selection: $bookingVM.visitDate,
                            in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .accentColor(.sonjuPrimary)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }

                    // Time picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("방문 시간 선택")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.sonjuPrimary)
                                .font(.system(size: 20))
                            DatePicker(
                                "",
                                selection: $bookingVM.visitDate,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .accentColor(.sonjuPrimary)
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }

                    // 부모님 기본 정보
                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeader("부모님 기본 정보", icon: "person.fill") {
                            Text("필수 \(bookingVM.completedRequiredCount)/\(bookingVM.requiredCount) 완료")
                                .font(.sonjuCaption.weight(.semibold))
                                .foregroundColor(bookingVM.isParentInfoComplete ? .sonjuSuccess : .sonjuPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background((bookingVM.isParentInfoComplete ? Color.sonjuSuccess : Color.sonjuPrimary).opacity(0.12))
                                .clipShape(Capsule())
                        }

                        formField("부모님 성함", required: true, error: bookingVM.nameError) {
                            BookingTextField(placeholder: "예: 홍길순", text: $bookingVM.parentName,
                                             hasError: showsError(bookingVM.nameError))
                                .onChange(of: bookingVM.parentName) { _, new in
                                    let cleaned = ParentInfoRule.sanitizeName(new)
                                    if cleaned != new { bookingVM.parentName = cleaned }
                                }
                        }
                        .id(FormFieldID.name)

                        formField("부모님 나이", required: true, error: bookingVM.ageError) {
                            BookingTextField(placeholder: "예: 72", text: $bookingVM.parentAge,
                                             keyboardType: .numberPad, hasError: showsError(bookingVM.ageError))
                                .overlay(alignment: .trailing) {
                                    Text("세")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuSecondary)
                                        .padding(.trailing, 16)
                                }
                                .onChange(of: bookingVM.parentAge) { _, new in
                                    let cleaned = ParentInfoRule.sanitizeAge(new)
                                    if cleaned != new { bookingVM.parentAge = cleaned }
                                }
                        }
                        .id(FormFieldID.age)

                        formField("부모님 전화번호", required: true, error: bookingVM.phoneError) {
                            BookingTextField(placeholder: "010-1234-5678", text: $bookingVM.parentPhone,
                                             keyboardType: .phonePad, hasError: showsError(bookingVM.phoneError))
                                .onChange(of: bookingVM.parentPhone) { _, new in
                                    let formatted = ParentInfoRule.formatPhoneInput(new)
                                    if formatted != new { bookingVM.parentPhone = formatted }
                                }
                        }
                        .id(FormFieldID.phone)

                        formField("자녀와의 관계", required: true, error: bookingVM.relationshipError) {
                            VStack(spacing: 10) {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                                    ForEach(ParentRelationship.allCases) { option in
                                        relationshipChip(option)
                                    }
                                }
                                if bookingVM.relationship == .other {
                                    BookingTextField(placeholder: "관계를 직접 입력 (예: 외할머니)",
                                                     text: $bookingVM.customRelationship,
                                                     hasError: showsError(bookingVM.relationshipError))
                                        .onChange(of: bookingVM.customRelationship) { _, new in
                                            let cleaned = ParentInfoRule.sanitizeRelationship(new)
                                            if cleaned != new { bookingVM.customRelationship = cleaned }
                                        }
                                }
                            }
                        }
                        .id(FormFieldID.relationship)
                    }

                    // 부모님 거주 위치
                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeader("부모님 거주 위치", icon: "house.fill") { EmptyView() }

                        formField("거주 위치", required: true, error: bookingVM.locationError) {
                            HStack(spacing: 10) {
                                // 직접 타이핑으로는 등록되지 않도록, 입력란은 지도 선택 결과로만 채운다
                                Button { showLocationPicker = true } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.sonjuPrimary)
                                            .font(.system(size: 22))
                                        Text(bookingVM.address.isEmpty ? "지도에서 위치를 선택해 주세요" : bookingVM.address)
                                            .font(.sonjuBody)
                                            .foregroundColor(bookingVM.address.isEmpty ? .sonjuSecondary : .sonjuText)
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(minHeight: 56)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(showsError(bookingVM.locationError) ? Color.red : Color.clear, lineWidth: 1.5)
                                    )
                                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)

                                Button { showLocationPicker = true } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 18))
                                        Text("지도에서\n위치 선택")
                                            .font(.system(size: 11, weight: .semibold))
                                            .multilineTextAlignment(.center)
                                    }
                                    .foregroundColor(.sonjuPrimary)
                                    .frame(width: 76, height: 56)
                                    .background(Color.sonjuPrimary.opacity(0.12))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PressButtonStyle())
                            }
                        }
                        .id(FormFieldID.location)

                        formField("상세 주소", required: false, error: nil) {
                            BookingTextField(placeholder: "예: 101동 1001호, 3층", text: $bookingVM.addressDetail)
                        }

                        // 위치 정보 수집·제공 동의 (신청마다 받는다)
                        VStack(alignment: .leading, spacing: 8) {
                            CheckRow(title: "[필수] 부모님 위치 정보 수집·제공에 동의합니다",
                                     isChecked: bookingVM.locationConsent) {
                                bookingVM.locationConsent.toggle()
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• 수집 항목: 거주 주소, 상세 주소, 위치 좌표(위도·경도)")
                                Text("• 이용 목적: 방문 교육 멘토 매칭과 방문 길 안내")
                                Text("• 제공 대상: 매칭된 멘토 (방문 수업 진행 목적으로만)")
                                Text("• 보관 기간: 회원 탈퇴 시 진행 중인 신청과 함께 삭제")
                                Text("부모님께 위치 정보가 멘토에게 제공된다는 점을 미리 알려 주세요.")
                                    .padding(.top, 2)
                            }
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                            .padding(.leading, 36)

                            if let error = bookingVM.consentError, triedSubmit {
                                errorLabel(error)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showsError(bookingVM.consentError) ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                        .id(FormFieldID.consent)
                    }

                    // 특이사항
                    VStack(alignment: .leading, spacing: 18) {
                        sectionHeader("전달 사항", icon: "text.bubble.fill") { EmptyView() }

                        formField("부모님 관련 특이사항", required: false, error: nil) {
                            VStack(alignment: .trailing, spacing: 6) {
                                TextField("예: 귀가 어두우셔서 크게 말씀해 주세요. 오후에는 병원에 다니세요.",
                                          text: $bookingVM.parentNotes, axis: .vertical)
                                    .font(.sonjuBody)
                                    .lineLimit(3...6)
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                                    .onChange(of: bookingVM.parentNotes) { _, new in
                                        let cleaned = ParentInfoRule.sanitizeNotes(new)
                                        if cleaned != new { bookingVM.parentNotes = cleaned }
                                    }
                                Text("\(bookingVM.parentNotes.count)/\(ParentInfoRule.notesMaxLength)")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                            }
                        }
                    }

                    AmberButton(title: "결제하기") {
                        submit(proxy)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .onAppear {
            // 이전 신청에 등록한 부모님 정보가 있으면 다시 입력하지 않도록 불러온다
            if let childId = auth.currentUser?.id,
               let previous = bookingStore.bookings(forChild: childId).first(where: { $0.parentInfo != nil }) {
                bookingVM.prefill(from: previous)
            }
        }
        .fullScreenCover(isPresented: $showLocationPicker) {
            ParentLocationPickerView(initialLocation: bookingVM.parentLocation,
                                     initialDetail: bookingVM.addressDetail) { location, detail in
                bookingVM.setParentLocation(location, detail: detail)
            }
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

    // MARK: - 입력 항목 구성

    private func showsError(_ error: String?) -> Bool {
        triedSubmit && error != nil
    }

    private func sectionHeader<Trailing: View>(_ title: String, icon: String,
                                               @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.sonjuPrimary)
            Text(title)
                .font(.sonjuHeadline)
                .foregroundColor(.sonjuText)
            Spacer()
            trailing()
        }
    }

    /// 라벨(필수 * / 선택) + 입력란 + 안내 문구. 올바르게 입력된 필수 항목은 체크 표시를 띄운다.
    private func formField<Content: View>(_ title: String, required: Bool, error: String?,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.sonjuBody.weight(.semibold))
                    .foregroundColor(.sonjuText)
                if required {
                    Text("*")
                        .font(.sonjuBody.weight(.semibold))
                        .foregroundColor(.red)
                } else {
                    Text("(선택)")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                }
                Spacer()
                if required && error == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.sonjuSuccess)
                        .accessibilityLabel("입력 완료")
                }
            }
            content()
            if let error, triedSubmit {
                errorLabel(error)
            }
        }
    }

    private func errorLabel(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(.sonjuCaption)
            .foregroundColor(.red)
    }

    private func relationshipChip(_ option: ParentRelationship) -> some View {
        let selected = bookingVM.relationship == option
        return Button {
            bookingVM.relationship = option
        } label: {
            Text(option.rawValue)
                .font(.sonjuBody.weight(selected ? .semibold : .regular))
                .foregroundColor(selected ? .white : .sonjuText)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(selected ? Color.sonjuPrimary : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showsError(bookingVM.relationshipError) && bookingVM.relationship == nil
                                ? Color.red : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PressButtonStyle())
    }

    // MARK: - 신청

    private func submit(_ proxy: ScrollViewProxy) {
        triedSubmit = true
        let firstMissing: FormFieldID? =
            bookingVM.nameError != nil ? .name :
            bookingVM.ageError != nil ? .age :
            bookingVM.phoneError != nil ? .phone :
            bookingVM.relationshipError != nil ? .relationship :
            bookingVM.locationError != nil ? .location :
            bookingVM.consentError != nil ? .consent : nil
        if let firstMissing {
            withAnimation { proxy.scrollTo(firstMissing, anchor: .top) }
            return
        }
        guard let info = bookingVM.makeParentInfo(), let location = bookingVM.parentLocation else { return }
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
                    locationConsentAt: Date()
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

#Preview {
    ParentInfoView(bookingVM: BookingViewModel())
        .environmentObject(BookingStore())
        .environmentObject(AuthViewModel())
}

struct BookingTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var width: CGFloat? = nil
    var hasError: Bool = false

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(.sonjuBody)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .frame(width: width)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasError ? Color.red : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
