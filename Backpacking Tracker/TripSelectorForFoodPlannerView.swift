import SwiftUI

struct BackpackSelectorView: View {
    @EnvironmentObject var model: GearViewModel

    var body: some View {
        listView
            .navigationTitle("Select a Backpack")
    }

    private var listView: some View {
        List {
            if model.backpacks.isEmpty {
                Text("No backpacks found. Please create a backpack from the 'Backpacks' tab before planning.")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach($model.backpacks) { $backpack in
                    NavigationLink(destination: BackpackDetailView(backpack: $backpack)) {
                        VStack(alignment: .leading) {
                            Text(backpack.name)
                                .font(.headline)
                            Text("Contains \(backpack.items.count) item(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
