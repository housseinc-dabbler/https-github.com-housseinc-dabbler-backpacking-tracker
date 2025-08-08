import SwiftUI
import Foundation

struct GearDataWrapper: Codable {
    var items: [GearItem]
    var trips: [Trip]
    var categories: [GearCategory]
    var foodPlanTemplates: [FoodPlanTemplate]?
    var allFoodItems: [FoodItem]?
}

class GearViewModel: ObservableObject {
    @Published var allItems: [GearItem] = [] { didSet { updateGroupedItems() } }
    @Published var trips: [Trip] = []
    @Published var categories: [GearCategory] = []
    @Published var foodPlanTemplates: [FoodPlanTemplate] = []
    @Published var allFoodItems: [FoodItem] = []
    @Published var searchText = "" { didSet { updateGroupedItems() } }
    @Published var showFavoritesOnly = false { didSet { updateGroupedItems() } }
    @Published var showConsumableOnly = false { didSet { updateGroupedItems() } }
    @Published var groupedItems: [GroupedGearItems] = []
    @AppStorage("weightUnit") var weightUnit: UnitMassType = .kilograms
    @AppStorage("distanceUnit") var distanceUnit: UnitLengthType = .meters

    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gearData.json")
    }

    init() {
        load()
        updateGroupedItems()
    }

    func updateGroupedItems() {
        var filtered = allItems
        if showFavoritesOnly { filtered = filtered.filter { $0.favorite } }
        if showConsumableOnly { filtered = filtered.filter { $0.consumable } }

        if !searchText.isEmpty {
            let lowercasedSearchText = searchText.lowercased()
            filtered = filtered.filter { item in
                let categoryName = self.categoryFor(id: item.categoryID)?.name ?? ""
                let tagsString = item.tags.joined(separator: " ")
                return item.name.lowercased().contains(lowercasedSearchText) ||
                       categoryName.lowercased().contains(lowercasedSearchText) ||
                       tagsString.lowercased().contains(lowercasedSearchText)
            }
        }

        // keep only items with valid categories
        let validItems = filtered.filter { self.categoryFor(id: $0.categoryID) != nil }

        // group by category (GearCategory is Hashable)
        let itemsByCategory = Dictionary(grouping: validItems, by: { self.categoryFor(id: $0.categoryID)! })
        let sortedCategories = itemsByCategory.keys.sorted(by: { $0.name < $1.name })

        self.groupedItems = sortedCategories.map { category in
            GroupedGearItems(id: category.id, category: category, items: itemsByCategory[category] ?? [])
        }
    }

    func save() {
        do {
            let wrapper = GearDataWrapper(items: allItems, trips: trips, categories: categories, foodPlanTemplates: foodPlanTemplates, allFoodItems: allFoodItems)
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: saveURL, options: .atomicWrite)
        } catch {
            print("Failed to save data: \(error.localizedDescription)")
        }
    }

    func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            let wrapper = try JSONDecoder().decode(GearDataWrapper.self, from: data)
            self.allItems = wrapper.items
            self.trips = wrapper.trips
            self.categories = wrapper.categories
            self.foodPlanTemplates = wrapper.foodPlanTemplates ?? []
            self.allFoodItems = wrapper.allFoodItems ?? []
        } catch {
            self.allItems = []
            self.trips = []
            self.foodPlanTemplates = []
            self.allFoodItems = []
        }
        if self.categories.isEmpty {
            self.categories = GearCategory.defaultCategories()
        }
    }

    func resetToDefaults() {
        weightUnit = .kilograms
        distanceUnit = .meters
    }

    func categoryFor(id: UUID?) -> GearCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }

    func addCategory(_ category: GearCategory) { categories.append(category); save() }
    func updateCategory(_ category: GearCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) { categories[index] = category; save() }
    }
    func deleteCategory(at offsets: IndexSet) {
        let idsToDelete = offsets.map { categories[$0].id }
        if let otherCategory = categories.first(where: { $0.name == "Other" }) {
            for i in allItems.indices {
                if idsToDelete.contains(allItems[i].categoryID) { allItems[i].categoryID = otherCategory.id }
            }
        }
        categories.remove(atOffsets: offsets); save()
    }

    func addTrip(_ trip: Trip) { trips.append(trip); save() }
    func updateTrip(_ trip: Trip) {
        if let idx = trips.firstIndex(where: { $0.id == trip.id }) { trips[idx] = trip; save() }
    }
    func deleteTrip(at offsets: IndexSet) { trips.remove(atOffsets: offsets); save() }

    func updateItem(_ item: GearItem) {
        if let index = allItems.firstIndex(where: { $0.id == item.id }) { allItems[index] = item } else { allItems.append(item) }
        save()
    }

    func deleteItem(_ item: GearItem) {
        allItems.removeAll { $0.id == item.id }
        for i in trips.indices { trips[i].items.removeAll { $0.itemID == item.id } }
        save()
    }

    func deleteItems(ids: Set<UUID>) {
        allItems.removeAll { ids.contains($0.id) }
        for i in trips.indices {
            trips[i].items.removeAll { ids.contains($0.itemID) }
        }
        save()
    }

    func moveItems(ids: Set<UUID>, to newCategoryID: UUID) {
        for id in ids {
            if let index = allItems.firstIndex(where: { $0.id == id }) {
                allItems[index].categoryID = newCategoryID
            }
        }
        save()
    }

    func importGear(from newItems: [GearItem]) {
        self.allItems.append(contentsOf: newItems)
        save()
    }

    func updateTemplate(_ template: FoodPlanTemplate) {
        if let index = foodPlanTemplates.firstIndex(where: { $0.id == template.id }) { foodPlanTemplates[index] = template } else { foodPlanTemplates.append(template) }
        save()
    }

    func deleteTemplate(at offsets: IndexSet) {
        foodPlanTemplates.remove(atOffsets: offsets)
        save()
    }

    func updateFoodItem(_ foodItem: FoodItem) {
        if let index = allFoodItems.firstIndex(where: { $0.id == foodItem.id }) {
            allFoodItems[index] = foodItem
        } else {
            allFoodItems.append(foodItem)
        }
        save()
    }

    func deleteFoodItem(at offsets: IndexSet) {
        let idsToDelete = offsets.map { allFoodItems[$0].id }
        allFoodItems.remove(atOffsets: offsets)
        for i in trips.indices {
            trips[i].foodItems.removeAll { idsToDelete.contains($0.foodItemID) }
        }
        save()
    }

    func foodItemFor(id: UUID) -> FoodItem? {
        allFoodItems.first { $0.id == id }
    }

    func formattedWeight(grams: Double, unit: UnitMassType) -> String {
        let measurement = Measurement(value: grams, unit: UnitMass.grams)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: measurement.converted(to: unit.unit))
    }

    func formattedDistance(meters: Double) -> String {
        let m = Measurement(value: meters, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 2
        return formatter.string(from: m.converted(to: distanceUnit.unit))
    }
}
