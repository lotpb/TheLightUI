//
//  CreateNewMessageView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/22/21.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    @Published var users = [UserModel]()
    @Published var errorMessage = ""
    
    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentsSnapshot, error in
            if let error = error {
                self.errorMessage = "failed to fetch users: \(error)"
                print("failed to fetch users: \(error)")
                return
            }
            
            documentsSnapshot?.documents.forEach({ snapshot in
                let user = try? snapshot.data(as: UserModel.self)
                if user?.uid != FirebaseManager.shared.auth.currentUser?.uid {
                    self.users.append(user!)
                }
                
            })
        }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (UserModel) -> ()
    let maxWidthForIpad: CGFloat = 700
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: true) {
                Text(vm.errorMessage)
                
                ForEach(vm.users) { user in
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color.primary, lineWidth: 1))
                            
                            Text(user.email)
                                .foregroundColor(.primary)
                            Spacer()
                        }.padding(.horizontal)
                       Divider()
                            .padding(.vertical, 8)
                    }
                   
                }
            }.navigationTitle("New Message")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
        }
        .frame(maxWidth: maxWidthForIpad)
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
