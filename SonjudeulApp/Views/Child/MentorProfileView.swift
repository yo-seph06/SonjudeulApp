import SwiftUI

struct MentorProfileView: View {
    let mentorName: String
    let mentorId: UUID?

    @EnvironmentObject var bookingStore: BookingStore

    private var mentor: User? {
        guard let id = mentorId else { return nil }
        return UserStore.shared.findUserById(id)
    }

    private var displayName: String {
        mentor?.name.isEmpty == false ? mentor!.name : (mentorName.isEmpty ? "멘토" : mentorName)
    }

    private var reviews: [BookingRecord] {
        guard let id = mentorId else { return [] }
        return bookingStore.reviews(forMentor: id)
    }

    private var avgRating: Double {
        guard let id = mentorId else { return 5.0 }
        return bookingStore.averageRating(forMentor: id)
    }

    private var visitCount: Int {
        guard let id = mentorId else { return 0 }
        return bookingStore.visitCount(forMentor: id)
    }

    private var ratingText: String {
        String(format: "%.1f", avgRating)
    }

    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Avatar + name
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.sonjuPrimary, Color.sonjuDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 100, height: 100)
                            if let data = mentor?.profileImageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Text(String(displayName.prefix(1)))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(spacing: 6) {
                            Text(displayName)
                                .font(.sonjuLargeTitle)
                                .foregroundColor(.sonjuText)
                            HStack(spacing: 6) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.sonjuPrimary)
                                Text(mentor?.university ?? "대학생 멘토")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuPrimary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Color.sonjuPrimary.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 32)

                    // Stats
                    SonjuCard {
                        HStack(spacing: 0) {
                            VStack(spacing: 6) {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "#FFB300"))
                                    Text(ratingText)
                                        .font(.sonjuTitle)
                                        .foregroundColor(.sonjuText)
                                }
                                Text("평점")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 40).background(Color.sonjuDivider)

                            VStack(spacing: 6) {
                                Text("\(visitCount)")
                                    .font(.sonjuTitle)
                                    .foregroundColor(.sonjuText)
                                Text("방문 횟수")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 40).background(Color.sonjuDivider)

                            VStack(spacing: 6) {
                                Text("\(reviews.count)")
                                    .font(.sonjuTitle)
                                    .foregroundColor(.sonjuText)
                                Text("리뷰")
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)

                    // Introduction
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "소개")
                            Text("어르신들의 디지털 생활을 함께 돕겠습니다. 스마트폰 기초부터 카카오톡, 유튜브, 인터넷 뱅킹까지 친절하게 알려드려요 😊")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuText)
                                .lineSpacing(4)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Services
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "제공 서비스")
                            VStack(spacing: 10) {
                                ServiceBadgeRow(items: ["스마트폰 기초", "카카오톡"])
                                ServiceBadgeRow(items: ["유튜브 활용", "인터넷 뱅킹"])
                                ServiceBadgeRow(items: ["사진 관리", "기기 최적화"])
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Reviews
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                SectionHeader(title: "이용 후기")
                                Spacer()
                                if !reviews.isEmpty {
                                    Text("\(reviews.count)개")
                                        .font(.sonjuCaption)
                                        .foregroundColor(.sonjuSecondary)
                                }
                            }

                            if reviews.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .foregroundColor(.sonjuPrimary.opacity(0.4))
                                        .font(.system(size: 24))
                                    Text("아직 후기가 없어요")
                                        .font(.sonjuBody)
                                        .foregroundColor(.sonjuSecondary)
                                }
                                .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(reviews) { review in
                                        ReviewCard(review: review)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Contact
                    SonjuCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "연락처")
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.sonjuPrimary)
                                    .frame(width: 20)
                                Text("010-****-\(String((mentor?.phone ?? "0000").suffix(4)))")
                                    .font(.sonjuBody)
                                    .foregroundColor(.sonjuText)
                            }
                            Text("예약 확정 후 방문 당일 연락드립니다")
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("멘토 프로필")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ReviewCard: View {
    let review: BookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= (review.rating ?? 0) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(star <= (review.rating ?? 0) ? Color(hex: "#FFB300") : Color.sonjuDivider)
                }
                Spacer()
                Text(review.date)
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuSecondary)
            }
            if !review.reviewComment.isEmpty {
                Text(review.reviewComment)
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color.sonjuBackground)
        .cornerRadius(12)
    }
}

private struct ServiceBadgeRow: View {
    let items: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.sonjuCaption)
                    .foregroundColor(.sonjuPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.sonjuPrimary.opacity(0.1))
                    .cornerRadius(20)
            }
            Spacer()
        }
    }
}
