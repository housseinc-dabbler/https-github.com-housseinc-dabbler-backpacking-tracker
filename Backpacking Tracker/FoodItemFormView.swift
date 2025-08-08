// FoodItemFormView.swift
import SwiftUI

struct FoodItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: GearViewModel
    
    @State private var item: FoodItem
    private var isNew: Bool
    
    // NEW: An optional closure to run after saving a new item.
    var onSave: ((FoodItem) -> Void)?
    
    // State for API Search
    @State private var searchQuery = ""
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    private let dbService = FoodDatabaseService()
    
    init(model: GearViewModel, itemToEdit: FoodItem?, onSave: ((FoodItem) -> Void)? = nil) {
        self.model = model
        self.onSave = onSave
        if let item = itemToEdit {
            _item = State(initialValue: item)
            self.isNew = false
        } else {
            _item = State(initialValue: FoodItem(name: "", weightInGrams: 0, calories: 0, fat: 0, carbs: 0, protein: 0))
            self.isNew = true
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Search USDA Database") {
                    HStack {
                        TextField("Search for a food...", text: $searchQuery)
                        if isSearching {
                            ProgressView()
                        } else {
                            Button("Search", systemImage: "magnifyingglass") {
                                Task { await performSearch() }
                            }
                        }
                    }
                    if !searchResults.isEmpty {
                        List(searchResults) { result in
                            Button(action: { selectSearchResult(result) }) {
                                VStack(alignment: .leading) {
                                    Text(result.name).bold()
                                    Text("Per 100g: \(Int(result.calories)) kCal, F:\(Int(result.fat))g, C:\(Int(result.carbs))g, P:\(Int(result.protein))g")
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Name", text: $item.name)
                    PhotoPicker(imageData: $item.imageData)
                }
                
                Section("Nutrition (per single item)") {
                    nutritionRow(label: "Item Weight", unit: "g", value: $item.weightInGrams)
                    nutritionRow(label: "Packaging Weight", unit: "g", value: $item.packagingWeightGrams)
                    nutritionRow(label: "Calories", unit: "kCal", value: $item.calories)
                    nutritionRow(label: "Fat", unit: "g", value: $item.fat)
                    nutritionRow(label: "Carbs", unit: "g", value: $item.carbs)
                    nutritionRow(label: "Protein", unit: "g", value: $item.protein)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $item.notes, axis: .vertical)
                }
            }
            .navigationTitle(isNew ? "New Pantry Food" : "Edit Pantry Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .disabled(item.name.isEmpty)
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        model.updateFoodItem(item)
        // If this form was presented to create a new item for a trip,
        // call the completion handler.
        if isNew {
            onSave?(item)
        }
        dismiss()
    }
    
    private func nutritionRow(label: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text(unit)
        }
    }
    
    private func performSearch() async {
        isSearching = true
        do {
            searchResults = try await dbService.search(for: searchQuery)
        } catch {
            print("Food search failed: \(error)")
            searchResults = []
        }
        isSearching = false
    }

    private func selectSearchResult(_ result: FoodItem) {
        item.name = result.name
        item.weightInGrams = result.weightInGrams
        item.calories = result.calories
        item.fat = result.fat
        item.carbs = result.carbs
        item.protein = result.protein
        
        searchQuery = ""
        searchResults = []
    }
}
