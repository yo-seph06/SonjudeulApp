import SwiftUI

struct ScheduleAddView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    @Environment(\.dismiss) private var dismiss

    var initialDate: Date = Date()

    @State private var title = ""
    @State private var date: Date
    @State private var notes = ""

    init(initialDate: Date = Date()) {
        self.initialDate = initialDate
        // 기본 시간을 오전 10시로 설정
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: initialDate)
        comps.hour = 10
        comps.minute = 0
        _date = State(initialValue: Calendar.current.date(from: comps) ?? initialDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonjuBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 제목
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("일정 제목", systemImage: "pencil")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                TextField("예) 병원 방문, 가족 모임", text: $title)
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuText)
                            }
                        }
                        .padding(.horizontal, 24)

                        // 날짜 & 시간
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("날짜 및 시간", systemImage: "calendar.clock")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .tint(.sonjuPrimary)
                                    .environment(\.locale, Locale(identifier: "ko_KR"))
                            }
                        }
                        .padding(.horizontal, 24)

                        // 메모
                        SonjuCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("메모 (선택)", systemImage: "note.text")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                                TextField("추가 메모를 입력하세요", text: $notes, axis: .vertical)
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuText)
                                    .lineLimit(3...5)
                            }
                        }
                        .padding(.horizontal, 24)

                        // 알림 안내
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.sonjuPrimary)
                                .font(.system(size: 14))
                            Text("일정 1시간 전에 알림을 보내드려요")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.horizontal, 28)

                        // 저장 버튼
                        AmberButton(
                            title: "일정 저장",
                            disabled: title.trimmingCharacters(in: .whitespaces).isEmpty
                        ) {
                            let trimmed = title.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            let event = ScheduleEvent(title: trimmed, date: date, notes: notes)
                            scheduleStore.add(event)
                            dismiss()
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("새 일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.sonjuPrimary)
                }
            }
        }
    }
}
