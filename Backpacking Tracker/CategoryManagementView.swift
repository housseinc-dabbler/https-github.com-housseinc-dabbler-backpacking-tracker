// CategoryManagementView.swift
import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var model: GearViewModel
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(model.categories) { category in
                NavigationLink(destination: CategoryEditView(category: category)) {
                    Label(category.name, systemImage: category.iconName)
                        .foregroundStyle(category.color)
                }
            }
            .onDelete(perform: model.deleteCategory)
            .onMove { from, to in
                model.categories.move(fromOffsets: from, toOffset: to)
                model.save()
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") { showingAddSheet = true }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            // Pass a new, blank category to the edit view
            CategoryEditView(category: GearCategory(name: "", iconName: "questionmark.diamond.fill", colorName: "gray"), isNew: true)
        }
    }
}
