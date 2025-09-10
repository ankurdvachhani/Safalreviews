import SwiftUI
import PhotosUI

struct CommentSheet: View {
    let post: Post
    let onCommentAdded: (() -> Void)?
    @StateObject private var commentViewModel = CommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingImageSourceSheet = false
    @State private var showingFullScreenMedia: MediaPresentationData?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Comments list
                commentsListView
                
                // Comment input
                commentInputView
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            commentViewModel.onCommentAdded = onCommentAdded
            Task {
                await commentViewModel.fetchComments(for: post.id)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            CommentImagePicker(selectedImages: $commentViewModel.selectedImages, maxImages: 4)
        }
        .sheet(isPresented: $showingCamera) {
            CommentCameraPicker(selectedImages: $commentViewModel.selectedImages, maxImages: 4)
        }
        .actionSheet(isPresented: $showingImageSourceSheet) {
            ActionSheet(
                title: Text("Add Image"),
                message: Text("Choose how you want to add an image"),
                buttons: [
                    .default(Text("Camera")) {
                        showingCamera = true
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .fullScreenCover(item: $showingFullScreenMedia) { mediaData in
            FullScreenMediaView(
                mediaURLs: mediaData.mediaURLs,
                initialIndex: mediaData.initialIndex,
                isPresented: $showingFullScreenMedia
            )
        }
        .toast(message: $commentViewModel.errorMessage, type: .error)
        .toast(message: $commentViewModel.successMessage, type: .success)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Comments")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Placeholder for balance
                Color.clear
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
        }
    }
    
    // MARK: - Comments List View
    private var commentsListView: some View {
        Group {
            if commentViewModel.isLoading && commentViewModel.comments.isEmpty {
                loadingView
            } else if commentViewModel.comments.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(commentViewModel.comments) { comment in
                            CommentRowView(
                                comment: comment,
                                onLike: {
                                    Task {
                                        await commentViewModel.likeComment(comment)
                                    }
                                },
                                onDislike: {
                                    Task {
                                        await commentViewModel.dislikeComment(comment)
                                    }
                                },
                                onImageTap: { imageURLs, selectedIndex in
                                    showingFullScreenMedia = MediaPresentationData(
                                        mediaURLs: imageURLs,
                                        initialIndex: selectedIndex
                                    )
                                }
                            )
                        }
                        
                        if commentViewModel.isLoading && !commentViewModel.comments.isEmpty {
                            loadingIndicator
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .refreshable {
                    await commentViewModel.refreshComments(for: post.id)
                }
            }
        }
    }
    
    // MARK: - Comment Input View
    private var commentInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                // Selected images preview
                if !commentViewModel.selectedImages.isEmpty {
                    selectedImagesPreview
                }
                
                HStack(alignment: .center, spacing: 12) {
                    // Image picker button
                    Button(action: {
                        showingImageSourceSheet = true
                    }) {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(commentViewModel.selectedImages.count >= 4)
                    
                    // Text input
                    TextField("Add a comment...", text: $commentViewModel.commentText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...4)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    
                    // Send button
                    Button(action: {
                        Task {
                            await commentViewModel.addComment(to: post.id)
                        }
                    }) {
                        if commentViewModel.isAddingComment {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(
                        commentViewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && commentViewModel.selectedImages.isEmpty
                        ? Color.gray
                        : Color.blue
                    )
                    .clipShape(Circle())
                    .disabled(commentViewModel.commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && commentViewModel.selectedImages.isEmpty || commentViewModel.isAddingComment)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Selected Images Preview
    private var selectedImagesPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(commentViewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: {
                            commentViewModel.removeImage(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .offset(x: 4, y: -4)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading comments...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left")
                .font(.system(size: 60))
                .foregroundColor(Color.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Comments Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Be the first to share your thoughts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: PostComment
    let onLike: () -> Void
    let onDislike: () -> Void
    let onImageTap: ([String], Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info and date
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: comment.user.profilePicture ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(comment.formattedCreatedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Comment text
            Text(comment.comment)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            // Comment images
            if !comment.imgs.isEmpty {
                commentImagesView
            }
            
            // Like/Dislike buttons
            HStack(spacing: 16) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 14))
                        Text("\(comment.likesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(comment.isLiked ? .blue : .secondary)
                }
                
                Button(action: onDislike) {
                    HStack(spacing: 4) {
                        Image(systemName: comment.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.system(size: 14))
                        Text("\(comment.dislikesCount)")
                            .font(.caption)
                    }
                    .foregroundColor(comment.isDisliked ? .red : .secondary)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Comment Images View
    private var commentImagesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(comment.imgs.enumerated()), id: \.element) { index, imageURL in
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        onImageTap(comment.imgs, index)
                    }
                }
            }
        }
    }
}

// MARK: - Comment Image Picker
struct CommentImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxImages: Int
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = maxImages - selectedImages.count
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: CommentImagePicker
        
        init(_ parent: CommentImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.selectedImages.append(image)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Comment Camera Picker
struct CommentCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    let maxImages: Int
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CommentCameraPicker
        
        init(_ parent: CommentCameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    if self.parent.selectedImages.count < self.parent.maxImages {
                        self.parent.selectedImages.append(image)
                    }
                }
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    CommentSheet(post: Post.mockPost, onCommentAdded: nil)
}
