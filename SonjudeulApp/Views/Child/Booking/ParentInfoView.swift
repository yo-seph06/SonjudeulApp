import SwiftUI

struct ParentInfoView: View {
    @ObservedObject var bookingVM: BookingViewModel

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

                // Address
                VStack(alignment: .leading, spacing: 10) {
                    Text("주소 입력")
                        .font(.sonjuHeadline)
                        .foregroundColor(.sonjuText)

                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.sonjuPrimary)
                            .font(.system(size: 22))

                        TextField("서울특별시 강남구 OO로 123", text: $bookingVM.address)
                            .font(.sonjuBody)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
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
                    withAnimation { bookingVM.nextStep() }
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ParentInfoView(bookingVM: BookingViewModel())
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
