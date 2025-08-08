// TripFoodEditView.swift
import SwiftUI

struct TripFoodEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tripFood: TripFood
    let foodItemName: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Stepper("Quantity: \(tripFood.quantity)", value: $tripFood.quantity, in: 1...100)
                    Stepper("Day: \(tripFood.day)", value: $tripFood.day, in: 1...100)
                    Picker("Meal", selection: $tripFood.mealType) {
                        ForEach(MealType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
            }
            .navigationTitle(foodItemName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
