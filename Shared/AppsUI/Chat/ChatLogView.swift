//
//  ChatLogView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/26/21.
//

import SwiftUI
import Firebase


class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    var chatUser: UserModel?
    
    init(chatUser: UserModel?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    var firestoreListener: ListenerRegistration?
    
    func fetchMessages() {
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        firestoreListener?.remove()
        chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print(error)
                    return
                }
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        if let cm = try?
                            change.document.data(as: ChatMessage.self) {
                            self.chatMessages.append(cm)
                            print("Appending chatMessage in ChatLogView: \(Date())")
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        
        print(chatText)
        guard let fromId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        let document = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: self.chatText, FirebaseConstants.timestamp: Timestamp()] as [String : Any]
        
        document.setData(messageData) { error in
            if let error = error {
                print(error)
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            
            print("Successfully saved current user sending message")
            
            self.persistRecentMessage()
            
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
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
    
    private func persistRecentMessage() {
        
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
                FirebaseConstants.text: self.chatText,
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
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
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
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            HStack {
                ZStack {
                    
                    DescriptionPlaceholder()
                    TextEditor(text: $vm.chatText)
                        .opacity(vm.chatText.isEmpty ? 0.5 : 1)
                        //.disableAutocorrection(true)
                       // .submitLabel(.done)
                        .onSubmit() {
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
                
                //.disabled(vm.chatText.isEmpty)
                
//                ProgressView("Chars: \(vm.chatText) / 150", value: Double(vm.chatText), total: 150)
//                    .frame(width: 150)
//                    .padding()
//                    .accentColor(.yellow)
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
                        Text(message.text)
                            .foregroundColor(Color.primary)
                            .textSelection(.enabled)
                    }
                    .padding(10)
                    .background(Color.blue)
                    .clipShape(ChatBubble(myMsg: true))
                    .frame(alignment: .trailing)
                    .onTapGesture {
                        showTime.toggle()
                    }
                }
                
            } else {
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(message.text)
                            .foregroundColor(Color.primary)
                            .textSelection(.enabled)
                    }
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(ChatBubble(myMsg: false))
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
        //ChatLogView(vm: ChatUser(from:(["uid":"6787g8fghctrdcrt6", "email":"arp1@gmail.com", "profileImageUrl": ""]) as! Decoder))
        
               MainMessagesView()
    }
}
