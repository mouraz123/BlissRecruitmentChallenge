import Foundation
import UIKit

struct EmojiItem: Codable, Identifiable, Hashable {
    let name: String
    let url: URL

    var id: String { name }
}

struct GitHubUserResponse: Decodable {
    let login: String
    let avatarURL: URL

    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
    }
}

struct AvatarRecord: Codable, Identifiable, Hashable {
    let login: String
    let avatarURL: URL
    let imageData: Data

    var id: String { login.lowercased() }
}

struct Repository: Decodable, Identifiable, Hashable {
    let id: Int
    let fullName: String
    let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case isPrivate = "private"
    }
}

enum GitHubAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The GitHub request URL could not be created."
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case let .httpStatus(status, message):
            return "GitHub request failed (\(status)): \(message)"
        case .invalidImage:
            return "The avatar response was not a valid image."
        }
    }
}

struct GitHubAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchEmojis() async throws -> [EmojiItem] {
        let response: [String: URL] = try await get("https://api.github.com/emojis")
        return response.map { EmojiItem(name: $0.key, url: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func fetchUser(username: String) async throws -> GitHubUserResponse {
        let loginCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        let escapedUsername = username.addingPercentEncoding(withAllowedCharacters: loginCharacters) ?? username
        return try await get("https://api.github.com/users/\(escapedUsername)")
    }

    func fetchAvatar(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("BlissRecruitmentChallenge", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
            throw GitHubAPIError.invalidImage
        }
        return data
    }

    func fetchRepositories(page: Int, pageSize: Int = 10) async throws -> [Repository] {
        guard var components = URLComponents(string: "https://api.github.com/users/Apple/repos") else {
            throw GitHubAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(pageSize))
        ]
        guard let url = components.url else { throw GitHubAPIError.invalidURL }
        return try await get(url)
    }

    private func get<Response: Decodable>(_ urlString: String) async throws -> Response {
        guard let url = URL(string: urlString) else { throw GitHubAPIError.invalidURL }
        return try await get(url)
    }

    private func get<Response: Decodable>(_ url: URL) async throws -> Response {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("BlissRecruitmentChallenge", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let response = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            let payload = try? JSONDecoder().decode([String: String].self, from: data)
            let message = payload?["message"] ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            throw GitHubAPIError.httpStatus(response.statusCode, message)
        }
    }
}
