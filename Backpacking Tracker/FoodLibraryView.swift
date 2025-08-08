// FoodLibraryView.swift
import SwiftUI

struct FoodLibraryView: View {
    @EnvironmentObject var model: GearViewModel
    @State private var showingForm = false
    @State private var itemToEdit: FoodItem?

    var body: some View {
        List {
            ForEach(model.allFoodItems) { item in
                HStack {
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable().scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading) {
                        Text(item.name).bold()
                        let totalWeight = item.weightInGrams + item.packagingWeightGrams
                        Text(String(format: "%.0fg • %.0f kCal", totalWeight, item.calories))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    itemToEdit = item
                    showingForm = true
                }
            }
            .onDelete(perform: model.deleteFoodItem)
        }
        .navigationTitle("Food Pantry")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    itemToEdit = nil
                    showingForm = true
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            FoodItemFormView(model: model, itemToEdit: itemToEdit)
        }
    }
}
