//
//  PostsView.swift
//  Gossip
//
//

import SwiftUI

struct PostsView: View {
    @Environment(SessionManager.self) private var sessionManager

    let title: String
    @State var viewModel: PostsViewModel

    @State private var showCreatePost = false
    @State private var postIsOpen = false

    @State private var initialLoadInProgress = true

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if initialLoadInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.posts.isEmpty {
                        ScrollView {
                            VStack {
                                Text("Postitusi pole.")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .refreshable {
                            Task {
                                await viewModel.resetAndFetch()
                            }
                        }
                    } else {
                        PostListView(viewModel: viewModel)
                    }
                }
                .navigationTitle(title)
                .onAppear {
                    if viewModel.posts.isEmpty {
                        Task {
                            await viewModel.resetAndFetch()
                            initialLoadInProgress = false
                        }
                    }
                }
                if sessionManager.currentUser?.role != "READER" && !postIsOpen {
                    FloatingCreatePostButton {
                        showCreatePost = true
                    }
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
}

#Preview {
    let sessionManager = SessionManager()
    PostsView(title: "Kõlakad", viewModel: PostsViewModel(endpoint: ""))
        .environment(sessionManager)
        .task { await sessionManager.getCurrentUser() }
}
