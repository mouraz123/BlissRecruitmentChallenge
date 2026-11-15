import SwiftUI
import UIKit

struct RandomEmojiView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 24) {
            if let emoji = model.randomEmoji {
                AsyncImage(url: emoji.url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 120, height: 120)
                Text(emoji.name)
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                EmptyStateView(title: "No emoji selected", systemImage: "face.smiling")
            }

            Button {
                Task { await model.chooseRandomEmoji() }
            } label: {
                Label("Random Emoji", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isLoadingEmojis)

            if model.isLoadingEmojis {
                ProgressView("Loading emojis…")
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Random Emoji")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmojiListView: View {
    @EnvironmentObject private var model: AppModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Group {
                    if model.visibleEmojis.isEmpty && model.isLoadingEmojis {
                        ProgressView("Loading emojis…")
                    } else if model.visibleEmojis.isEmpty {
                        EmptyStateView(title: "No emojis loaded", systemImage: "face.smiling")
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(model.visibleEmojis) { emoji in
                                Button(role: .destructive) {
                                    model.removeEmojiFromMemory(emoji)
                                } label: {
                                    VStack(spacing: 8) {
                                        AsyncImage(url: emoji.url) { image in
                                            image.resizable().scaledToFit()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 48, height: 48)
                                        Text(emoji.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Label("Remove", systemImage: "minus.circle")
                                            .labelStyle(.iconOnly)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove \(emoji.name) from this list")
                            }
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .refreshable {
                await model.ensureEmojisLoaded()
                model.resetVisibleEmojis()
            }
        }
        .navigationTitle("Emoji List")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.ensureEmojisLoaded() }
    }
}

struct AvatarSearchView: View {
    @EnvironmentObject private var model: AppModel
    @State private var username = ""

    var body: some View {
        Form {
            Section("GitHub username") {
                TextField("e.g. apple", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(search)

                Button(action: search) {
                    if model.isSearchingAvatar {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Search", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(model.isSearchingAvatar)
            }

            if let avatar = model.avatarRecords.first(where: {
                $0.login.caseInsensitiveCompare(username.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
            }) {
                Section("Avatar") {
                    HStack(spacing: 16) {
                        AvatarThumbnail(data: avatar.imageData)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                        Text(avatar.login)
                            .font(.headline)
                    }
                }
            }
        }
        .navigationTitle("Search Avatar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func search() {
        Task { await model.searchAvatar(username: username) }
    }
}

struct AvatarListView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.avatarRecords.isEmpty {
                EmptyStateView(
                    title: "No saved avatars",
                    systemImage: "person.crop.square",
                    description: "Search for a GitHub user to add an avatar."
                )
            } else {
                List {
                    ForEach(model.avatarRecords) { avatar in
                        HStack(spacing: 14) {
                            AvatarThumbnail(data: avatar.imageData)
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                            Text(avatar.login)
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button(role: .destructive) {
                                model.deleteAvatar(avatar)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Avatar List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppleRepositoriesView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List {
            ForEach(model.repositories) { repository in
                VStack(alignment: .leading, spacing: 5) {
                    Text(repository.fullName)
                        .font(.headline)
                    Text(repository.isPrivate ? "Private" : "Public")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .task {
                    if repository.id == model.repositories.last?.id {
                        await model.loadRepositoriesIfNeeded()
                    }
                }
            }

            if model.isLoadingRepositories {
                HStack {
                    Spacer()
                    ProgressView("Loading repositories…")
                    Spacer()
                }
            } else if model.hasMoreRepositories {
                Button("Load more repositories") {
                    Task { await model.loadRepositoriesIfNeeded() }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .overlay {
            if model.repositories.isEmpty && !model.isLoadingRepositories {
                EmptyStateView(
                    title: "Apple Repositories",
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    description: "Repositories will load here."
                )
            }
        }
        .navigationTitle("Apple Repositories")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadRepositoriesIfNeeded() }
    }
}

private struct AvatarThumbnail: View {
    let data: Data

    var body: some View {
        Group {
            if let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var description: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
