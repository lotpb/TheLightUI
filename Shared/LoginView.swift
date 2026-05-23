//
//  LoginView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 10/26/21.
//

import SwiftUI

struct LoginView: View {
    let didCompleteLoginProcess: () -> Void
    
    @State private var isLoginMode = true
    @State private var email = "eunited@aol.net"
    @State private var password = "united"
    @State private var shouldShowImagePicker = false
    @State private var image: UIImage?
    @State private var isAuthenticated = false
    @State private var loginStatusMessage = ""
    
    private let maxWidthForIpad: CGFloat = 700
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 16) {
                    Picker("Mode", selection: $isLoginMode) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    if !isLoginMode {
                        profileImageButton
                    }
                    
                    credentialsFields
                    primaryActionButton
                    biometricLoginButton
                    touchIDButton
                    statusMessage
                }
                .padding()
            }
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05)).ignoresSafeArea())
        }
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }
        .frame(maxWidth: maxWidthForIpad)
    }
    
    private var profileImageButton: some View {
        Button {
            shouldShowImagePicker.toggle()
        } label: {
            VStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 64))
                        .padding()
                        .foregroundColor(.primary)
                }
            }
            .overlay(Circle().stroke(Color.black, lineWidth: 3))
        }
    }
    
    private var credentialsFields: some View {
        Group {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Password", text: $password)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .foregroundColor(.primary)
    }
    
    private var primaryActionButton: some View {
        Button(action: handlePrimaryAction) {
            fullWidthButtonLabel(isLoginMode ? "Log In" : "Create Account", color: .blue)
        }
        .padding(.top, 25)
    }
    
    private var biometricLoginButton: some View {
        Button(action: loginUsingTouchId) {
            fullWidthButtonLabel("Sign in with Face ID", color: .orange)
        }
        .padding(.top, 10)
    }
    
    private var touchIDButton: some View {
        HStack {
            Spacer()
            Button(action: loginUsingTouchId) {
                Image(systemName: "touchid")
            }
        }
    }
    
    private var statusMessage: some View {
        Text(loginStatusMessage)
            .foregroundColor(.red)
    }
    
    private func fullWidthButtonLabel(_ title: String, color: Color) -> some View {
        HStack {
            Spacer()
            Text(title)
                .frame(height: 30)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .background(color)
    }
    
    private func handlePrimaryAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUsingTouchId() {
        AuthenticationService().authenticateUsingTouchId { success, error in
            if success {
                isAuthenticated = true
                didCompleteLoginProcess()
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
    
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, error in
            if let error {
                print("failed to login user:", error)
                loginStatusMessage = "Failed to login user: \(error)"
                return
            }
            
            let uid = result?.user.uid ?? ""
            print("Successfully logged in user: \(uid)")
            loginStatusMessage = "Successfully logged in user: \(uid)"
            didCompleteLoginProcess()
        }
    }
    
    private func createNewAccount() {
        guard image != nil else {
            loginStatusMessage = "You must select an avatar image"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, error in
            if let error {
                print("failed to create user:", error)
                loginStatusMessage = "Failed to create user: \(error)"
                return
            }
            
            let uid = result?.user.uid ?? ""
            print("Successfully created user: \(uid)")
            loginStatusMessage = "Successfully created user: \(uid)"
            persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let imageData = image?.jpegData(compressionQuality: 0.5) else { return }
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        ref.putData(imageData, metadata: nil) { _, error in
            if let error {
                loginStatusMessage = "Failed to push image to Storage: \(error)"
                return
            }
            
            ref.downloadURL { url, error in
                if let error {
                    loginStatusMessage = "Failed to retrieve downloadURL: \(error)"
                    return
                }
                
                guard let url else { return }
                loginStatusMessage = "Successfully stored image with url: \(url.absoluteString)"
                print(url.absoluteString)
                storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        let userData = [
            FirebaseConstants.email: email,
            FirebaseConstants.uid: uid,
            FirebaseConstants.profileImageUrl: imageProfileUrl.absoluteString
        ]
        
        FirebaseManager.shared.firestore.collection(FirebaseConstants.users)
            .document(uid)
            .setData(userData) { error in
                if let error {
                    loginStatusMessage = "\(error)"
                    return
                }
                
                print("Success")
                didCompleteLoginProcess()
            }
    }
}

#Preview("Login - Dark") {
    LoginView(didCompleteLoginProcess: { })
        .preferredColorScheme(.dark)
}
