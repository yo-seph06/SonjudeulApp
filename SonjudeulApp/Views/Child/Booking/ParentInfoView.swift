import SwiftUI

struct ParentInfoView: View {
    @ObservedObject var bookingVM: BookingViewModel
    @EnvironmentObject var bookingStore: BookingStore
    @EnvironmentObject var auth: AuthViewModel

    @State private var showLocationPicker = false
    @State private var triedSubmit = false
    @State private var saveErrorMessage: String?

    private var locationErrorVisible: Bool {
        triedSubmit && !bookingVM.hasValidParentLocation
    }

    var body: some View {
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

                // Address (필수)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 2) {
                        Text("부모님 위치")
                            .font(.sonjuHeadline)
                            .foregroundColor(.sonjuText)
                        Text("*")
                            .font(.sonjuHeadline)
                            .foregroundColor(.red)
                    }

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
                            .padding(16)
                            .frame(minHeight: 56)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(locationErrorVisible ? Color.red : Color.clear, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
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
                            .cornerRadius(14)
                        }
                        .buttonStyle(PressButtonStyle())
                    }

                    if bookingVM.parentLocation != nil {
                        BookingTextField(
                            placeholder: "상세 주소 (동·호수, 선택)",
                            text: $bookingVM.addressDetail
                        )
                    }

                    if locationErrorVisible {
                        Label(BookingRequestError.missingParentLocation.message, systemImage: "exclamationmark.circle.fill")
                            .font(.sonjuCaption)
                            .foregroundColor(.red)
                    }
                }

                // Parent info
                VStack(alignment: .leading, spacing: 10) {
                    Text("부모님 정보")
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            BookingTextField(
                                placeholder: "홍길순",
                                text: $bookingVM.parentName
                            )
                            BookingTextField(
                                placeholder: "72세",
                                text: $bookingVM.parentAge,
                                keyboardType: .numberPad,
                                width: 90
                            )
                        }

                        BookingTextField(
                            placeholder: "010-1234-5678",
                            text: $bookingVM.parentPhone,
                            keyboardType: .phonePad
                        )
                    }
                }

                AmberButton(title: "결제하기") {
                    submit()
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showLocationPicker) {
            ParentLocationPickerView(initialLocation: bookingVM.parentLocation) { location in
                bookingVM.setParentLocation(location)
            }
        }
        .alert("부모님 위치", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func submit() {
        triedSubmit = true
        guard bookingVM.hasValidParentLocation, let location = bookingVM.parentLocation else {
            saveErrorMessage = BookingRequestError.missingParentLocation.message
            return
        }
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
                    parentAddressDetail: detail.isEmpty ? nil : detail
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
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
