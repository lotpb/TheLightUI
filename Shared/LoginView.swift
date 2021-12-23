//
//  Login3UI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 10/26/21.
//

import SwiftUI


//@available(iOS 15.0, *)
struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State var isLoginMode = true
    @State var email = "eunited@aol.net"
    @State var password = "united"
    
    @State var shouldShowImagePicker = false
    let maxWidthForIpad: CGFloat = 700
    //@FocusState private var fieldInFocus: OnboardingField?
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color.primary)
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                        .stroke(Color.black, lineWidth: 3)
                            )
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundColor(Color.primary)
                    
                    Button {
                        handle2Action()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "log In" : "Create Account")
                                .frame(height: 30)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                                
                                .cornerRadius(10)
                            Spacer()
                        }
                        .background(Color.blue)
                    }
                    .padding(.top, 25)
                    
                    Button {
                        loginUsingTouchId() 
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign in with face Id")
                                .foregroundColor(.white)
                                .frame(height: 30)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .background(Color.orange)
                    }
                    .padding(.top, 10)
                    
                    //---------------------------------------
                    HStack {
                        Spacer()
                        Button {
                            loginUsingTouchId()
                        } label: {
                            Image(systemName: "touchid")
                        }
                    }
                    //----------------------------------------
                    
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
            }
            
            .navigationTitle(isLoginMode ? "Log In" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                            .ignoresSafeArea())
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
        .frame(maxWidth: maxWidthForIpad)
    }
    
    @State var image: UIImage?
    
    private func handle2Action() {
        if isLoginMode {
            print("Should log into Firebase with existing credentials")
            loginUser()
        } else {
            createNewAccount()
        }
    }
    //-----------------------------------------------------
    @State var isAuthenticated: Bool = false
    
    func loginUsingTouchId() {
        
        AuthenticationService().authenticateUsingTouchId { (success, error) in
            if success {
                isAuthenticated = true
                self.didCompleteLoginProcess()
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    //------------------------------------------------------
    private func loginUser() {
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            
            print("Successfully logged in user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully logged in user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        FirebaseManager.shared.auth.createUser(withEmail: self.email, password: password) {
            result, err in
            if let err = err {
                print("failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString ?? "")
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let userData = [FirebaseConstants.email: self.email, FirebaseConstants.uid: uid, FirebaseConstants.profileImageUrl: imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection(FirebaseConstants.users)
            .document(uid).setData(userData) { err in
                if let err = err {
                    self.loginStatusMessage = "\(err)"
                    return
                }
                print("Succcess")
                self.didCompleteLoginProcess()
            }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
        .preferredColorScheme(.dark)
    }
}
