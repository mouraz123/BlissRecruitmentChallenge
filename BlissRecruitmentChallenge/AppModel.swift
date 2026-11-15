import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var emojiCache: [EmojiItem] = []
    @Published private(set) var visibleEmojis: [EmojiItem] = []
    @Published private(set) var avatarRecords: [AvatarRecord] = []
    @Published private(set) var repositories: [Repository] = []
    @Published private(set) var isLoadingEmojis = false
    @Published private(set) var isSearchingAvatar = false
    @Published private(set) var isLoadingRepositories = false
    @Published private(set) var hasMoreRepositories = true
    @Published var randomEmoji: EmojiItem?
    @Published var errorMessage: String?

    private let api: GitHubAPI
    private let cache: LocalCache
    private var nextRepositoryPage = 1

    init(api: GitHubAPI = GitHubAPI(), cache: LocalCache = LocalCache()) {
        self.api = api
        self.cache = cache

        do {
            emojiCache = try cache.load([EmojiItem].self, from: .emojis) ?? []
            visibleEmojis = emojiCache
            let savedAvatars = try cache.load([AvatarRecord].self, from: .avatars) ?? []
            avatarRecords = savedAvatars.sorted {
                $0.login.localizedCaseInsensitiveCompare($1.login) == .orderedAscending
            }
        } catch {
            errorMessage = "Could not read saved data: \(error.localizedDescription)"
        }
    }

    func ensureEmojisLoaded() async {
        guard emojiCache.isEmpty, !isLoadingEmojis else { return }
        isLoadingEmojis = true
        defer { isLoadingEmojis = false }

        do {
            let items = try await api.fetchEmojis()
            try cache.save(items, to: .emojis)
            emojiCache = items
            visibleEmojis = items
        } catch {
            show(error)
        }
    }

    func chooseRandomEmoji() async {
        await ensureEmojisLoaded()
        guard let item = emojiCache.randomElement() else {
            if errorMessage == nil { errorMessage = "No emojis are available." }
            return
        }
        randomEmoji = item
    }

    func resetVisibleEmojis() {
        visibleEmojis = emojiCache
    }

    func removeEmojiFromMemory(_ emoji: EmojiItem) {
        visibleEmojis.removeAll { $0.id == emoji.id }
    }

    func searchAvatar(username: String) async {
        let query = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = "Enter a GitHub username first."
            return
        }
        isSearchingAvatar = true
        defer { isSearchingAvatar = false }

        if let saved = avatarRecords.first(where: { $0.login.caseInsensitiveCompare(query) == .orderedSame }) {
            avatarRecords.removeAll { $0.id == saved.id }
            avatarRecords.insert(saved, at: 0)
            return
        }

        do {
            let user = try await api.fetchUser(username: query)
            let imageData = try await api.fetchAvatar(from: user.avatarURL)
            let record = AvatarRecord(login: user.login, avatarURL: user.avatarURL, imageData: imageData)
            let updatedRecords = (avatarRecords + [record])
                .sorted { $0.login.localizedCaseInsensitiveCompare($1.login) == .orderedAscending }
            try cache.save(updatedRecords, to: .avatars)
            avatarRecords = updatedRecords
        } catch {
            show(error)
        }
    }

    func deleteAvatar(_ avatar: AvatarRecord) {
        let updatedRecords = avatarRecords.filter { $0.id != avatar.id }
        do {
            try cache.save(updatedRecords, to: .avatars)
            avatarRecords = updatedRecords
        } catch {
            show(error)
        }
    }

    func loadRepositoriesIfNeeded() async {
        guard hasMoreRepositories, !isLoadingRepositories else { return }
        isLoadingRepositories = true
        defer { isLoadingRepositories = false }

        do {
            let page = try await api.fetchRepositories(page: nextRepositoryPage)
            repositories.append(contentsOf: page)
            nextRepositoryPage += 1
            hasMoreRepositories = page.count == 10
        } catch {
            show(error)
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

struct LocalCache {
    enum File: String {
        case emojis = "emojis.json"
        case avatars = "avatars.json"
    }

    private let directory: URL

    init(fileManager: FileManager = .default) {
        directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BlissRecruitmentChallenge", isDirectory: true)
    }

    func load<Value: Decodable>(_ type: Value.Type, from file: File) throws -> Value? {
        let url = directory.appendingPathComponent(file.rawValue)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }

    func save<Value: Encodable>(_ value: Value, to file: File) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(value)
        try data.write(to: directory.appendingPathComponent(file.rawValue), options: .atomic)
    }
}
