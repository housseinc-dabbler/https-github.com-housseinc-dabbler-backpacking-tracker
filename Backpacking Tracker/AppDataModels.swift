// AppDataModels.swift
import Foundation
import SwiftUI

// MARK: - Unit Types
enum UnitMassType: String, CaseIterable, Identifiable {
    case grams = "g", kilograms = "kg", ounces = "oz", pounds = "lbs"
    var id: String { rawValue }
    var unit: UnitMass {
        switch self {
        case .grams: return .grams
        case .kilograms: return .kilograms
        case .ounces: return .ounces
        case .pounds: return .pounds
        }
    }
}

enum UnitLengthType: String, CaseIterable, Identifiable {
    case meters = "m", kilometers = "km", miles = "mi"
    var id: String { rawValue }
    var unit: UnitLength {
        switch self {
        case .meters: return .meters
        case .kilometers: return .kilometers
        case .miles: return .miles
        }
    }
}

// MARK: - Food Planner Models
enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Breakfast", lunch = "Lunch", dinner = "Dinner", snack = "Snacks & Drinks"
    var id: Self { self }
}

struct FoodItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var weightInGrams: Double
    var packagingWeightGrams: Double = 0
    var calories: Double
    var fat: Double
    var carbs: Double
    var protein: Double
    var notes: String = ""
    var imageData: Data?
}

struct TripFood: Identifiable, Codable, Hashable {
    var id = UUID()
    var foodItemID: UUID
    var quantity: Int = 1
    var day: Int = 1
    var mealType: MealType
}

struct FoodPlanTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var items: [FoodItem]
}

// MARK: - App-Specific Models
struct GearCategory: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var iconName: String
    var colorName: String

    var color: Color {
        switch colorName {
        case "brown": return .brown
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "blue": return .blue
        case "cyan": return .cyan
        case "red": return .red
        case "indigo": return .indigo
        case "mint": return .mint
        case "yellow": return .yellow
        case "pink": return .pink
        default: return .gray
        }
    }

    static func defaultCategories() -> [GearCategory] {
        [
            .init(name: "Packs", iconName: "backpack.fill", colorName: "brown"),
            .init(name: "Shelter", iconName: "tent.fill", colorName: "green"),
            .init(name: "Sleep System", iconName: "bed.double.fill", colorName: "purple"),
            .init(name: "Cooking & Water", iconName: "stove.fill", colorName: "orange"),
            .init(name: "Food", iconName: "fork.knife", colorName: "yellow"),
            .init(name: "Clothing", iconName: "tshirt.fill", colorName: "cyan"),
            .init(name: "Footwear", iconName: "shoe.fill", colorName: "brown"),
            .init(name: "Electronics", iconName: "macmini.fill", colorName: "blue"),
            .init(name: "Navigation", iconName: "map.fill", colorName: "yellow"),
            .init(name: "First Aid & Safety", iconName: "cross.case.fill", colorName: "red"),
            .init(name: "Hygiene", iconName: "hand.sparkles.fill", colorName: "mint"),
            .init(name: "Tools & Repair", iconName: "wrench.and.screwdriver.fill", colorName: "gray"),
            .init(name: "Photography", iconName: "camera.fill", colorName: "indigo"),
            .init(name: "Personal Items", iconName: "person.fill", colorName: "pink"),
            .init(name: "Other", iconName: "questionmark.diamond.fill", colorName: "gray")
        ]
    }
    
    private static let unknownCategoryID = UUID()
    static func unknownCategory() -> GearCategory {
        return GearCategory(id: unknownCategoryID, name: "Unknown Category", iconName: "questionmark.folder.fill", colorName: "gray")
    }
}

struct GearItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var categoryID: UUID
    var weightGrams: Double
    var priceCAD: Double
    var wornWeight: Bool
    var consumable: Bool
    var favorite: Bool
    var isOptional: Bool = false
    var quantity: Int = 1
    var description: String
    var notes: String
    var tags: [String]
    var productURLString: String
    var imageData: Data?
}

// RENAMED
struct BackpackItem: Identifiable, Codable, Hashable {
    var id: UUID { itemID }
    var itemID: UUID
    var quantity: Int
}

// RENAMED
struct Backpack: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var description: String = ""
    var items: [BackpackItem]
    var foodItems: [TripFood] = []
}

// MARK: - Analytics and UI Helper Types
struct GroupedGearItems: Identifiable {
    let id: UUID
    var category: GearCategory
    var items: [GearItem]
}

struct CategorySummary: Identifiable, Hashable {
    let id: GearCategory
    var category: GearCategory
    var weight: Double
    var price: Double
}

enum ChartType: String, CaseIterable, Identifiable {
    case bar = "Bar", pie = "Pie"
    var id: Self { self }
}
