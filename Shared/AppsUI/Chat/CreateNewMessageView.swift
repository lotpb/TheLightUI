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
        FirebaseManager.shared.firestore.collection("users").getDocuments { [weak self] documentsSnapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to fetch users: \(error)"
                }
                print("Failed to fetch users: \(error)")
                return
            }
            
            let currentUserId = FirebaseManager.shared.auth.currentUser?.uid
            let users = documentsSnapshot?.documents.compactMap { snapshot -> UserModel? in
                guard let user = try? snapshot.data(as: UserModel.self), user.uid != currentUserId else {
                    return nil
                }
                return user
            } ?? []
            
            DispatchQueue.main.async {
                self?.users = users
            }
        }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser: (UserModel) -> Void
    private let maxWidthForIpad: CGFloat = 700
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: true) {
                Text(vm.errorMessage)
                
                ForEach(vm.users) { user in
                    Button {
                        dismiss()
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
                        }
                        .padding(.horizontal)
                        Divider()
                            .padding(.vertical, 8)
                    }
                   
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
            .preferredColorScheme(.dark)
    }
}
