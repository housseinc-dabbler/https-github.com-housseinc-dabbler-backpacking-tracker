import SwiftUI

struct TripItemSelectorView: View {
    @EnvironmentObject var model: GearViewModel
    @Binding var backpack: Backpack

    var itemsByCategory: [GearCategory: [GearItem]] {
        let grouped = Dictionary(grouping: model.allItems, by: { model.categoryFor(id: $0.categoryID) })
        let validGroups = grouped.filter { $0.key != nil }
        
        return Dictionary(uniqueKeysWithValues: validGroups.map { (key, value) in
            (key!, value)
        })
    }
    
    var sortedCategories: [GearCategory] {
        itemsByCategory.keys.sorted(by: { $0.name < $1.name })
    }

    var body: some View {
        List {
            ForEach(sortedCategories) { category in
                Section(header: Text(category.name)) {
                    ForEach(itemsByCategory[category] ?? []) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name).bold()
                                Text(model.categoryFor(id: item.categoryID)?.name ?? "Unknown")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            if let backpackItemIndex = backpack.items.firstIndex(where: { $0.itemID == item.id }) {
                                Stepper(
                                    "Qty: \(backpack.items[backpackItemIndex].quantity)",
                                    value: $backpack.items[backpackItemIndex].quantity,
                                    in: 0...item.quantity,
                                    onEditingChanged: { isEditing in
                                        if !isEditing && backpack.items[backpackItemIndex].quantity == 0 {
                                            backpack.items.remove(at: backpackItemIndex)
                                        }
                                    }
                                )
                                .frame(width: 150)
                            } else {
                                Button("Add") {
                                    let newBackpackItem = BackpackItem(itemID: item.id, quantity: 1)
                                    backpack.items.append(newBackpackItem)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Items")
    }
}
