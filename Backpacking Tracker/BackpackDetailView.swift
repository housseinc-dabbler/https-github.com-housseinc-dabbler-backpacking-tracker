// BackpackDetailView.swift
import SwiftUI

struct BackpackDetailView: View {
    @EnvironmentObject var model: GearViewModel
    @Binding var backpack: Backpack // RENAMED
    
    enum ViewMode { case analytics, packingList }
    @State private var viewMode: ViewMode = .analytics

    var body: some View {
        Form {
            Section {
                TextField("Backpack Name", text: $backpack.name)
                TextField("Description", text: $backpack.description, axis: .vertical)
            }
            
            Picker("View Mode", selection: $viewMode) {
                Text("Analytics").tag(ViewMode.analytics)
                Text("Packing List").tag(ViewMode.packingList)
            }
            .pickerStyle(.segmented)

            if viewMode == .analytics {
                TripAnalyticsSection(backpack: $backpack) // RENAMED
            } else {
                TripPackingSection(backpack: $backpack) // RENAMED
            }
            
            Section("Food Planner") {
                NavigationLink("Plan Meals & Nutrition") {
                    TripFoodPlannerView(backpack: $backpack) // RENAMED
                }
            }
        }
        .navigationTitle("Edit Backpack")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            model.updateBackpack(backpack)
        }
    }
}


private struct TripAnalyticsSection: View {
    @EnvironmentObject var model: GearViewModel
    @Binding var backpack: Backpack // RENAMED

    var body: some View {
        Section("Stats & Analytics") {
            // NOTE: You will need to update TripAnalyticsView to accept a 'backpack'
            // TripAnalyticsView(trip: backpack)
            Text("Analytics View (Refactor Needed)")
        }
        
        Section("Gear Items (\(backpack.items.count))") {
            NavigationLink("Select & Manage Gear") {
                // NOTE: You will need to update TripItemSelectorView to accept a 'backpack'
                // TripItemSelectorView(trip: $backpack)
                Text("Item Selector View (Refactor Needed)")
            }
        }
    }
}


private struct TripPackingSection: View {
    @Binding var backpack: Backpack // RENAMED
    
    var body: some View {
        Section("Packing Checklist") {
            // NOTE: You will need to update TripPackingView to accept a 'backpack'
            // TripPackingView(trip: $backpack)
            Text("Packing View (Refactor Needed)")
        }
    }
}
