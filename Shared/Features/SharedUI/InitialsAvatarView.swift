import SwiftUI

public struct InitialsAvatarView: View {
    public let firstName: String
    public let lastName: String
    public let size: CGFloat

    private var initials: String {
        let firstInitial = firstName.first.map { String($0) } ?? ""
        let lastInitial = lastName.first.map { String($0) } ?? ""
        let combined = firstInitial + lastInitial
        if combined.isEmpty {
            return "?"
        }
        return combined.uppercased()
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(UIColor.systemGray2), Color(UIColor.systemGray)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.42, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Profile image")
        .accessibilityValue(initials)
        .accessibilityAddTraits(.isImage)
    }

    public init(firstName: String, lastName: String, size: CGFloat) {
        self.firstName = firstName
        self.lastName = lastName
        self.size = size
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        InitialsAvatarView(firstName: "Alice", lastName: "Smith", size: 64)
        InitialsAvatarView(firstName: "Bob", lastName: "", size: 48)
        InitialsAvatarView(firstName: "", lastName: "Johnson", size: 72)
        InitialsAvatarView(firstName: "", lastName: "", size: 50)
    }
    .padding()
}
