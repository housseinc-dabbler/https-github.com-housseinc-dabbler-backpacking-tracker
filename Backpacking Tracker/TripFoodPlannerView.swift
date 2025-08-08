// TripFoodPlannerView.swift
import SwiftUI

struct TripFoodPlannerView: View {
    @EnvironmentObject var model: GearViewModel
    // RENAMED
    @Binding var backpack: Backpack
    
    @State private var showingPantrySelector = false
    @State private var showingManualAddForm = false
    @State private var tripFoodToEdit: TripFood?

    var body: some View {
        tripFoodList
            .navigationTitle("Food Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Menu {
                    Button("Add From Pantry", systemImage: "list.bullet") {
                        showingPantrySelector = true
                    }
                    Button("Add Manually", systemImage: "square.and.pencil") {
                        showingManualAddForm = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingPantrySelector) {
                // Pass the backpack binding to the selector view
                PantrySelectorView(backpack: $backpack)
            }
            .sheet(isPresented: $showingManualAddForm) {
                FoodItemFormView(model: model, itemToEdit: nil) { newFoodItem in
                    let newTripFood = TripFood(foodItemID: newFoodItem.id, day: 1, mealType: .snack)
                    backpack.foodItems.append(newTripFood)
                }
            }
            .sheet(item: $tripFoodToEdit) { itemToEdit in
                if let index = backpack.foodItems.firstIndex(where: { $0.id == itemToEdit.id }),
                   let foodItem = model.foodItemFor(id: itemToEdit.foodItemID) {
                    TripFoodEditView(tripFood: $backpack.foodItems[index], foodItemName: foodItem.name)
                }
            }
    }
    
    private var tripFoodList: some View {
        List {
            Section(header: Text("Trip Totals")) {
                TripSummaryHeader(tripFoods: backpack.foodItems, model: model)
            }
            
            let itemsByDay = Dictionary(grouping: backpack.foodItems, by: { $0.day })
            let sortedDays = itemsByDay.keys.sorted()
            
            ForEach(sortedDays, id: \.self) { day in
                Section(header: DayHeader(day: day, tripFoods: itemsByDay[day] ?? [], model: model)) {
                    ForEach(MealType.allCases) { mealType in
                        let itemsForMeal = itemsByDay[day]?.filter { $0.mealType == mealType } ?? []
                        if !itemsForMeal.isEmpty {
                            mealSection(mealType: mealType, items: itemsForMeal)
                        }
                    }
                }
            }
        }
    }
    
    private func mealSection(mealType: MealType, items: [TripFood]) -> some View {
        Section(header: MealHeader(mealType: mealType, tripFoods: items, model: model)) {
            ForEach(items) { tripFood in
                if let foodItem = model.foodItemFor(id: tripFood.foodItemID) {
                    if let index = backpack.foodItems.firstIndex(where: { $0.id == tripFood.id }) {
                        FoodItemRow(foodItem: foodItem, tripFood: $backpack.foodItems[index])
                            .onTapGesture {
                                self.tripFoodToEdit = tripFood
                            }
                    }
                }
            }
            .onDelete { offsets in
                deleteItem(at: offsets, in: items)
            }
        }
    }

    private func deleteItem(at offsets: IndexSet, in items: [TripFood]) {
        for index in offsets {
            let itemToDelete = items[index]
            if let masterIndex = backpack.foodItems.firstIndex(where: { $0.id == itemToDelete.id }) {
                backpack.foodItems.remove(at: masterIndex)
            }
        }
    }
}


// MARK: - Subviews for TripFoodPlannerView (Now Correct)

private struct TripSummaryHeader: View {
    let tripFoods: [TripFood]
    let model: GearViewModel
    
    private var totalWeight: Double { calculateTotal { ($0.weightInGrams + $0.packagingWeightGrams) * Double($1.quantity) } }
    private var totalCalories: Double { calculateTotal { $0.calories * Double($1.quantity) } }
    private var totalFat: Double { calculateTotal { $0.fat * Double($1.quantity) } }
    private var totalCarbs: Double { calculateTotal { $0.carbs * Double($1.quantity) } }
    private var totalProtein: Double { calculateTotal { $0.protein * Double($1.quantity) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Macros: \(Int(totalFat))g F • \(Int(totalCarbs))g C • \(Int(totalProtein))g P")
                .font(.headline)
            HStack(spacing: 15) {
                Label(String(format: "%.0fg", totalWeight), systemImage: "scalemass.fill")
                Label(String(format: "%.0f kCal", totalCalories), systemImage: "flame.fill")
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func calculateTotal(value: (FoodItem, TripFood) -> Double) -> Double {
        tripFoods.reduce(0) { total, tripFood in
            if let foodItem = model.foodItemFor(id: tripFood.foodItemID) {
                return total + value(foodItem, tripFood)
            }
            return total
        }
    }
}

private struct DayHeader: View {
    let day: Int
    let tripFoods: [TripFood]
    let model: GearViewModel
    
    private var totalWeight: Double { calculateTotal { ($0.weightInGrams + $0.packagingWeightGrams) * Double($1.quantity) } }
    private var totalCalories: Double { calculateTotal { $0.calories * Double($1.quantity) } }
    private var totalFat: Double { calculateTotal { $0.fat * Double($1.quantity) } }
    private var totalCarbs: Double { calculateTotal { $0.carbs * Double($1.quantity) } }
    private var totalProtein: Double { calculateTotal { $0.protein * Double($1.quantity) } }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Day \(day)").font(.title2).bold().foregroundColor(.primary)
            Text("Macros: \(Int(totalFat))g F • \(Int(totalCarbs))g C • \(Int(totalProtein))g P")
                .font(.caption).bold().foregroundStyle(.secondary)
            HStack {
                Label(String(format: "%.0fg", totalWeight), systemImage: "scalemass.fill")
                Label(String(format: "%.0f kCal", totalCalories), systemImage: "flame.fill")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    private func calculateTotal(value: (FoodItem, TripFood) -> Double) -> Double {
        tripFoods.reduce(0) { total, tripFood in
            if let foodItem = model.foodItemFor(id: tripFood.foodItemID) {
                return total + value(foodItem, tripFood)
            }
            return total
        }
    }
}

private struct MealHeader: View {
    let mealType: MealType
    let tripFoods: [TripFood]
    let model: GearViewModel
    
    private var totalCalories: Double { calculateTotal { $0.calories * Double($1.quantity) } }
    private var totalWeight: Double { calculateTotal { ($0.weightInGrams + $0.packagingWeightGrams) * Double($1.quantity) } }

    var body: some View {
        HStack {
            Text(mealType.rawValue).font(.headline)
            Spacer()
            Text("\(Int(totalWeight))g • \(Int(totalCalories)) kCal").font(.caption).foregroundStyle(.secondary)
        }
        .listRowBackground(Color(.systemGray6))
    }

    private func calculateTotal(value: (FoodItem, TripFood) -> Double) -> Double {
        tripFoods.reduce(0) { total, tripFood in
            if let foodItem = model.foodItemFor(id: tripFood.foodItemID) {
                return total + value(foodItem, tripFood)
            }
            return total
        }
    }
}


private struct FoodItemRow: View {
    let foodItem: FoodItem
    @Binding var tripFood: TripFood
    
    var body: some View {
        HStack {
            if let data = foodItem.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(foodItem.name)
                Text("Macros (ea): \(Int(foodItem.fat))g F, \(Int(foodItem.carbs))g C, \(Int(foodItem.protein))g P")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Qty", selection: $tripFood.quantity) {
                ForEach(1...50, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 90)
        }
        .padding(.vertical, 4)
    }
}

// PantrySelectorView is now refactored
struct PantrySelectorView: View {
    @EnvironmentObject var model: GearViewModel
    @Environment(\.dismiss) var dismiss
    // RENAMED
    @Binding var backpack: Backpack
    
    @State private var mealType: MealType = .snack
    @State private var day: Int = 1
    @State private var selections = Set<UUID>()

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.menu)
                    
                    Stepper("Day \(day)", value: $day, in: 1...100)
                }
                .padding(.horizontal)

                List(model.allFoodItems, selection: $selections) { foodItem in
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
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Select From Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selections.count))") {
                        addSelectedItems()
                        dismiss()
                    }
                    .disabled(selections.isEmpty)
                }
            }
        }
    }
    
    private func addSelectedItems() {
        for foodID in selections {
            // RENAMED
            if let existingIndex = backpack.foodItems.firstIndex(where: {
                $0.foodItemID == foodID && $0.day == day && $0.mealType == mealType
            }) {
                backpack.foodItems[existingIndex].quantity += 1
            } else {
                let newTripFood = TripFood(foodItemID: foodID, quantity: 1, day: day, mealType: mealType)
                backpack.foodItems.append(newTripFood)
            }
        }
    }
}
