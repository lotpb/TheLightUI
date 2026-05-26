//
//  MainMessagesView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: UserModel?
    @Published var isUserCurrentlyLoggedOut = false
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        
        fetchCurrentUser()
        
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessage]()
    
    private var firestoreListener: ListenerRegistration?
    
    func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        firestoreListener?.remove()
        recentMessages.removeAll()
        
        firestoreListener = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to listen for recent messages: \(error)"
                    }
                    print(error)
                    return
                }
                
                DispatchQueue.main.async {
                    querySnapshot?.documentChanges.forEach { change in
                        let docId = change.document.documentID
                        
                        if let index = self?.recentMessages.firstIndex(where: { recentMessage in
                            recentMessage.id == docId
                        }) {
                            self?.recentMessages.remove(at: index)
                        }
                        
                        if let recentMessage = try? change.document.data(as: RecentMessage.self) {
                            self?.recentMessages.insert(recentMessage, at: 0)
                        }
                    }
                }
            }
    }
    
    func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
        }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to fetch current user: \(error)"
                }
                print("Failed to fetch current user:", error)
                return
            }
            
            DispatchQueue.main.async {
                self?.chatUser = try? snapshot?.data(as: UserModel.self)
                FirebaseManager.shared.currentUser = self?.chatUser
            }
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    
    @State private var shouldShowLogOutOptions = false
    @State private var shouldNavigateToChatLogView = false
    @State private var shouldShowNewMessageScreen = false
    @State private var chatUser: UserModel?
    
    @StateObject private var vm = MainMessagesViewModel()
    @StateObject private var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                InboxBackground()

                VStack(spacing: 0) {
                    customNavBar
                    messagesView
                }

                newMessageButton
            }
            .overlay(alignment: .top) { errorBanner }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $shouldNavigateToChatLogView) {
                ChatLogView(vm: chatLogViewModel)
            }
        }
    }
    
    private var customNavBar: some View {
        HStack(spacing: 14) {
            CurrentUserAvatar(urlString: vm.chatUser?.profileImageUrl)

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName(for: vm.chatUser?.email) ?? "Messages")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)

                    Text("Online")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()

            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .confirmationDialog("Settings", isPresented: $shouldShowLogOutOptions, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                vm.handleSignOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("What do you want to do?")
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                self.vm.fetchRecentMessages()
            })
        }
    }
    
    private var messagesView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                inboxHeader

                if vm.recentMessages.isEmpty {
                    EmptyInboxView()
                        .padding(.top, 44)
                } else {
                    ForEach(vm.recentMessages) { recentMessage in
                        Button {
                            openChat(for: recentMessage)
                        } label: {
                            RecentMessageRow(recentMessage: recentMessage)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 108)
        }
    }

    private var inboxHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Inbox")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Recent conversations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(vm.recentMessages.count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.blue, in: Capsule())
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            Label("New", systemImage: "square.and.pencil")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(Color.blue, in: Capsule())
                .shadow(color: .blue.opacity(0.28), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
                self.chatLogViewModel.chatUser = user
                self.chatLogViewModel.fetchMessages()
            })
        }
    }

    private var errorBanner: some View {
        Group {
            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.92), in: Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
        }
    }

    private func openChat(for recentMessage: RecentMessage) {
        let uid = FirebaseManager.shared.auth.currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId

        chatUser = .init(id: uid, uid: uid, email: recentMessage.email, profileImageUrl: recentMessage.profileImageUrl)
        chatLogViewModel.chatUser = chatUser
        chatLogViewModel.fetchMessages()
        shouldNavigateToChatLogView.toggle()
    }

    private func displayName(for email: String?) -> String? {
        email?.replacingOccurrences(of: "@optonline.net", with: "")
    }
}

private struct InboxBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct CurrentUserAvatar: View {
    let urlString: String?

    var body: some View {
        WebImage(url: URL(string: urlString ?? ""))
            .resizable()
            .scaledToFill()
            .frame(width: 52, height: 52)
            .background(Color(.tertiarySystemFill))
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)
    }
}

private struct RecentMessageRow: View {
    let recentMessage: RecentMessage

    private var displayName: String {
        recentMessage.email.replacingOccurrences(of: "@optonline.net", with: "")
    }

    var body: some View {
        HStack(spacing: 14) {
            WebImage(url: URL(string: recentMessage.profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .background(Color(.tertiarySystemFill))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayName)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(recentMessage.timeAgo)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(recentMessage.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
        }
    }
}

private struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 70, height: 70)
                .background(.regularMaterial, in: Circle())

            VStack(spacing: 4) {
                Text("No conversations yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Start a new message to begin chatting.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

#Preview("Main Messages") {
    MainMessagesView()
        .preferredColorScheme(.dark)
}
