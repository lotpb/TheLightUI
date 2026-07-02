//
//  AuthenticationService.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/30/21.
//

import LocalAuthentication

final class AuthenticationService: Sendable {
    func authenticateUsingTouchId() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? LAError(.biometryNotAvailable)
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason(for: context.biometryType)
        )
    }

    private func localizedReason(for biometryType: LABiometryType) -> String {
        switch biometryType {
        case .faceID:
            "Face ID authentication is required"
        case .touchID:
            "Touch ID authentication is required"
        default:
            "Biometric authentication is required"
        }
    }
}
