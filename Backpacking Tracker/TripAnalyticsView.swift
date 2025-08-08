// TripAnalyticsView.swift
import SwiftUI
import Charts

// A helper struct to manage the alert content, making it identifiable.
private struct AlertInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct TripAnalyticsView: View {
    // RENAMED
    let backpack: Backpack
    @EnvironmentObject var model: GearViewModel
    
    @State private var displayUnit: UnitMassType
    @State private var alertInfo: AlertInfo?

    // Helper struct to hold all calculated values for the trip
    private struct TripCalculations {
        let allItems: [GearItem]
        let baseWeight, consumableWeight, wornWeight, optionalWeight, trailWeight, totalWeight: Double
        let totalCost: Double
        let summaries: [CategorySummary]
    }
    
    // RENAMED
    init(backpack: Backpack) {
        self.backpack = backpack
        _displayUnit = State(initialValue: GearViewModel().weightUnit)
    }
    
    // Compute all values in one place
    private var calculations: TripCalculations {
        // RENAMED
        let allItemsInTrip = backpack.items.compactMap { backpackItem in
            model.allItems.first { $0.id == backpackItem.itemID }
        }
        
        let nonOptionalItems = allItemsInTrip.filter { !$0.isOptional }
        let baseItems = nonOptionalItems.filter { !$0.consumable && !$0.wornWeight }
        let consumableItems = nonOptionalItems.filter { $0.consumable && !$0.wornWeight }
        let wornItems = allItemsInTrip.filter { $0.wornWeight }
        let optionalItems = allItemsInTrip.filter { $0.isOptional }
        
        let baseWeight = baseItems.reduce(0) { $0 + ($1.weightGrams * Double($1.quantity)) }
        let consumableWeight = consumableItems.reduce(0) { $0 + ($1.weightGrams * Double($1.quantity)) }
        let wornWeight = wornItems.reduce(0) { $0 + ($1.weightGrams * Double($1.quantity)) }
        let optionalWeight = optionalItems.reduce(0) { $0 + ($1.weightGrams * Double($1.quantity)) }
        
        let totalWeight = baseWeight + consumableWeight + wornWeight + optionalWeight
        let trailWeight = totalWeight - wornWeight
        let totalCost = allItemsInTrip.reduce(0) { $0 + ($1.priceCAD * Double($1.quantity)) }

        let summaries = Dictionary(grouping: nonOptionalItems.filter { !$0.wornWeight }, by: { model.categoryFor(id: $0.categoryID)! })
            .map { (category, items) -> CategorySummary in
                let catWeight = items.reduce(0) { $0 + ($1.weightGrams * Double($1.quantity)) }
                return CategorySummary(id: category, category: category, weight: catWeight, price: 0)
            }
            .sorted(by: { $0.weight > $1.weight })

        return TripCalculations(allItems: allItemsInTrip, baseWeight: baseWeight, consumableWeight: consumableWeight, wornWeight: wornWeight, optionalWeight: optionalWeight, trailWeight: trailWeight, totalWeight: totalWeight, totalCost: totalCost, summaries: summaries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weight & Cost Summary").font(.headline)
                    Spacer()
                    Picker("Unit", selection: $displayUnit) {
                        ForEach(UnitMassType.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }
                
                weightInfoRow(label: "Base Weight", weight: calculations.baseWeight, infoTitle: "Base Weight", infoMessage: "The weight of your essential gear (non-consumable, non-worn items). This is the core weight of your pack.")
                weightInfoRow(label: "Consumables", weight: calculations.consumableWeight, infoTitle: "Consumable Weight", infoMessage: "The weight of items that will be used up during your trip, like food and fuel.")
                weightInfoRow(label: "Worn Weight", weight: calculations.wornWeight, infoTitle: "Worn Weight", infoMessage: "The weight of items you will be wearing, like your boots and hiking clothes. This is not included in your pack's Trail Weight.")
                weightInfoRow(label: "Optional Weight", weight: calculations.optionalWeight, infoTitle: "Optional Weight", infoMessage: "The weight of items you've marked as optional, like a camp chair or a larger camera.")
                
                Divider()
                
                weightInfoRow(label: "Trail Weight", weight: calculations.trailWeight, infoTitle: "Trail Weight", infoMessage: "The total weight on your back when you start hiking. (Total Weight - Worn Weight)", isBold: true)
                
                HStack {
                    Text("Total Cost").bold()
                    Spacer()
                    Text(calculations.totalCost, format: .currency(code: "CAD"))
                }
            }

            // Chart Section
            if !calculations.summaries.isEmpty {
                Chart(calculations.summaries) { summary in
                    BarMark(
                        x: .value("Weight", model.formattedWeightValue(grams: summary.weight, unit: displayUnit)),
                        y: .value("Category", summary.category.name)
                    )
                    .foregroundStyle(by: .value("Category", summary.category.name))
                }
                .chartXAxisLabel("Weight (\(displayUnit.rawValue))")
                .chartLegend(.hidden)
                .frame(minHeight: 200)
            }
        }
        .alert(item: $alertInfo) { info in
            Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func weightInfoRow(label: String, weight: Double, infoTitle: String, infoMessage: String, isBold: Bool = false) -> some View {
        HStack {
            Text(label).bold(isBold)
            Button {
                self.alertInfo = AlertInfo(title: infoTitle, message: infoMessage)
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            Text(model.formattedWeight(grams: weight, unit: displayUnit))
        }
    }
}
