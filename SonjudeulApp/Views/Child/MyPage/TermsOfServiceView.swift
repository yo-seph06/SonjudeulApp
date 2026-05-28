import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("손주들 서비스 이용약관")
                        .font(.sonjuTitle)
                        .foregroundColor(.sonjuText)
                    Text("시행일: 2025년 1월 1일")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)

                    Text("본 이용약관은 손주들(이하 '회사' 또는 '당사')이 제공하는 스마트폰 교육 중개 서비스 '손주들'(이하 '서비스')의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임 사항을 규정합니다.\n이용자는 서비스에 접속하거나 서비스를 이용함으로써 본 약관에 동의한 것으로 간주됩니다. 약관에 동의하지 않을 경우 서비스 이용이 제한될 수 있습니다.")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuText)

                    TermsArticle(title: "제1조 (목적 및 적용 범위)",
                        content: "본 약관은 회사가 운영하는 서비스(모바일 애플리케이션 및 관련 플랫폼 포함)에 적용되며, 멘토 회원, 자녀 회원, 수혜 시니어 이용자 간의 관계를 규율합니다.\n이용자가 미성년자인 경우, 관련 법령에 따라 법정대리인의 동의가 필요합니다.")

                    TermsArticle(title: "제2조 (용어의 정의)",
                        content: "본 약관에서 사용하는 주요 용어의 정의는 다음과 같습니다.\n• '멘토 회원': 서비스에 등록하여 시니어를 대상으로 일대일 스마트폰 교육을 제공하고 그에 따른 보수를 수령하는 개인\n• '자녀 회원': 자신의 부모 또는 보호 중인 시니어를 위해 교육 서비스를 결제하고 이용 혜택을 제공하는 개인\n• '시니어': 자녀 회원의 신청에 의해 교육 서비스를 실제로 제공받는 어르신\n• '수업': 멘토 회원과 시니어 간에 이루어지는 일대일 스마트폰 교육 세션\n• '플랫폼': 회사가 제공하는 모바일 애플리케이션 및 관련 시스템 일체")

                    TermsArticle(title: "제3조 (회원 유형 및 가입)",
                        content: "① 멘토 회원\n• 서비스에 등록한 후 회사의 심사를 통해 멘토 자격을 취득할 수 있습니다.\n• 멘토 회원은 정확한 개인정보, 교육 이력 및 자격 사항을 제공해야 하며, 허위 정보 등록 시 즉시 자격이 박탈될 수 있습니다.\n• 멘토 회원은 약속된 수업 일정과 장소에 성실히 임해야 할 의무가 있습니다.\n• 멘토 회원은 시니어의 개인정보를 교육 목적 외에 사용할 수 없습니다.\n\n② 자녀 회원\n• 본인 명의의 계정을 생성하고, 부모님 또는 보호 중인 시니어를 위해 교육 서비스를 신청 및 결제합니다.\n• 자녀 회원은 시니어의 수업 참여에 필요한 정보(이름, 연락처, 주소 등)를 정확히 입력할 책임이 있습니다.\n• 자녀 회원은 결제 완료 후 수업 일정이 확정되었음을 시니어에게 사전에 안내할 책임이 있습니다.")

                    TermsArticle(title: "제4조 (서비스 이용)",
                        content: "모든 이용자는 서비스 이용 시 다음 각 호의 행위를 하여서는 안 됩니다.\n• 관련 법령 또는 본 약관을 위반하는 행위\n• 타인의 개인정보 또는 계정을 도용하는 행위\n• 허위 정보를 등록하거나 타인을 기망하는 행위\n• 서비스의 정상적인 운영을 방해하거나 장애를 유발하는 행위\n• 멘토 회원과 자녀 회원 간의 직거래(플랫폼 외부 결제) 유도 행위\n• 수업 중 또는 수업과 관련하여 시니어에게 불쾌감, 피해를 주거나 괴롭히는 행위\n• 허가되지 않은 자동화 프로그램, 크롤러 등을 사용하는 행위\n• 기타 공공질서 및 선량한 풍속에 반하는 행위")

                    TermsArticle(title: "제5조 (계정 및 보안)",
                        content: "• 이용자는 계정 및 비밀번호 등 로그인 정보의 기밀을 유지할 책임이 있습니다.\n• 계정의 무단 사용이 발생한 경우 즉시 회사에 알려야 합니다.\n• 이용자의 관리 소홀로 인해 발생한 손해에 대해서는 회사가 책임을 지지 않습니다.\n• 메시지, 사진, 동영상 및 기타 사용자 데이터는 종단간 암호화(end-to-end encryption)된 상태로 저장됩니다.")

                    TermsArticle(title: "제6조 (결제 정책)",
                        content: "① 결제 방법\n자녀 회원은 회사가 제공하는 결제 수단을 통해 수업료를 결제합니다. 결제는 수업 확정 전 선결제 방식으로 진행됩니다.\n\n② 멘토 보수 지급\n회사는 수업 완료 확인 후, 회사가 정한 정산 주기에 따라 멘토 회원에게 보수를 지급합니다. 회사는 플랫폼 운영 수수료를 공제한 후 잔액을 지급할 수 있으며, 수수료율은 서비스 내 별도 공지합니다.")

                    TermsArticle(title: "제7조 (환불 정책)",
                        content: "다음 각 호에 해당하는 경우 자녀 회원은 환불을 신청할 수 있습니다.\n• 수업 시작 24시간 전까지 자녀 회원이 취소를 요청한 경우: 결제 금액 전액 환불\n• 멘토 회원이 약속된 수업 시간에 정당한 사유 없이 도착하지 않은 사실이 확인된 경우: 해당 수업 결제 금액 전액 환불\n• 멘토 회원의 귀책사유로 수업이 정상적으로 이행되지 않은 사실이 확인된 경우: 해당 수업 결제 금액 전액 또는 일부 환불\n\n단, 다음의 경우에는 환불이 제한될 수 있습니다.\n• 수업 시작 24시간 이내에 자녀 회원 또는 시니어 측의 사정으로 취소하는 경우\n• 시니어가 수업에 참여하지 않거나 정당한 사유 없이 거부한 경우\n\n환불 신청은 서비스 내 고객센터 또는 이메일(contact@sonjudeul.kr)을 통해 접수하며, 증빙 자료 확인 후 처리됩니다. 환불은 원칙적으로 결제 수단으로 환불되며, 처리 기간은 영업일 기준 3~7일이 소요될 수 있습니다.")

                    TermsArticle(title: "제8조 (상호 평가 시스템)",
                        content: "서비스는 수업 완료 후 멘토 회원과 자녀 회원이 상호 평가를 진행할 수 있는 기능을 제공합니다.\n• 평가는 사실에 기반하여 성실하게 작성되어야 합니다.\n• 허위 사실, 모욕, 명예훼손에 해당하는 평가는 회사의 판단에 따라 삭제될 수 있습니다.\n• 악의적 평가를 반복적으로 작성하거나 평가 시스템을 남용하는 경우, 회사는 해당 이용자의 서비스 이용을 제한할 수 있습니다.\n• 평가 내용은 상대방의 프로필에 공개될 수 있으며, 서비스 품질 향상을 위한 내부 데이터로 활용될 수 있습니다.")

                    TermsArticle(title: "제9조 (지적재산권)",
                        content: "서비스와 관련된 콘텐츠, 디자인, 소프트웨어, 로고 등은 회사 또는 해당 권리자의 자산이며, 국내외 저작권법 및 관련 법령에 의해 보호됩니다.\n이용자는 회사의 사전 서면 동의 없이 서비스 내 콘텐츠를 복제, 배포, 수정하거나 영리 목적으로 이용할 수 없습니다.")

                    TermsArticle(title: "제10조 (서비스 변경 및 중단)",
                        content: "회사는 다음과 같은 경우 사전 공지 없이 서비스의 전부 또는 일부를 변경하거나 중단할 수 있습니다.\n• 서비스 개선, 기능 추가/변경 및 유지 보수 필요 시\n• 기술적, 운영상 불가피한 사유가 발생한 경우\n• 관련 법령 또는 정책 변경으로 인한 조정이 필요한 경우\n\n회사는 서비스 변경 및 중단으로 인하여 발생하는 문제에 대해 관련 법령이 허용하는 범위 내에서 책임을 부담합니다.")

                    TermsArticle(title: "제11조 (면책조항)",
                        content: "회사는 다음 각 호의 사유로 인하여 이용자에게 발생한 손해에 대하여, 관련 법령이 허용하는 한도 내에서 책임을 지지 않습니다.\n• 천재지변, 정전, 통신망 장애 등 불가항력으로 인한 서비스 중단\n• 이용자의 귀책사유로 인한 서비스 이용 장애\n• 제3자가 제공하는 서비스, 네트워크, 소프트웨어로 인해 발생한 문제\n• 멘토 회원과 시니어 사이에서 발생한 개인 간 분쟁")

                    TermsArticle(title: "제12조 (책임의 한계)",
                        content: "회사는 간접손해, 특별손해, 결과적 손해, 손실 이익, 데이터 손실 등에 대하여, 관련 법령이 허용하는 최대 한도 내에서 책임을 제한합니다.")

                    TermsArticle(title: "제13조 (개인정보 보호)",
                        content: "회사는 이용자의 개인정보를 「개인정보 보호법」 및 관련 법령에 따라 보호합니다. 개인정보의 수집, 이용, 보관 및 파기에 관한 상세한 사항은 서비스 내 개인정보처리방침을 통해 확인하실 수 있습니다.")

                    TermsArticle(title: "제14조 (약관의 변경)",
                        content: "회사는 법령 변경, 서비스 내용 변경 등 합리적인 사유가 있는 경우 본 약관을 변경할 수 있습니다. 약관이 변경되는 경우, 변경 사항 및 적용 일자를 명시하여 서비스 내 공지 등으로 안내합니다.\n이용자가 변경된 약관의 효력 발생일 이후에도 서비스를 계속 이용하는 경우, 변경된 약관에 동의한 것으로 간주됩니다.")

                    TermsArticle(title: "제15조 (준거법 및 관할)",
                        content: "본 약관은 대한민국 법률을 준거법으로 하며, 서비스 이용과 관련하여 회사와 이용자 간에 분쟁이 발생한 경우 민사소송법에 따른 관할 법원을 전속 관할로 합니다.")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("문의처")
                            .font(.sonjuBody)
                            .fontWeight(.semibold)
                            .foregroundColor(.sonjuText)
                        Text("• 이메일: contact@sonjudeul.kr\n• 서비스: 손주들 (sonjudeul.kr)")
                            .font(.sonjuCaption)
                            .foregroundColor(.sonjuSecondary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                    Text("ⓒ 2025 손주들. All rights reserved.")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                        .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .navigationTitle("서비스 이용약관")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TermsArticle: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.sonjuBody)
                .fontWeight(.semibold)
                .foregroundColor(.sonjuText)
            Text(content)
                .font(.sonjuBody)
                .foregroundColor(.sonjuText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
