//
//  AuthenticationService.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/30/21.
//

import LocalAuthentication

final class AuthenticationService {
    func authenticateUsingTouchId(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason(for: context.biometryType)
        ) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func authenticateUsingTouchId() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            authenticateUsingTouchId { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    private func localizedReason(for biometryType: LABiometryType) -> String {
        switch biometryType {
        case .faceID:
            return "Face ID authentication is required"
        case .touchID:
            return "Touch ID authentication is required"
        default:
            return "Biometric authentication is required"
        }
    }
}
