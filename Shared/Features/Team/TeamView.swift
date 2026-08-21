//
//  TeamView.swift
//  TheLightUI
//

import SwiftUI
import FirebaseAuth
@preconcurrency import FirebaseFirestore
import SDWebImageSwiftUI

// MARK: - Private helpers (file-scope for use in subviews without self capture)

private func teamRoleOrder(_ role: String?) -> Int {
    switch role {
    case "owner":    return 0
    case "admin":    return 1
    case "salesman": return 2
    case "viewer":   return 3
    default:         return 4
    }
}

private func teamPresenceLabel(isOnline: Bool, lastSeen: Date?) -> String? {
    if isOnline { return "Online" }
    guard let ls = lastSeen else { return nil }
    let min = Int(Date().timeIntervalSince(ls) / 60)
    if min < 1  { return "Just now" }
    if min < 60 { return "\(min)m ago" }
    let hr = min / 60
    if hr < 24  { return "\(hr)h ago" }
    return ls.formatted(date: .abbreviated, time: .omitted)
}

// MARK: - TeamMember

struct TeamMember: Identifiable {
    let id: String          // Firestore document ID == Firebase UID
    var email: String
    var firstName: String
    var lastName: String
    var profileImageUrl: String
    var role: String?
    var isOnline: Bool
    var lastSeen: Date?

    var displayName: String {
        let full = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return full.isEmpty
            ? String(email.split(separator: "@").first ?? Substring(email))
            : full
    }

    init?(doc: QueryDocumentSnapshot) {
        let d   = doc.data()
        let str = { (k: String) -> String in d[k] as? String ?? "" }
        id              = doc.documentID
        email           = str("email")
        firstName       = str("firstName")
        lastName        = str("lastName")
        profileImageUrl = str("profileImageUrl")
        role            = d["role"] as? String
        isOnline        = d["isOnline"] as? Bool ?? false
        lastSeen        = (d["lastSeen"] as? Timestamp)?.dateValue()
    }
}

// MARK: - Listener Box

// Thread-safe wrapper for a ListenerRegistration. `deinit` fires on an
// arbitrary thread while `@MainActor` methods run on the main thread; the
// NSLock serialises both without requiring `nonisolated(unsafe)`.
private final class TeamListenerBox: @unchecked Sendable {
    private let lock = NSLock()
    private var listener: ListenerRegistration?

    func replace(with new: ListenerRegistration) {
        lock.withLock {
            listener?.remove()
            listener = new
        }
    }

    func removeAll() {
        lock.withLock {
            listener?.remove()
            listener = nil
        }
    }
}

// MARK: - TeamViewModel

@MainActor @Observable
private final class TeamViewModel {
    private(set) var members: [TeamMember] = []
    private(set) var isLoading = true
    private(set) var myRole: String? = nil

    @ObservationIgnored private let listenerBox = TeamListenerBox()

    init() { subscribe() }

    deinit { listenerBox.removeAll() }

    var canManage: Bool { myRole == "owner" || myRole == "admin" }

    private func subscribe() {
        let uid = Auth.auth().currentUser?.uid
        guard let cid = CompanySession.companyId, !cid.isEmpty else {
            isLoading = false
            return
        }
        let newListener = Firestore.firestore()
            .collection("users")
            .whereField("companyId", isEqualTo: cid)
            .addSnapshotListener { [weak self] snap, _ in
                let parsed = snap?.documents.compactMap { TeamMember(doc: $0) } ?? []
                let sorted = parsed.sorted {
                    let ro = teamRoleOrder($0.role) - teamRoleOrder($1.role)
                    if ro != 0 { return ro < 0 }
                    let a = $0.firstName.isEmpty ? $0.email : $0.firstName
                    let b = $1.firstName.isEmpty ? $1.email : $1.firstName
                    return a < b
                }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    members   = sorted
                    myRole    = parsed.first { $0.id == uid }?.role
                    isLoading = false
                }
            }
        listenerBox.replace(with: newListener)
    }

    func changeRole(uid: String, to role: String) {
        Task {
            try? await Firestore.firestore()
                .collection("users").document(uid)
                .setData(["role": role], merge: true)
        }
    }

    func removeMember(uid: String) {
        Task {
            try? await Firestore.firestore()
                .collection("users").document(uid)
                .setData(["companyId": ""], merge: true)
        }
    }
}

// MARK: - TeamView

struct TeamView: View {
    @Environment(\.tabBarOverlap) private var tabBarOverlap
    @State private var viewModel = TeamViewModel()
    @State private var confirmRemove: TeamMember? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                headerCard

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                } else if viewModel.members.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.members) { member in
                            TeamMemberCard(
                                member: member,
                                isMe: member.id == Auth.auth().currentUser?.uid,
                                canManage: viewModel.canManage
                                    && member.role != "owner"
                                    && member.id != Auth.auth().currentUser?.uid,
                                onRoleChange: { role in
                                    viewModel.changeRole(uid: member.id, to: role)
                                },
                                onRemove: { confirmRemove = member }
                            )
                        }
                    }
                    roleLegend
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: tabBarOverlap)
        }
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Member?", isPresented: Binding(
            get: { confirmRemove != nil },
            set: { if !$0 { confirmRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) { confirmRemove = nil }
            Button("Remove", role: .destructive) {
                if let m = confirmRemove { viewModel.removeMember(uid: m.id) }
                confirmRemove = nil
            }
        } message: {
            if let m = confirmRemove {
                Text("\(m.displayName) will lose access to the company account. This can be undone by re-inviting them.")
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.isLoading
                     ? "Loading…"
                     : "\(viewModel.members.count) member\(viewModel.members.count == 1 ? "" : "s")")
                    .font(.headline.weight(.semibold))
                if let cid = CompanySession.companyId {
                    Text(cid)
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.title2)
                .foregroundStyle(Color.indigo.opacity(0.8))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("👥")
                .font(.system(size: 40))
            Text("No team members found")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.secondary)
            Text("Invite colleagues using the web app")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Role Legend

    private var roleLegend: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color.indigo).frame(height: 3)
            VStack(alignment: .leading, spacing: 12) {
                Text("Role Permissions")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                VStack(alignment: .leading, spacing: 6) {
                    roleLegendRow(color: .yellow,  name: "Owner",    desc: "Full access, cannot be changed by others")
                    roleLegendRow(color: .indigo,  name: "Admin",    desc: "Can invite, change roles, and manage team")
                    roleLegendRow(color: .teal,    name: "Salesman", desc: "Full CRM access, no team management")
                    roleLegendRow(color: .secondary, name: "Viewer", desc: "Read-only access to records")
                }
            }
            .padding(14)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func roleLegendRow(color: Color, name: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text("—")
                .font(.caption)
                .foregroundStyle(Color.secondary)
            Text(desc)
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
    }
}

// MARK: - TeamMemberCard

private struct TeamMemberCard: View {
    let member: TeamMember
    let isMe: Bool
    let canManage: Bool
    let onRoleChange: (String) -> Void
    let onRemove: () -> Void

    private let assignableRoles = ["admin", "salesman", "viewer"]

    var body: some View {
        HStack(spacing: 12) {
            avatarView

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    if isMe {
                        Text("you")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    if let role = member.role, !role.isEmpty {
                        TeamRoleBadge(role: role)
                    }
                }
                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                if let presence = teamPresenceLabel(isOnline: member.isOnline, lastSeen: member.lastSeen) {
                    Text(presence)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(member.isOnline ? Color.green : Color.secondary)
                }
            }

            Spacer(minLength: 0)

            if canManage {
                Menu {
                    Section("Set Role") {
                        ForEach(assignableRoles, id: \.self) { r in
                            Button {
                                onRoleChange(r)
                            } label: {
                                if member.role == r {
                                    Label(r.capitalized, systemImage: "checkmark")
                                } else {
                                    Text(r.capitalized)
                                }
                            }
                        }
                    }
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Remove from Team", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                        .padding(8)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            if !member.profileImageUrl.isEmpty,
               let url = URL(string: member.profileImageUrl) {
                WebImage(url: url)
                    .placeholder {
                        InitialsAvatarView(firstName: member.firstName,
                                          lastName: member.lastName, size: 44)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                InitialsAvatarView(firstName: member.firstName,
                                   lastName: member.lastName, size: 44)
            }

            if member.isOnline || member.lastSeen != nil {
                Circle()
                    .fill(member.isOnline ? Color.green : Color.secondary)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2))
            }
        }
    }
}

// MARK: - TeamRoleBadge

private struct TeamRoleBadge: View {
    let role: String

    private var badgeColor: Color {
        switch role.lowercased() {
        case "owner":    return .yellow
        case "admin":    return .indigo
        case "salesman": return .teal
        default:         return .secondary
        }
    }

    var body: some View {
        Text(role.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(badgeColor.opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Preview

#Preview("Team") {
    NavigationStack {
        TeamView()
    }
}
