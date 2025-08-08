// CSVMappingView.swift
import SwiftUI

struct CSVMappingView: View {
    @EnvironmentObject var model: GearViewModel
    @Environment(\.dismiss) var dismiss
    
    let parseResult: CSVParseResult
    @State private var mappings: [ColumnMapping]
    
    // State for the debug alert
    @State private var showingDebugAlert = false
    @State private var debugMessage = ""
    
    init(parseResult: CSVParseResult) {
        self.parseResult = parseResult
        self._mappings = State(initialValue: CSVParserService.mapHeaders(parseResult.headers))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Confirm Column Mappings")) {
                    ForEach($mappings) { $mapping in
                        HStack {
                            Text(mapping.csvHeader).bold()
                            Spacer()
                            Picker("Map to", selection: $mapping.mappedTo) {
                                ForEach(GearFieldType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                Section(header: Text("Data Preview (First 3 Rows)")) {
                    ForEach(0..<min(3, parseResult.rows.count), id: \.self) { rowIndex in
                        VStack(alignment: .leading) {
                            ForEach(0..<parseResult.headers.count, id: \.self) { colIndex in
                                if colIndex < parseResult.rows[rowIndex].count {
                                    let value = parseResult.rows[rowIndex][colIndex]
                                    if mappings[colIndex].mappedTo != .ignore {
                                        Text("\(mappings[colIndex].mappedTo.rawValue): \(value)")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import \(parseResult.rows.count) Items") {
                        processImport()
                        showingDebugAlert = true
                    }
                }
            }
            .alert("Import Summary", isPresented: $showingDebugAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(debugMessage)
            }
        }
    }
    
    private func processImport() {
        var potentialNewItems: [GearItem] = []
        var newCategoriesCreated: [String] = []
        
        for row in parseResult.rows {
            var newItemCategoryID: UUID?
            var newItem = GearItem(name: "", categoryID: UUID(), weightGrams: 0, priceCAD: 0, wornWeight: false, consumable: false, favorite: false, description: "", notes: "", tags: [], productURLString: "", imageData: nil)
            
            for (index, mapping) in mappings.enumerated() {
                guard index < row.count else { continue }
                let value = row[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch mapping.mappedTo {
                case .name:
                    newItem.name = value
                case .weight:
                    if let weightValue = Double(value.components(separatedBy: " ")[0]) {
                        if value.lowercased().contains("oz") { newItem.weightGrams = Measurement(value: weightValue, unit: UnitMass.ounces).converted(to: .grams).value }
                        else if value.lowercased().contains("kg") { newItem.weightGrams = Measurement(value: weightValue, unit: UnitMass.kilograms).converted(to: .grams).value }
                        else if value.lowercased().contains("lbs") { newItem.weightGrams = Measurement(value: weightValue, unit: UnitMass.pounds).converted(to: .grams).value }
                        else { newItem.weightGrams = weightValue }
                    }
                case .price:
                    newItem.priceCAD = Double(value) ?? 0.0
                case .quantity:
                    newItem.quantity = Int(value) ?? 1
                case .consumable:
                    newItem.consumable = Bool(value.lowercased()) ?? (value == "1")
                case .worn:
                    newItem.wornWeight = Bool(value.lowercased()) ?? (value == "1")
                case .notes:
                    newItem.notes = value
                case .link:
                    newItem.productURLString = value
                case .category:
                    if let existingCategory = model.categories.first(where: { $0.name.lowercased() == value.lowercased() }) {
                        newItemCategoryID = existingCategory.id
                    } else if !value.isEmpty {
                        let newCategory = GearCategory(name: value, iconName: suggestedIcon(forCategoryName: value), colorName: "gray")
                        model.addCategory(newCategory)
                        newItemCategoryID = newCategory.id
                        if !newCategoriesCreated.contains(value) { newCategoriesCreated.append(value) }
                    }
                case .ignore:
                    continue
                }
            }
            
            newItem.categoryID = newItemCategoryID ?? suggestedCategoryID(forName: newItem.name)
            
            if !newItem.name.isEmpty {
                potentialNewItems.append(newItem)
            }
        }
        
        // --- START: NEW DE-DUPLICATION LOGIC ---
        var finalItemsToImport: [GearItem] = []
        var skippedDuplicateCount = 0
        
        for potentialItem in potentialNewItems {
            // Check if an item with the same name and weight already exists in the main gear list.
            let isDuplicate = model.allItems.contains { existingItem in
                return existingItem.name.trimmingCharacters(in: .whitespaces).lowercased() == potentialItem.name.trimmingCharacters(in: .whitespaces).lowercased() &&
                       existingItem.weightGrams == potentialItem.weightGrams
            }
            
            if !isDuplicate {
                finalItemsToImport.append(potentialItem)
            } else {
                skippedDuplicateCount += 1
            }
        }
        
        model.importGear(from: finalItemsToImport)
        // --- END: NEW DE-DUPLICATION LOGIC ---
        
        
        // Build the summary message for the alert
        var summary = "Import process finished.\n"
        summary += "Processed \(parseResult.rows.count) rows.\n"
        summary += "Created \(finalItemsToImport.count) new gear items.\n"
        
        if skippedDuplicateCount > 0 {
            summary += "Skipped \(skippedDuplicateCount) duplicate items that already exist in your gear list.\n"
        }
        
        if newCategoriesCreated.isEmpty {
            summary += "No new categories were created."
        } else {
            summary += "Created \(newCategoriesCreated.count) new categories: \(newCategoriesCreated.joined(separator: ", "))."
        }
        self.debugMessage = summary
    }
    
    private func suggestedCategoryID(forName name: String) -> UUID {
        let name = name.lowercased()
        if let category = model.categories.first(where: { cat in name.contains(cat.name.lowercased()) && !cat.name.isEmpty }) {
             return category.id
        }
        if name.contains("tent") || name.contains("shelter") { return model.categories.first(where: { $0.name == "Shelter" })?.id ?? UUID() }
        if name.contains("pack") { return model.categories.first(where: { $0.name == "Packs" })?.id ?? UUID() }
        if name.contains("sleep") || name.contains("quilt") || name.contains("pad") { return model.categories.first(where: { $0.name == "Sleep System" })?.id ?? UUID() }
        if name.contains("cook") || name.contains("stove") || name.contains("pot") { return model.categories.first(where: { $0.name == "Cooking & Water" })?.id ?? UUID() }
        
        return model.categories.first(where: { $0.name == "Other" })?.id ?? UUID()
    }

    private func suggestedIcon(forCategoryName name: String) -> String {
        let name = name.lowercased()
        let iconMapping: [String: String] = [
            "pack": "backpack.fill", "shelter": "tent.fill", "tent": "tent.fill", "tarp": "tent.fill", "sleep": "bed.double.fill", "quilt": "bed.double.fill", "bag": "bed.double.fill", "cook": "stove.fill", "stove": "stove.fill", "water": "drop.fill", "cloth": "tshirt.fill", "jacket": "tshirt.fill", "shirt": "tshirt.fill", "pant": "tshirt.fill", "foot": "shoe.fill", "shoe": "shoe.fill", "boot": "shoe.fill", "sock": "shoe.fill", "electronic": "macmini.fill", "nav": "map.fill", "map": "map.fill", "compass": "safari.fill", "first aid": "cross.case.fill", "safety": "exclamationmark.triangle.fill", "hygiene": "hand.sparkles.fill", "tool": "wrench.and.screwdriver.fill", "repair": "wrench.and.screwdriver.fill", "camera": "camera.fill", "photo": "camera.fill", "personal": "person.fill", "food": "fork.knife"
        ]
        
        for (keyword, icon) in iconMapping {
            if name.contains(keyword) {
                return icon
            }
        }
        
        return "questionmark.diamond.fill"
    }
}
