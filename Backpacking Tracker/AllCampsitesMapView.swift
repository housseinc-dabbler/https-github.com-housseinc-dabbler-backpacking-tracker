// AllCampsitesMapView.swift
import SwiftUI
import MapKit

// An enum to manage which sheet (add or edit) should be shown.
enum CampsiteSheet: Identifiable {
    case add(CLLocationCoordinate2D)
    case edit(Campsite)

    var id: String {
        switch self {
        case .add(let coord): return "add-\(coord.latitude)-\(coord.longitude)"
        case .edit(let campsite): return "edit-\(campsite.objectID.uriRepresentation().absoluteString)"
        }
    }
}

// A custom, Hashable & Identifiable enum to represent map styles.
enum CustomMapStyle: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case hybrid = "Hybrid"
    case satellite = "Satellite"
    
    var id: String { self.rawValue }
    
    var mapKitStyle: MapStyle {
        switch self {
        case .standard: return .standard
        case .hybrid: return .hybrid
        case .satellite: return .imagery
        }
    }
}

struct AllCampsitesMapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Campsite.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Campsite.name, ascending: true)]
    ) private var allCampsites: FetchedResults<Campsite>
    
    @State private var region: MKCoordinateRegion
    @StateObject private var locationManager = LocationManager()
    
    @State private var mapStyle: CustomMapStyle = .standard
    @State private var sheetType: CampsiteSheet? = nil
    @State private var isLegendExpanded = false
    @State private var activeFilters = Set<String>()
    
    @State private var isAddingCampsite = false
    @State private var showingFilterSheet = false

    private var filteredCampsites: [Campsite] {
        if activeFilters.isEmpty {
            return Array(allCampsites)
        } else {
            return allCampsites.filter { campsite in
                let campsiteTags = Set(campsite.tagsArray)
                return activeFilters.isSubset(of: campsiteTags)
            }
        }
    }
    
    init() {
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.4215, longitude: -75.6972),
            span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: filteredCampsites.filter { $0.latitude != 0 && $0.longitude != 0 }) { campsite in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: campsite.latitude, longitude: campsite.longitude)) {
                    CampsiteMapPin(campsite: campsite)
                        .onTapGesture {
                            if !isAddingCampsite {
                                self.sheetType = .edit(campsite)
                            }
                        }
                }
            }
            .mapStyle(mapStyle.mapKitStyle)
            .ignoresSafeArea()
            .animation(.easeOut, value: region)
            
            if isAddingCampsite {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .padding()
                    .background(.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .allowsHitTesting(false)
                    // THIS IS THE FIX: This frame modifier forces the crosshair to the center,
                    // ignoring the ZStack's .bottom alignment.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    LegendView(isExpanded: $isLegendExpanded)
                    Spacer()
                    if isAddingCampsite {
                        Button(action: addCampsiteAtCenter) {
                            Text("Add Campsite Here")
                                .font(.headline)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .shadow(radius: 10)
                        }
                        .padding(.trailing)
                    }
                }
            }
            .padding(.bottom)
            
        }
        .navigationTitle("All Campsites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isAddingCampsite.toggle() }) {
                    Image(systemName: isAddingCampsite ? "xmark.circle.fill" : "plus")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Map Style", selection: $mapStyle) {
                        ForEach(CustomMapStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.inline)
                    Button("Filter by Tag", systemImage: "tag.fill") {
                        showingFilterSheet = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: centerOnUserLocation) { Image(systemName: "location.fill") }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(activeFilters: $activeFilters)
        }
        .sheet(item: $sheetType) { type in
            switch type {
            case .add(let coordinate):
                CampsiteFormView(coordinate: coordinate)
            case .edit(let campsite):
                CampsiteFormView(campsite: campsite)
            }
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if let newLocation {
                withAnimation {
                    region.center = newLocation.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                }
            }
        }
        .animation(.default, value: isAddingCampsite)
    }
    
    private func centerOnUserLocation() {
        isAddingCampsite = false
        locationManager.requestLocation()
    }
    
    private func addCampsiteAtCenter() {
        self.sheetType = .add(region.center)
        self.isAddingCampsite = false
    }
}

// All helper views and extensions are included below.
private struct FilterSheetView: View {
    @Binding var activeFilters: Set<String>
    @Environment(\.dismiss) var dismiss

    private let filterTags = [
        "Backcountry", "Crown Land", "Dispersed", "Established Campground",
        "FCFS", "Reservation Required", "Bear Box Available", "Water Access", "Fire Pit"
    ]

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tap to toggle filters")) {
                    ForEach(filterTags, id: \.self) { tag in
                        Toggle(tag, isOn: Binding(
                            get: { activeFilters.contains(tag) },
                            set: { isOn in
                                if isOn { activeFilters.insert(tag) }
                                else { activeFilters.remove(tag) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filter Campsites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All", role: .destructive) { activeFilters.removeAll() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CampsiteMapPin: View {
    @ObservedObject var campsite: Campsite
    var body: some View {
        VStack(spacing: 2) {
            Text(campsite.wrappedName)
                .font(.caption).fontWeight(.bold)
                .padding(5).background(.white.opacity(0.8)).clipShape(Capsule())
            
            Image(systemName: campsite.needsInvestigation ? "questionmark.circle.fill" : "tent.circle.fill")
                .font(.title)
                .foregroundStyle(
                    campsite.primaryType.color,
                    Color(campsite.visited ? .systemGray3 : .systemGray6)
                )
                .shadow(radius: 2)
        }
    }
}

private struct LegendView: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Legend").font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { isExpanded.toggle() }
            }
            
            if isExpanded {
                ForEach(PrimaryCampsiteType.allCases) { type in
                    HStack {
                        Image(systemName: "tent.circle.fill")
                            .foregroundStyle(type.color, Color(.systemGray6))
                        Text(type.rawValue)
                    }
                }
                Divider()
                HStack {
                    Image(systemName: "tent.circle.fill")
                        .foregroundStyle(Color.gray, Color(.systemGray3))
                    Text("Visited")
                }
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(Color.orange, Color(.systemGray6))
                    Text("Investigate Later")
                }
            }
        }
        .font(.caption)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude &&
        lhs.center.longitude == rhs.center.longitude &&
        lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
        lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}
