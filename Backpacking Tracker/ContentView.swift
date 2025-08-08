// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject var model = GearViewModel()

    var body: some View {
        TabView {
            GearTab(model: model)
                .tabItem { Label("Gear", systemImage: "bag.fill") }

            // RENAMED
            BackpacksTab()
                .tabItem { Label("Backpacks", systemImage: "backpack.fill") }

            PlannerHomeView()
                .tabItem { Label("Planner", systemImage: "text.book.closed.fill") }

            SettingsTab()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .environmentObject(model)
    }
}

// MARK: - Helper Views for Each Tab

private struct GearTab: View {
    @ObservedObject var model: GearViewModel
    
    var body: some View {
        NavigationStack {
            // This now passes a binding for the editing state
            GearListView(model: model, isEditing: .constant(false))
        }
    }
}

// RENAMED: TripsTab is now BackpacksTab
private struct BackpacksTab: View {
    @EnvironmentObject var model: GearViewModel

    var body: some View {
        NavigationStack {
            List {
                // Now iterates over the renamed 'backpacks'
                ForEach($model.backpacks) { $backpack in
                    NavigationLink(value: backpack) {
                        VStack(alignment: .leading) {
                           Text(backpack.name).font(.headline)
                           let itemCount = backpack.items.count
                           Text("\(itemCount) item type\(itemCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: model.deleteBackpack)
                .onMove { from, to in
                    model.backpacks.move(fromOffsets: from, toOffset: to)
                }
            }
            .navigationTitle("Backpacks")
            .navigationDestination(for: Backpack.self) { backpack in
                if let index = model.backpacks.firstIndex(where: { $0.id == backpack.id }) {
                    // Navigate to the renamed detail view
                    BackpackDetailView(backpack: $model.backpacks[index])
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Backpack", systemImage: "plus") {
                        let newBackpack = Backpack(name: "New Backpack", items: [])
                        model.addBackpack(newBackpack)
                    }
                }
            }
        }
    }
}

private struct SettingsTab: View {
    var body: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
