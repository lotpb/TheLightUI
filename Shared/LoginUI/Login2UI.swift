//
//  Login.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct Login2UI: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var validationMessage = ""
    @Namespace private var animation
    
    private var isLoginEnabled: Bool {
        email.contains("@") && password.count >= 6
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Login")
                        .font(.system(size: 40, weight: .heavy))
                        // For Dark Mode Adoption
                        .foregroundColor(.primary)
                    
                    Text("Please sign in to continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .padding(.leading)
            
            CustomTextField(image: "envelope", title: "EMAIL", value: $email, animation: animation)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            
            CustomTextField(image: "lock", title: "PASSWORD", value: $password, animation: animation)
                .textContentType(.password)
                .padding(.top, 5)
            
            if !validationMessage.isEmpty {
                Text(validationMessage)
                    .font(.footnote.bold())
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            HStack {
                Spacer(minLength: 0)
            
                VStack(alignment: .trailing, spacing: 20) {
                    Button(action: forgotPassword) {
                        Text("FORGOT")
                            .fontWeight(.heavy)
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: login) {
                        HStack(spacing: 10) {
                            Text("LOGIN")
                                .fontWeight(.heavy)
                            
                            Image(systemName: "arrow.right")
                                .font(.title2)
                        }
                        .modifier(CustomButtonModifier())
                        .opacity(isLoginEnabled ? 1 : 0.55)
                    }
                    .disabled(!isLoginEnabled)
                }
            }
            .padding()
            .padding(.top, 10)
            .padding(.leading)
            
            HStack(spacing: 0) {
                Text("Don't have an account? ")
                    .fontWeight(.heavy)
                    .foregroundColor(.secondary)
                
                Button {
                    showRegister = true
                } label: {
                    Text("sign up")
                        .fontWeight(.heavy)
                        .foregroundColor(.yellow)
                }
            }
            .padding()
        }
        .navigationDestination(isPresented: $showRegister) {
            RegisterUI(show: $showRegister)
        }
    }
    
    private func login() {
        guard isLoginEnabled else {
            validationMessage = "Enter a valid email and a password with at least 6 characters."
            return
        }
        
        validationMessage = ""
    }
    
    private func forgotPassword() {
        validationMessage = email.isEmpty ? "Enter your email first." : "Password reset is not configured yet."
    }
}

#Preview("Login - Dark") {
    NavigationStack {
        Login2UI()
    }
    .preferredColorScheme(.dark)
}
