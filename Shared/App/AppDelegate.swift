import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Messaging.messaging().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[FCM] Remote notification registration failed: \(error.localizedDescription)")
    }
}

extension AppDelegate: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { await FCMTokenService.save(token: token) }
    }
}

// Persists the FCM token to the signed-in user's Firestore doc using arrayUnion
// so multiple devices are all stored and old tokens accumulate safely.
enum FCMTokenService {
    static func save(token: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore()
            .collection(FirebaseConstants.users)
            .document(uid)
        let payload: [String: Any] = [FirebaseConstants.fcmTokens: FieldValue.arrayUnion([token])]

        do {
            // updateData is preferred: it is atomic and will not clobber other
            // fields. It requires the document to already exist.
            try await ref.updateData(payload)
        } catch {
            print("[FCM] Token save failed (\(error.localizedDescription)). Retrying with merge…")
            do {
                // setData(merge:true) creates the document when absent, which
                // handles the race between FCM callback and first-time account
                // creation.
                try await ref.setData(payload, merge: true)
            } catch {
                print("[FCM] Token save retry failed: \(error.localizedDescription)")
            }
        }
    }
}
