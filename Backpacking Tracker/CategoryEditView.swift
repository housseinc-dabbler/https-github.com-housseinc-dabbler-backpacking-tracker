// CategoryEditView.swift
import SwiftUI

struct CategoryEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var model: GearViewModel
    
    @State var category: GearCategory
    var isNew: Bool = false

    let colors = ["gray", "brown", "green", "purple", "orange", "blue", "cyan", "red", "indigo", "mint", "yellow", "pink"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $category.name)
                    NavigationLink(destination: IconPicker(selectedIcon: $category.iconName)) {
                        HStack {
                            Text("Icon")
                            Spacer()
                            Image(systemName: category.iconName)
                        }
                    }
                }

                Section("Color") {
                    Picker("Color", selection: $category.colorName) {
                        ForEach(colors, id: \.self) { colorName in
                            Text(colorName.capitalized).tag(colorName)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
            }
            .navigationTitle(isNew ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // The "Cancel" button has been removed
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isNew {
                            model.addCategory(category)
                        } else {
                            model.updateCategory(category)
                        }
                        dismiss()
                    }
                    .disabled(category.name.isEmpty)
                }
            }
        }
    }
}
