import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Use system background so it adapts to light/dark if needed
            Color.black
                .ignoresSafeArea()

            // Center the launch icon and app name
            VStack(spacing: 12) {
//                Text("TheLight")
//                    .font(.system(size: 50, weight: .semibold))
//                    .foregroundStyle(.white)
//                    .accessibilityLabel("App Name: TheLight")

                Image("The Light Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 350, maxHeight: 350)
                    .padding(.top, 10)
                    .accessibilityLabel("App Launch Icon")
            }
        }
    }
}

#Preview("Launch Screen") {
    LaunchScreenView()
        .preferredColorScheme(.light)
}
