//
//  ChatLogView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/26/21.
//

import SwiftUI
import Firebase
import FirebaseStorage
import PhotosUI
import SDWebImageSwiftUI

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var isUploadingImage = false
    
    var chatUser: UserModel?
    
    init(chatUser: UserModel?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    private var firestoreListener: ListenerRegistration?
    
    func stopListening() {
        firestoreListener?.remove()
        firestoreListener = nil
    }
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        stopListening()
        chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to listen for messages: \(error)"
                    }
                    print(error)
                    return
                }
                
                let newMessages = querySnapshot?.documentChanges.compactMap { change -> ChatMessage? in
                    guard change.type == .added else { return nil }
                    return try? change.document.data(as: ChatMessage.self)
                } ?? []
                
                DispatchQueue.main.async {
                    self?.chatMessages.append(contentsOf: newMessages)
                    self?.count += 1
                }
            }
    }
    
    func handleSendImage(_ imageData: Data) {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }

        isUploadingImage = true

        // Create a unique path for the image in Firebase Storage
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = FirebaseManager.shared.storage.reference(withPath: "chat_images/\(fromId)/\(toId)/\(fileName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to upload image: \(error.localizedDescription)"
                    self?.isUploadingImage = false
                }
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Failed to get download URL: \(error.localizedDescription)"
                        self?.isUploadingImage = false
                    }
                    return
                }

                guard let imageURL = url?.absoluteString else {
                    DispatchQueue.main.async { self?.isUploadingImage = false }
                    return
                }

                // Compose a message that contains the image URL as text.
                let messageDocFrom = FirebaseManager.shared.firestore
                    .collection(FirebaseConstants.messages)
                    .document(fromId)
                    .collection(toId)
                    .document()

                let messageDocTo = FirebaseManager.shared.firestore
                    .collection(FirebaseConstants.messages)
                    .document(toId)
                    .collection(fromId)
                    .document()

                let messageData: [String: Any] = [
                    FirebaseConstants.fromId: fromId,
                    FirebaseConstants.toId: toId,
                    FirebaseConstants.timestamp: Timestamp(),
                    FirebaseConstants.text: imageURL
                ]

                messageDocFrom.setData(messageData)
                messageDocTo.setData(messageData)

                // Update recent message with a placeholder text
                self?.persistRecentMessage(text: "📷 Photo")

                DispatchQueue.main.async {
                    self?.isUploadingImage = false
                    self?.count += 1
                }
            }
        }
    }
    
    func handleSend() {
        let messageText = chatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: messageText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage(text: messageText)
            
            DispatchQueue.main.async {
                self.chatText = ""
                self.count += 1
            }
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            
            print("Recipient saved message as well")
        }
    }
    
    private func persistRecentMessage(text: String) {
        guard let chatUser = chatUser else { return }
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
            
            let data = [
                FirebaseConstants.timestamp: Timestamp(),
                FirebaseConstants.text: text,
                FirebaseConstants.fromId: uid,
                FirebaseConstants.toId: toId,
                FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
                FirebaseConstants.email: chatUser.email
            ] as [String : Any]
            
            document.setData(data) { error in
                if let error = error {
                    self.errorMessage = "Failed to save recent message: \(error)"
                    print("Failed to save recent message: \(error)")
                    return
                }
            }
        }
    
    @Published var count = 0
}

struct ChatLogView: View {
    
    @ObservedObject var vm: ChatLogViewModel
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var isPickingPhoto = false
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(vm.chatUser?.email.replacingOccurrences(of: "@optonline.net", with: "") ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.stopListening()
        }
    }
    
    static let emptyScrollToString = "Empty"
    
    private var messagesView: some View {
        VStack {
                ScrollView {
                    ScrollViewReader { scrollViewProxy in
                        VStack {
                            
                            ForEach(vm.chatMessages) { message in
                                MessageView(message: message)
                            }
                            
                            HStack { Spacer() }
                            .id(Self.emptyScrollToString)
                        }
                        .onReceive(vm.$count) { _ in
                            withAnimation(.easeOut(duration: 0.5)) {
                                scrollViewProxy.scrollTo(Self.emptyScrollToString, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
                .safeAreaInset(edge: .bottom) {
                    chatBottomBar
                        .background(Color(.systemBackground)
                                        .ignoresSafeArea())
                }
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            PhotosPicker(selection: $selectedPhoto, matching: .images, preferredItemEncoding: .automatic) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 24))
                    .foregroundColor(Color(.darkGray))
            }
            .onChange(of: selectedPhoto) { newValue in
                guard let newValue = newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        vm.handleSendImage(data)
                        await MainActor.run { selectedPhoto = nil }
                    }
                }
            }
            
            HStack {
                ZStack {
                    
                    DescriptionPlaceholder()
                    TextEditor(text: $vm.chatText)
                        .opacity(vm.chatText.isEmpty ? 0.5 : 1)
                        .onSubmit {
                            vm.handleSend()
                        }
                }
                
                Button {
                    vm.handleSend()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.red)
                        .padding(5)
                        .background(Color(.gray))
                        .cornerRadius(50)
                }
                .controlSize(.mini)

                .disabled(vm.chatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color(.systemGray5), lineWidth: 1.0)
            )
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        //.ignoresSafeArea(.keyboard, edges: .bottom)
        //.ignoresSafeArea(.container, edges: [.top, .horizontal])
        //.ignoresSafeArea(.keyboard)
    }
    
    private struct DescriptionPlaceholder: View {
        var body: some View {
            HStack {
                Text("Message...")
                    .foregroundColor(.secondary)
                    .font(.system(size: 17))
                    .padding(.leading, 5)
                    .padding(.top, -4)
                Spacer()
            }
        }
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    @State private var showTime = false
    
    var body: some View  {
        VStack {
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                
                HStack {
                    Spacer()
                    VStack(alignment: .trailing) {
                        if let url = URL(string: message.text), url.scheme?.hasPrefix("http") == true {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 220, maxHeight: 220)
                                .clipped()
                                .cornerRadius(14)
                        } else {
                            Text(message.text)
                                .foregroundColor(Color.primary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(10)
                    .background(Color.blue)
                    .clipShape(ChatBubble(isCurrentUserMessage: true))
                    .frame(alignment: .trailing)
                    .onTapGesture {
                        showTime.toggle()
                    }
                }
                
            } else {
                
                HStack {
                    VStack(alignment: .leading) {
                        if let url = URL(string: message.text), url.scheme?.hasPrefix("http") == true {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 220, maxHeight: 220)
                                .clipped()
                                .cornerRadius(14)
                        } else {
                            Text(message.text)
                                .foregroundColor(Color.primary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(ChatBubble(isCurrentUserMessage: false))
                    .frame(alignment: .leading)
                    //.frame(maxWidth: 350)
                    .onTapGesture {
                        showTime.toggle()
                    }
                    Spacer()
                }
            }
            
            if showTime {
                Text("\(message.timestamp.formatted(.dateTime.weekday().month().day().year(.twoDigits).hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        
        .padding(.horizontal, 10)
        .padding(.top, 10)
    }
    
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock chat user for preview
        let mockUser = UserModel(uid: "6787g8fghctrdcrt6", email: "arp1@gmail.com", profileImageUrl: "profile-rabbit-toy.png")
        let vm = ChatLogViewModel(chatUser: mockUser)
        return Group {
            NavigationView {
                ChatLogView(vm: vm)
            }
            //.preferredColorScheme(.light)

            NavigationView {
                ChatLogView(vm: vm)
            }
            .preferredColorScheme(.dark)
        }
    }
}

