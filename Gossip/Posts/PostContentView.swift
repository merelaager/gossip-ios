//
//  PostContentView.swift
//  Gossip
//
//  Created by Taaniel Kraavi on 08.07.2025.
//

import SwiftUI

struct PostContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.title)
            
            Text(post.createdAt.formattedLocalShort())
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            if !post.published {
                Divider()
                Text("Postitus on ootel. Admin peab selle kinnitama.")
                    .font(.body)
                    .foregroundColor(.pink)
                    .padding(.vertical, 2)
                Divider()
            }
            
            Text(post.content ?? "")
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let mockViewModel = PostsViewModel(endpoint: "")
    PostDetailView(postId: "3927cd13-1dae-4fd3-b93d-f5003610fcb2", viewModel: mockViewModel)
        .environment(SessionManager())
}
