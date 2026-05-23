//
//  RegisterUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct RegisterUI: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var number = ""
    @State private var validationMessage = ""
    
    @Binding var show: Bool
    
    @Namespace private var animation
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        !number.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {
                HStack {
                    Button(action: {
                        show.toggle()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .padding(.leading)
                
                HStack {
                    Text("Create Account")
                        .font(.system(size: 40))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    
                    Spacer(minLength: 0)
                }
                .padding()
                .padding(.leading)
                
                CustomTextField(image: "person", title: "FULL NAME", value: $name, animation: animation)
                    .textContentType(.name)
                
                CustomTextField(image: "envelope", title: "EMAIL", value: $email, animation: animation)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding(.top, 5)
                
                CustomTextField(image: "lock", title: "PASSWORD", value: $password, animation: animation)
                    .textContentType(.newPassword)
                    .padding(.top, 5)
                
                CustomTextField(image: "phone.fill", title: "PHONE NUMBER", value: $number, animation: animation)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
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
                    Spacer()
                    
                    Button(action: signUp) {
                        HStack(spacing: 10) {
                            Text("SIGN UP")
                                .fontWeight(.heavy)
                            
                            Image(systemName: "arrow.right")
                                .font(.title2)
                        }
                        .modifier(CustomButtonModifier())
                        .opacity(isFormValid ? 1 : 0.55)
                    }
                    .disabled(!isFormValid)
                }
                .padding()
                .padding(.top)
                .padding(.trailing)
                
                HStack {
                    Text("Already have an account? ")
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        show.toggle()
                    }) {
                        Text("sign in")
                            .fontWeight(.heavy)
                            .foregroundColor(Color("yellow"))
                    }
                }
                .padding()
                .padding(.top, 10)
                
                Spacer(minLength: 0)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    private func signUp() {
        guard isFormValid else {
            validationMessage = "Enter a name, valid email, phone number, and a password with at least 6 characters."
            return
        }
        
        validationMessage = ""
        show.toggle()
    }
}

#Preview("Register - Dark") {
    RegisterUI(show: .constant(false))
        .preferredColorScheme(.dark)
}
