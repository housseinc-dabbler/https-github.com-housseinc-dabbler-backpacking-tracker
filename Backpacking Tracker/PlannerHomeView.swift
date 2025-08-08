// PlannerHomeView.swift
import SwiftUI

struct PlannerHomeView: View {
    @StateObject private var persistenceController = PersistenceController.shared

    var body: some View {
        if persistenceController.isDataLoaded {
            NavigationStack {
                List {
                    Section("Planning Tools") {
                        // NEW LINK
                        NavigationLink(destination: TripItineraryListView()) {
                            Label("Trip Itineraries", systemImage: "map.route")
                        }
                        NavigationLink(destination: HikeWishlistView()) {
                            Label("Wishlist Hikes", systemImage: "text.book.closed.fill")
                        }
                        NavigationLink(destination: CampsiteListView()) {
                            Label("Campsite Log", systemImage: "tent.fill")
                        }
                        NavigationLink(destination: FoodLibraryView()) {
                            Label("Food Pantry", systemImage: "fork.knife")
                        }
                    }
                }
                .navigationTitle("Planner")
            }
        } else {
            ProgressView("Initializing Database...")
        }
    }
}
