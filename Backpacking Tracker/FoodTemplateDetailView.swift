// FoodTemplateDetailView.swift
import SwiftUI

struct FoodTemplateDetailView: View {
    @EnvironmentObject var model: GearViewModel
    @Binding var template: FoodPlanTemplate
    
    @State private var showingPantrySelector = false

    var body: some View {
        // The view is now a simple list of the items in the template.
        List {
            ForEach(template.items) { item in
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
            }
            .onDelete { offsets in
                template.items.remove(atOffsets: offsets)
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add From Pantry", systemImage: "plus") {
                    showingPantrySelector = true
                }
            }
        }
        .sheet(isPresented: $showingPantrySelector) {
            // This presents a new view to select items from the main food pantry.
            PantrySelectorForTemplateView(template: $template)
        }
        .onDisappear {
            // Save any changes when the view disappears.
            model.updateTemplate(template)
        }
    }
}


// A new helper view to select items from the pantry to add to the template.
struct PantrySelectorForTemplateView: View {
    @EnvironmentObject var model: GearViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var template: FoodPlanTemplate
    
    var body: some View {
        NavigationStack {
            List(model.allFoodItems) { foodItem in
                Button(action: {
                    // Add the selected food item to the template's item list.
                    if !template.items.contains(where: { $0.id == foodItem.id }) {
                        template.items.append(foodItem)
                    }
                }) {
                    HStack {
                        if let data = foodItem.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Text(foodItem.name)
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Select From Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
