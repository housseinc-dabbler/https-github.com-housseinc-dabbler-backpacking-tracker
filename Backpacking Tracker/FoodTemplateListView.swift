// FoodTemplateListView.swift
import SwiftUI

struct FoodTemplateListView: View {
    @EnvironmentObject var model: GearViewModel
    @State private var newTemplateName = ""
    @State private var showingAlert = false

    var body: some View {
        List {
            Section {
                ForEach(model.foodPlanTemplates.indices, id: \.self) { index in
                    NavigationLink(destination: FoodTemplateDetailView(template: $model.foodPlanTemplates[index])) {
                        VStack(alignment: .leading) {
                            Text(model.foodPlanTemplates[index].name)
                            Text("\(model.foodPlanTemplates[index].items.count) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: model.deleteTemplate)
            } header: {
                Text("My Food Templates")
            }
        }
        .navigationTitle("Food Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New", systemImage: "plus") {
                    showingAlert = true
                }
            }
        }
        .alert("New Template", isPresented: $showingAlert) {
            TextField("Template Name (e.g., '3-Day Solo Meals')", text: $newTemplateName)
            Button("Create") {
                let newTemplate = FoodPlanTemplate(name: newTemplateName, items: [])
                model.updateTemplate(newTemplate)
                newTemplateName = ""
            }
            Button("Cancel", role: .cancel) { newTemplateName = "" }
        }
    }
}
