//
//  PostService.swift
//  Gossip
//
//

import Foundation

struct CreatePostResponseData: Decodable {
    let postId: String
}

struct CreatePostFailResponseData: Decodable {
    let message: String
}

struct CreatePostRequestBody: Codable {
    let title: String
    let content: String?
    let imageId: String?
}

struct PublishPostRequestBody: Codable {
    let published: Bool
}

struct FetchPostFailResponseData: Decodable {
    let message: String
}

struct PublishPostFailResponseData: Decodable {
    let postId: String
    let message: String
}

struct DeletePostFailResponseData: Decodable {
    let postId: String
    let message: String
}

struct LikePostFailData: Decodable {
    let message: String
}

struct UploadImageResponseData: Decodable {
    let fileName: String
}

struct UploadImageFailResponseData: Decodable {
    let message: String
    let acceptedTypes: [String]?
}

struct UploadImage {
    let data: Data
    let fileName: String
    let mimeType: String
}

struct PostService {
    static func fetchPost(postId: String) async throws -> Post {
        let url = Constants.baseURL.appendingPathComponent("posts/\(postId)")
        let response: PostDataContainer = try await Networking.get(
            url,
            failType: FetchPostFailResponseData.self
        )
        return response.post
    }

    static func fetchPosts(endpoint: String, page: Int, limit: Int) async throws -> PostsData {
        var components = URLComponents(
            url: Constants.baseURL.appendingPathComponent("posts" + endpoint),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        return try await Networking.get(url, failType: FetchPostFailResponseData.self)
    }

    private static func uploadImage(_ image: UploadImage) async throws -> String {
        let url = Constants.baseURL.appendingPathComponent("posts/images")
        let boundary = UUID().uuidString

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(image.fileName)\"\r\n")
        body.append("Content-Type: \(image.mimeType)\r\n\r\n")
        body.append(image.data)
        body.append("\r\n--\(boundary)--\r\n")

        let response: UploadImageResponseData = try await Networking.upload(
            url,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)",
            failType: UploadImageFailResponseData.self
        )
        return response.fileName
    }

    static func createPost(title: String, content: String?, image: UploadImage?) async throws -> String {
        var imageId: String? = nil

        if let image = image {
            imageId = try await uploadImage(image)
        }

        let url = Constants.baseURL.appendingPathComponent("posts")
        let body = CreatePostRequestBody(title: title, content: content, imageId: imageId)
        let response: CreatePostResponseData = try await Networking.post(
            url,
            body: body,
            failType: CreatePostFailResponseData.self
        )

        return response.postId
    }

    static func publishPost(postId: String) async throws {
        let url = Constants.baseURL.appendingPathComponent("posts/\(postId)")
        let body = PublishPostRequestBody(published: true)
        let _: NoContent = try await Networking.patch(url, body: body, failType: PublishPostFailResponseData.self)
    }

    static func deletePost(postId: String) async throws {
        let url = Constants.baseURL.appendingPathComponent("posts/\(postId)")
        let _: NoContent = try await Networking.delete(url, failType: DeletePostFailResponseData.self)
    }

    static func likePost(postId: String, userId: String) async throws {
        let url = Constants.baseURL.appendingPathComponent("posts/\(postId)/likes/\(userId)")
        let _: NoContent = try await Networking.put(url, body: NoContent(), failType: LikePostFailData.self)
    }

    static func unlikePost(postId: String, userId: String) async throws {
        let url = Constants.baseURL.appendingPathComponent("posts/\(postId)/likes/\(userId)")
        let _: NoContent = try await Networking.delete(url, failType: LikePostFailData.self)
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
