import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.sonjuBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("SonjudeulLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)

                Text("손주들")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.sonjuDeep)

                Text("효도를 일상의 서비스로")
                    .font(.system(size: 15))
                    .foregroundColor(.sonjuSecondary)
            }
        }
    }
}

#Preview { SplashView() }
