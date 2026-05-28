import SwiftUI

struct PrivacyConsentView: View {
    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("개인정보 수집·이용 동의서")
                        .font(.sonjuTitle)
                        .foregroundColor(.sonjuText)
                    Text("손주들 (sonjudeul.kr)\n시행일: 2025년 1월 1일")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)

                    Text("손주들(이하 '회사')은 개인정보 보호법 및 관련 법령에 따라 이용자의 개인정보를 보호하고, 이와 관련한 고충을 신속하게 처리하기 위해 다음과 같이 개인정보의 수집·이용에 대한 동의를 받고 있습니다.\n이용자는 아래 내용을 충분히 읽고 동의 여부를 결정하시기 바랍니다. 필수 항목에 동의하지 않을 경우 서비스 이용이 제한될 수 있으며, 선택 항목에 동의하지 않더라도 기본 서비스 이용은 가능합니다.")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)

                    ConsentSection(title: "제1조 (멘토 회원 개인정보 수집·이용)", items: [
                        ConsentItem(
                            number: "①", subtitle: "회원 가입 및 본인 확인 [필수]",
                            details: [
                                "수집 항목: 이름, 생년월일, 휴대폰 번호, 이메일 주소",
                                "보유 기간: 회원 탈퇴 시까지"
                            ]
                        ),
                        ConsentItem(
                            number: "②", subtitle: "멘토 자격 심사 [필수]",
                            details: [
                                "수집 항목: 학력, 교육 경력, 자격증 사본",
                                "보유 기간: 심사 완료 후 3년"
                            ]
                        ),
                        ConsentItem(
                            number: "③", subtitle: "수업 매칭 및 서비스 제공 [필수]",
                            details: [
                                "수집 항목: 활동 지역, 가능 시간대, 자기소개",
                                "보유 기간: 회원 탈퇴 시까지"
                            ]
                        ),
                        ConsentItem(
                            number: "④", subtitle: "보수 정산 [필수]",
                            details: [
                                "수집 항목: 계좌번호, 은행명, 예금주명",
                                "보유 기간: 정산 완료 후 5년 (전자상거래법에 따른 의무 보관)"
                            ]
                        ),
                        ConsentItem(
                            number: "⑤", subtitle: "서비스 품질 관리 [필수]",
                            details: [
                                "수집 항목: 수업 평가 내역, 수업 이력",
                                "보유 기간: 회원 탈퇴 후 1년"
                            ]
                        ),
                        ConsentItem(
                            number: "⑥", subtitle: "프로필 공개 [선택]",
                            details: [
                                "수집 항목: 프로필 사진",
                                "보유 기간: 회원 탈퇴 시까지",
                                "미동의 시 불이익: 프로필 사진 없이 서비스 이용 가능"
                            ]
                        )
                    ])

                    ConsentSection(title: "제2조 (자녀 회원 개인정보 수집·이용)", items: [
                        ConsentItem(
                            number: "①", subtitle: "회원 가입 및 본인 확인 [필수]",
                            details: [
                                "수집 항목: 이름, 휴대폰 번호, 이메일 주소",
                                "보유 기간: 회원 탈퇴 시까지"
                            ]
                        ),
                        ConsentItem(
                            number: "②", subtitle: "부모님(시니어) 정보 등록 [필수]",
                            details: [
                                "수집 항목: 시니어 이름, 휴대폰 번호, 주소(방문 교육 시)",
                                "보유 기간: 회원 탈퇴 시까지",
                                "※ 시니어의 개인정보는 교육 서비스 제공 목적으로만 이용되며, 시니어 본인도 열람·삭제를 요청할 수 있습니다."
                            ]
                        ),
                        ConsentItem(
                            number: "③", subtitle: "결제 처리 [필수]",
                            details: [
                                "수집 항목: 결제 수단 정보 (카드번호 등, PG사를 통해 처리)",
                                "보유 기간: 5년 (전자상거래법에 따른 의무 보관)",
                                "※ 카드번호 등 민감 결제 정보는 PG(결제대행)사에서 처리되며, 회사는 이를 직접 보관하지 않습니다."
                            ]
                        ),
                        ConsentItem(
                            number: "④", subtitle: "서비스 품질 관리 [필수]",
                            details: [
                                "수집 항목: 수업 평가 내역, 결제·환불 이력",
                                "보유 기간: 회원 탈퇴 후 1년"
                            ]
                        ),
                        ConsentItem(
                            number: "⑤", subtitle: "마케팅·혜택 안내 [선택]",
                            details: [
                                "수집 항목: 이메일 주소, 휴대폰 번호",
                                "보유 기간: 동의 철회 시까지",
                                "미동의 시 불이익: 마케팅 및 혜택 안내를 받지 못하나, 기본 서비스 이용에는 영향 없음"
                            ]
                        )
                    ])

                    ConsentArticleView(
                        title: "제3조 (개인정보의 제3자 제공)",
                        content: "회사는 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 다음의 경우에는 예외로 합니다.\n• 이용자가 사전에 동의한 경우\n• 법령의 규정에 의하거나, 수사기관의 적법한 요청이 있는 경우\n• 수업 매칭을 위해 멘토 회원에게 시니어의 연락처 및 주소를 제공하는 경우 (자녀 회원 동의 하에)",
                        tableRows: [
                            ("매칭된 멘토 회원", "방문 수업 진행", "시니어 이름, 연락처, 주소", "수업 완료 후 즉시 삭제"),
                            ("결제대행사(PG사)", "결제 처리 및 환불", "결제 수단 정보", "관계 법령에 따름")
                        ]
                    )

                    ConsentArticleView(
                        title: "제4조 (개인정보의 처리 위탁)",
                        content: "회사는 서비스 향상을 위해 아래와 같이 개인정보 처리 업무를 외부 전문업체에 위탁할 수 있습니다. 위탁업체가 변경될 경우 서비스 내 공지 또는 개인정보처리방침을 통해 안내합니다.\n\n• 결제대행사(PG사): 결제 처리 및 환불 처리 / 관계 법령에 따른 기간 보관\n• 클라우드 서비스 제공업체: 데이터 저장 및 보안 관리 / 계약 종료 시까지\n• 문자·이메일 발송업체: 서비스 안내 및 알림 발송 / 계약 종료 시까지",
                        tableRows: nil
                    )

                    ConsentArticleView(
                        title: "제5조 (이용자의 권리)",
                        content: "이용자는 언제든지 다음의 권리를 행사할 수 있습니다.\n• 개인정보 열람 요청\n• 개인정보 정정·삭제 요청\n• 개인정보 처리 정지 요청\n• 동의 철회 (필수 항목 동의 철회 시 서비스 이용이 제한될 수 있습니다)\n\n권리 행사는 서비스 내 '내 정보 관리' 메뉴 또는 고객센터(contact@sonjudeul.kr)를 통해 요청하실 수 있으며, 회사는 지체 없이 처리합니다.",
                        tableRows: nil
                    )

                    ConsentArticleView(
                        title: "제6조 (개인정보 보호책임자)",
                        content: "회사는 개인정보 처리에 관한 업무를 총괄하고, 이용자의 개인정보 관련 불만 처리 및 피해 구제를 위해 개인정보 보호책임자를 지정하고 있습니다.\n• 성명: [담당자명]\n• 직책: 개인정보 보호책임자(CPO)\n• 이메일: contact@sonjudeul.kr",
                        tableRows: nil
                    )

                    ConsentArticleView(
                        title: "제7조 (동의 거부 권리 및 불이익 안내)",
                        content: "이용자는 개인정보 수집·이용에 대한 동의를 거부할 권리가 있습니다.\n• 필수 항목 동의 거부 시: 회원 가입 및 서비스 이용이 불가합니다.\n• 선택 항목 동의 거부 시: 마케팅·혜택 안내 등 일부 부가 서비스 이용이 제한되나, 기본 서비스 이용에는 영향이 없습니다.",
                        tableRows: nil
                    )

                    Text("ⓒ 2025 손주들. All rights reserved.")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                        .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("개인정보 처리방침")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ConsentItem {
    let number: String
    let subtitle: String
    let details: [String]
}

private struct ConsentSection: View {
    let title: String
    let items: [ConsentItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sonjuTitle)
                .foregroundColor(.sonjuText)
            ForEach(items, id: \.subtitle) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.number) \(item.subtitle)")
                        .font(.sonjuBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.sonjuText)
                    ForEach(item.details, id: \.self) { detail in
                        Text("• \(detail)")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

private struct ConsentArticleView: View {
    let title: String
    let content: String
    let tableRows: [(String, String, String, String)]?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.sonjuTitle)
                .foregroundColor(.sonjuText)
            Text(content)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .fixedSize(horizontal: false, vertical: true)
            if let rows = tableRows {
                VStack(spacing: 0) {
                    HStack {
                        Text("제공받는 자").font(.sonjuCaption).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                        Text("제공 목적").font(.sonjuCaption).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                        Text("제공 항목").font(.sonjuCaption).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                        Text("보유 기간").font(.sonjuCaption).fontWeight(.semibold).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(8)
                    .background(Color.sonjuPrimary.opacity(0.1))
                    Divider()
                    ForEach(rows, id: \.0) { row in
                        HStack(alignment: .top) {
                            Text(row.0).font(.sonjuCaption).foregroundColor(.sonjuText).frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.1).font(.sonjuCaption).foregroundColor(.sonjuText).frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.2).font(.sonjuCaption).foregroundColor(.sonjuText).frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.3).font(.sonjuCaption).foregroundColor(.sonjuText).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(8)
                        Divider()
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.sonjuDivider, lineWidth: 1))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
