// SettingsView.swift
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var model: GearViewModel
    
    @State private var showingResetAlert = false
    @AppStorage("usdaApiKey") var usdaApiKey = ""
    
    // State for the importer views
    @State private var isShowingFileImporter = false
    @State private var parsedCSV: CSVParseResult?

    var body: some View {
        Form {
            Section("Data Management") {
                Button("Import gear from CSV", systemImage: "square.and.arrow.down") {
                    isShowingFileImporter = true
                }
            }
            
            Section("Customization") {
                NavigationLink("Manage Categories") { CategoryManagementView() }
                NavigationLink("Manage Food Templates") { FoodTemplateListView() }
            }
            
            Section("API Keys") {
                VStack(alignment: .leading) {
                    Text("USDA FoodData Central API Key").font(.headline)
                    SecureField("Paste your API key here", text: $usdaApiKey)
                        .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                        .background(Color(.systemGray6)).cornerRadius(8)
                    Text("Get a free key from [api.data.gov](https://api.data.gov) to enable the food search feature.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            
            Section("Units") {
                 Picker("Default Distance Unit", selection: $model.distanceUnit) {
                    ForEach(UnitLengthType.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            
            Section("App Reset") {
                Button("Reset to Defaults", role: .destructive) {
                    showingResetAlert = true
                }
            }
            
            Section("About") {
                Text("App Version 1.0.0").foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $isShowingFileImporter, allowedContentTypes: [.commaSeparatedText]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    self.parsedCSV = CSVParserService.parse(url: url)
                }
            case .failure(let error):
                print("Error importing file: \(error.localizedDescription)")
            }
        }
        // CORRECTED: This now injects the main data model into the sheet.
        .sheet(item: $parsedCSV) { result in
            CSVMappingView(parseResult: result)
                .environmentObject(model)
        }
        .alert("Reset Settings?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { model.resetToDefaults() }
        } message: {
            Text("This will reset your default units to kilograms (kg) and meters (m). Your gear and trips will not be affected.")
        }
    }
}
