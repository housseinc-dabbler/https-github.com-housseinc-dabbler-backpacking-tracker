import SwiftUI

struct GearListView: View {
    @ObservedObject var model: GearViewModel
    // This binding is now correctly driven by the GearTab in ContentView
    @Binding var isEditing: Bool
    
    @State private var showingAddSheet = false
    @State private var selection = Set<UUID>()
    @State private var expandedCategoryIDs = Set<UUID>()
    @State private var showingCategoryPicker = false

    var body: some View {
        // ZStack is used to layer the action bar over the list at the bottom.
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                SearchBar(text: $model.searchText)
                    .padding([.horizontal, .bottom])

                Picker("Weight Unit", selection: $model.weightUnit) {
                    ForEach(UnitMassType.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List(selection: $selection) {
                    ForEach(model.groupedItems) { group in
                        Section {
                            // Categories are expanded in edit mode to ensure all items are selectable.
                            if expandedCategoryIDs.contains(group.category.id) || isEditing {
                                ForEach(group.items) { item in
                                    NavigationLink(destination: GearDetailView(item: item, model: model)) {
                                        GearItemRow(item: item, model: model)
                                    }
                                }
                                .onDelete { indexSet in
                                    let itemsToDelete = indexSet.map { group.items[$0] }
                                    for item in itemsToDelete { model.deleteItem(item) }
                                }
                            }
                        } header: {
                            HStack {
                                Label(group.category.name, systemImage: group.category.iconName)
                                    .foregroundStyle(group.category.color).fontWeight(.bold)
                                Spacer()
                                // The chevron is hidden in edit mode for a cleaner look.
                                if !isEditing {
                                     Image(systemName: expandedCategoryIDs.contains(group.category.id) ? "chevron.up" : "chevron.down")
                                        .font(.caption.weight(.bold))
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isEditing { toggleCategory(id: group.category.id) }
                            }
                        }
                        .textCase(nil)
                    }
                }
                .listStyle(.plain)
                // The environment modifier ensures the list's rows correctly show selection controls.
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                // Add padding to the bottom of the list so the last item isn't hidden by the action bar.
                .padding(.bottom, isEditing ? 60 : 0)
            }
            
            // This is the new, modern action bar.
            if isEditing {
                HStack {
                    // Move Button
                    Button { showingCategoryPicker = true } label: {
                        Label("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right")
                    }
                    .disabled(selection.isEmpty)

                    Spacer()

                    // Central status text
                    Text(selection.isEmpty ? "Select Items" : "\(selection.count) Selected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .id(selection.count) // Helps SwiftUI update the text reliably

                    Spacer()

                    // Delete Button
                    Button(role: .destructive) {
                        model.deleteItems(ids: selection)
                        selection.removeAll()
                        isEditing = false
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(selection.isEmpty)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.bar) // A standard, modern translucent background.
                .transition(.move(edge: .bottom))
            }
        }
        // Animate all changes related to the isEditing state.
        .animation(.default, value: isEditing)
        // Note: The toolbar is now correctly managed by the parent GearTab view.
        .sheet(isPresented: $showingAddSheet) {
            GearDetailView(item: nil, model: model)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerSheet { newCategoryID in
                model.moveItems(ids: selection, to: newCategoryID)
                selection.removeAll()
                isEditing = false
            }
            .environmentObject(model)
        }
        .onAppear(perform: expandAll)
    }
    
    private func toggleCategory(id: UUID) {
        withAnimation(.snappy) {
            if expandedCategoryIDs.contains(id) {
                expandedCategoryIDs.remove(id)
            } else {
                expandedCategoryIDs.insert(id)
            }
        }
    }
    
    private func expandAll() {
        expandedCategoryIDs = Set(model.categories.map { $0.id })
    }
}

// MARK: - Helper Views

private struct CategoryPickerSheet: View {
    @EnvironmentObject var model: GearViewModel
    @Environment(\.dismiss) var dismiss
    var onSelect: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List(model.categories) { category in
                Button(action: {
                    onSelect(category.id)
                    dismiss()
                }) {
                    HStack {
                        Label(category.name, systemImage: category.iconName)
                            .foregroundStyle(category.color)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Move to Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct GearItemRow: View {
    let item: GearItem
    @ObservedObject var model: GearViewModel

    var body: some View {
        HStack {
            if let data = item.imageData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading) {
                Text(item.name).bold()
                if item.quantity > 1 {
                    Text("Quantity: \(item.quantity)").font(.caption).foregroundStyle(.secondary)
                }
                let totalWeight = item.weightGrams * Double(item.quantity)
                let totalPrice = item.priceCAD * Double(item.quantity)
                Text("\(model.formattedWeight(grams: totalWeight, unit: model.weightUnit)) • \(totalPrice.formatted(.currency(code: "CAD")))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search gear...", text: $text)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
