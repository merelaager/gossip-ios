//
//  PostsViewModel.swift
//  Gossip
//
//

import Foundation

@MainActor
@Observable
class PostsViewModel {
    var posts: [Post] = []
    var currentPage: Int = 1
    var totalPages: Int = 1
    var isLoading: Bool = false

    private var endpoint: String

    init(endpoint: String) {
        self.endpoint = endpoint
    }

    func deletePost(withId id: String) {
        posts.removeAll { $0.id == id }
    }

    func updatePost(_ updatedPost: Post) {
        if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
            posts[index] = updatedPost
        }
    }

    func fetchPosts(reset: Bool = false) async {
        guard !isLoading else { return }

        if !reset && currentPage > totalPages { return }

        isLoading = true

        if reset {
            currentPage = 1
        }

        do {
            let data = try await PostService.fetchPosts(
                endpoint: endpoint,
                page: currentPage,
                limit: 25
            )

            if reset {
                posts = data.posts
            } else {
                posts += data.posts
            }
            totalPages = data.totalPages
            currentPage += 1
        } catch {
            print("Error fetching posts: \(error)")
        }

        isLoading = false
    }

    func resetAndFetch() async {
        currentPage = 1
        await fetchPosts(reset: true)
    }

    func goToPage(_ page: Int) async {
        guard page >= 1 else { return }
        if page > totalPages { return }

        currentPage = page
        await fetchPosts()
    }
}
