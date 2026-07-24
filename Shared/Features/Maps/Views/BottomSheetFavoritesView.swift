//
//  BottomSheetFavoritesView.swift
//  TheLightUI
//

import SwiftUI

// Persisted custom favorite entry (name + address).
struct SavedFavorite: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var address: String
}

struct BottomSheetFavoritesView: View {
    let favorites: [BottomSheetFavorite]
    var onFavoriteRoute: ((MapDestination) -> Void)? = nil

    @AppStorage("mapHomeAddress") private var homeAddress: String = ""
    @AppStorage("mapWorkAddress") private var workAddress: String = ""
    @AppStorage("mapCustomFavorites") private var customFavoritesData: Data = Data()

    // Home / Work editor state
    @State private var editingTitle: String = ""
    @State private var inputText: String = ""
    @State private var showingEditor = false

    // Custom-favorite editor state
    @State private var showingCustomEditor = false
    @State private var newCustomTitle: String = ""
    @State private var newCustomAddress: String = ""

    private var customFavorites: [SavedFavorite] {
        (try? JSONDecoder().decode([SavedFavorite].self, from: customFavoritesData)) ?? []
    }

    private func addCustomFavorite(title: String, address: String) {
        var list = customFavorites
        list.append(SavedFavorite(title: title, address: address))
        customFavoritesData = (try? JSONEncoder().encode(list)) ?? Data()
    }

    private func removeCustomFavorite(id: UUID) {
        var list = customFavorites
        list.removeAll { $0.id == id }
        customFavoritesData = (try? JSONEncoder().encode(list)) ?? Data()
    }

    private func savedAddress(for title: String) -> String {
        switch title {
        case "Home": return homeAddress
        case "Work": return workAddress
        default: return ""
        }
    }

    private func save(address: String, for title: String) {
        switch title {
        case "Home": homeAddress = address
        case "Work": workAddress = address
        default: break
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Favorites")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 18) {
                    // Home and Work
                    ForEach(favorites.filter { $0.title != "Add" }) { favorite in
                        builtInButton(favorite)
                    }
                    // Custom saved favorites
                    ForEach(customFavorites) { custom in
                        customButton(custom)
                    }
                    // Add button
                    if let addFav = favorites.first(where: { $0.title == "Add" }) {
                        addButton(addFav)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingEditor) {
            homeWorkEditorSheet
        }
        .sheet(isPresented: $showingCustomEditor) {
            customEditorSheet
        }
    }

    // MARK: - Built-in (Home / Work)

    private func builtInButton(_ favorite: BottomSheetFavorite) -> some View {
        let storedAddress = savedAddress(for: favorite.title)
        return VStack(spacing: 8) {
            Button {
                if storedAddress.isEmpty {
                    editingTitle = favorite.title
                    inputText = ""
                    showingEditor = true
                } else {
                    onFavoriteRoute?(MapDestination(rawAddress: storedAddress))
                }
            } label: {
                circleIcon(systemImage: favorite.systemImage, color: favorite.color)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    editingTitle = favorite.title
                    inputText = storedAddress
                    showingEditor = true
                } label: {
                    Label(storedAddress.isEmpty ? "Add Address" : "Edit Address", systemImage: "pencil")
                }
            }

            VStack(spacing: 2) {
                Text(favorite.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.primary)
                if !storedAddress.isEmpty {
                    Text(storedAddress)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Custom favorites

    private func customButton(_ custom: SavedFavorite) -> some View {
        VStack(spacing: 8) {
            Button {
                onFavoriteRoute?(MapDestination(rawAddress: custom.address))
            } label: {
                circleIcon(systemImage: "star.fill", color: .orange)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    removeCustomFavorite(id: custom.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Text(custom.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Add button

    private func addButton(_ favorite: BottomSheetFavorite) -> some View {
        VStack(spacing: 8) {
            Button {
                newCustomTitle = ""
                newCustomAddress = ""
                showingCustomEditor = true
            } label: {
                circleIcon(systemImage: favorite.systemImage, color: favorite.color)
            }
            .buttonStyle(.plain)

            Text(favorite.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - Shared icon

    private func circleIcon(systemImage: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(Color(.tertiarySystemGroupedBackground))
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(color)
        }
        .frame(width: 56, height: 56)
    }

    // MARK: - Sheets

    private var homeWorkEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Address") {
                    TextField("Street, City, State ZIP", text: $inputText)
                        .autocorrectionDisabled()
                }
                if !inputText.isEmpty {
                    Section {
                        Button(role: .destructive) { inputText = "" } label: {
                            Text("Clear Address")
                        }
                    }
                }
            }
            .navigationTitle(editingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save(address: inputText, for: editingTitle)
                        showingEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var customEditorSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Gym, Mom's House", text: $newCustomTitle)
                        .autocorrectionDisabled()
                }
                Section("Address") {
                    TextField("Street, City, State ZIP", text: $newCustomAddress)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingCustomEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let title = newCustomTitle.isEmpty ? "Place" : newCustomTitle
                        addCustomFavorite(title: title, address: newCustomAddress)
                        showingCustomEditor = false
                    }
                    .fontWeight(.semibold)
                    .disabled(newCustomAddress.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
