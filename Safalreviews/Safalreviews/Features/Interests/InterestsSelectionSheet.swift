//
//  InterestsSelectionSheet.swift
//  Safalreviews
//
//  Created by Antigravity on 23/03/30.
//

import SwiftUI

struct InterestsSelectionSheet: View {
    @StateObject private var viewModel: InterestsViewModel
    @Environment(\.dismiss) var dismiss
    var onSave: (() -> Void)?
    
    init(onSave: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: InterestsViewModel())
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    List {
                        Section(header: Text("Select your interests to personalize your experience.")) {
                            ForEach(viewModel.allInterests) { interest in
                                HStack {
                                    Text(interest.label)
                                    Spacer()
                                    if viewModel.selectedInterests.contains(interest.value) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.toggleInterest(interest.value)
                                }
                            }
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.saveInterests()
                            if viewModel.isSaved {
                                dismiss()
                                onSave?()
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Your Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.fetchAllInterests()
                await viewModel.fetchUserSelectedInterests()
            }
        }
    }
}

#Preview {
    InterestsSelectionSheet()
}
