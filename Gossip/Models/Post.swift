//
//  Post.swift
//  Gossip
//
//

import Foundation

struct PostsData: Decodable {
    let posts: [Post]
    let currentPage: Int
    let totalPages: Int
}

struct PostDataContainer: Decodable {
    let post: Post
}

struct Post: Identifiable, Decodable, Equatable {
    let id: String
    let title: String
    let content: String?
    let imageId: String?
    let createdAt: Date
    let published: Bool
    var likeCount: Int
    var isLiked: Bool
}
