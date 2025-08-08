// GearDetailView.swift
import SwiftUI

struct GearDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var item: GearItem
    @ObservedObject var model: GearViewModel
    let isNew: Bool

    @State private var weightInput: Double = 0.0
    @State private var selectedUnit: UnitMassType
    @State private var duplicatedItem: GearItem?
    @State private var showDuplicatedItemSheet = false

    init(item: GearItem?, model: GearViewModel) {
        self.model = model
        if let item = item {
            _item = State(initialValue: item)
            self.isNew = false
        } else {
            let defaultCatID = model.categories.first?.id ?? UUID()
            _item = State(initialValue: GearItem(
                name: "",
                categoryID: defaultCatID,
                weightGrams: 0,
                priceCAD: 0,
                wornWeight: false,
                consumable: false,
                favorite: false,
                isOptional: false,
                description: "",
                notes: "",
                tags: [],
                productURLString: "",
                imageData: nil
            ))
            self.isNew = true
        }
        
        let initialUnit = model.weightUnit
        _selectedUnit = State(initialValue: initialUnit)
        if let existingItem = item {
             _weightInput = State(initialValue: Measurement(value: existingItem.weightGrams, unit: UnitMass.grams).converted(to: initialUnit.unit).value)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $item.name)
                    Picker("Category", selection: $item.categoryID) {
                        ForEach(model.categories) { Text($0.name).tag($0.id) }
                    }
                    Stepper("Inventory Quantity: \(item.quantity)", value: $item.quantity, in: 1...1000)
                }
                
                Section("Measurements (per item)") {
                    HStack {
                        TextField("Weight", value: $weightInput, format: .number).keyboardType(.decimalPad)
                        Picker("Unit", selection: $selectedUnit) {
                            ForEach(UnitMassType.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.menu)
                    }
                    TextField("Price", value: $item.priceCAD, format: .currency(code: "CAD")).keyboardType(.decimalPad)
                }

                Section("Toggles") {
                    Toggle("Worn", isOn: $item.wornWeight)
                    Toggle("Consumable", isOn: $item.consumable)
                    Toggle("Favorite", isOn: $item.favorite)
                    Toggle("Optional Item", isOn: $item.isOptional) // NEW
                }
                
                Section("Image") {
                    PhotoPicker(imageData: $item.imageData)
                }

                Section("Info") {
                    TextField("Description", text: $item.description)
                    TextField("Notes", text: $item.notes, axis: .vertical)
                    TextField("Tags (comma-separated)", text: Binding(
                        get: { item.tags.joined(separator: ", ") },
                        set: { item.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                    ))
                    TextField("Product URL", text: $item.productURLString)
                }

                if !isNew {
                    Section("Actions") {
                        Button("Duplicate Item", systemImage: "plus.square.on.square") {
                           duplicateItem()
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Gear" : item.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }.disabled(item.name.isEmpty)
                }
            }
            .sheet(isPresented: $showDuplicatedItemSheet) {
                if let duplicatedItem = duplicatedItem {
                    GearDetailView(item: duplicatedItem, model: model)
                }
            }
        }
        .onChange(of: selectedUnit) { oldUnit, newUnit in
            let measurement = Measurement(value: weightInput, unit: oldUnit.unit)
            weightInput = measurement.converted(to: newUnit.unit).value
        }
    }

    private func saveAndDismiss() {
        let measurement = Measurement(value: weightInput, unit: selectedUnit.unit)
        item.weightGrams = measurement.converted(to: .grams).value
        model.updateItem(item)
        dismiss()
    }

    private func duplicateItem() {
        let measurement = Measurement(value: weightInput, unit: selectedUnit.unit)
        item.weightGrams = measurement.converted(to: .grams).value
        model.updateItem(item)
        
        var newVersion = item
        newVersion.id = UUID()
        newVersion.name = item.name + " (Copy)"
        
        model.updateItem(newVersion)
        self.duplicatedItem = newVersion
        self.showDuplicatedItemSheet = true
        
        dismiss()
    }
}
