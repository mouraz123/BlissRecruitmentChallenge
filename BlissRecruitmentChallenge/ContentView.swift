import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            List {
                Section("Emojis") {
                    NavigationLink {
                        RandomEmojiView()
                    } label: {
                        Label("Random Emoji", systemImage: "face.smiling")
                    }
                    NavigationLink {
                        EmojiListView()
                    } label: {
                        Label("Emoji List", systemImage: "square.grid.2x2")
                    }
                }

                Section("GitHub") {
                    NavigationLink {
                        AvatarSearchView()
                    } label: {
                        Label("Search User Avatar", systemImage: "magnifyingglass")
                    }
                    NavigationLink {
                        AvatarListView()
                    } label: {
                        Label("Avatar List", systemImage: "person.crop.square")
                    }
                    NavigationLink {
                        AppleRepositoriesView()
                    } label: {
                        Label("Apple Repositories", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Bliss Challenge")
            .alert("Something went wrong", isPresented: errorIsPresented) {
                Button("OK", role: .cancel) { model.dismissError() }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.dismissError() } }
        )
    }
}
