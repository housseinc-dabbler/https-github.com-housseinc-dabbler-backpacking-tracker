import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct HikeWishlistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: HikeWishlistItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \HikeWishlistItem.name, ascending: true)],
        animation: .default)
    private var allHikes: FetchedResults<HikeWishlistItem>

    @State private var sortDescriptors = [NSSortDescriptor(keyPath: \HikeWishlistItem.name, ascending: true)]
    @State private var selectedRegion: String? = nil
    @State private var searchText = ""
    @State private var showingAddHikeSheet = false
    @State private var showingQuickAddSheet = false
    @State private var showingFileImporter = false
    @State private var hikeToEdit: HikeWishlistItem?

    private var filteredAndSortedHikes: [HikeWishlistItem] {
        let request = HikeWishlistItem.fetchRequest()
        
        var predicates: [NSPredicate] = []
        if let region = selectedRegion {
            predicates.append(NSPredicate(format: "region == %@", region))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[c] %@ OR ANY tags CONTAINS[c] %@", searchText, searchText))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = sortDescriptors
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch hikes: \(error)")
            return []
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredAndSortedHikes) { hike in
                HikeRow(hike: hike)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hikeToEdit = hike
                    }
            }
            .onDelete(perform: deleteHike)
        }
        .navigationTitle("Wishlist Hikes")
        .searchable(text: $searchText, prompt: "Search by name or tag")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu("Sort / Filter", systemImage: "line.3.horizontal.decrease.circle") {
                    Picker("Sort by", selection: $sortDescriptors) {
                        Text("Name (A-Z)").tag([NSSortDescriptor(keyPath: \HikeWishlistItem.name, ascending: true)])
                        Text("Highest Priority").tag([NSSortDescriptor(keyPath: \HikeWishlistItem.priority, ascending: false)])
                        Text("Longest Distance").tag([NSSortDescriptor(keyPath: \HikeWishlistItem.distance, ascending: false)])
                    }
                    .pickerStyle(.inline)
                    
                    if !allRegions.isEmpty {
                         Picker("Filter by Region", selection: $selectedRegion) {
                            Text("All Regions").tag(String?.none)
                            ForEach(allRegions, id: \.self) { region in
                                Text(region).tag(String?.some(region))
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu("Add", systemImage: "plus") {
                    Button("Add Manually", systemImage: "square.and.pencil") {
                        hikeToEdit = nil
                        showingAddHikeSheet = true
                    }
                    Button("Quick Add from Text", systemImage: "doc.text") {
                        showingQuickAddSheet = true
                    }
                    Button("Import GPX File", systemImage: "doc.text.fill") {
                        showingFileImporter = true
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.gpx]) { result in
            handleFileImport(result: result)
        }
        .sheet(isPresented: $showingAddHikeSheet) {
            HikeWishlistFormView(hike: nil)
        }
        .sheet(item: $hikeToEdit) { hike in
            HikeWishlistFormView(hike: hike)
        }
        .sheet(isPresented: $showingQuickAddSheet) {
             QuickAddView()
        }
    }
    
    private var allRegions: [String] {
        Array(Set(allHikes.compactMap { $0.region })).sorted()
    }
    
    private func deleteHike(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let hike = filteredAndSortedHikes[index]
                viewContext.delete(hike)
            }
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let parsedHike = GPXParser.parse(url: url) {
                    let entity = HikeWishlistItem.entity()
                    let newHike = HikeWishlistItem(entity: entity, insertInto: viewContext)
                    
                    newHike.name = parsedHike.name
                    newHike.distance = parsedHike.distance
                    newHike.elevationGain = parsedHike.elevation
                    newHike.notes = parsedHike.notes
                    newHike.gpxLink = parsedHike.link // <-- Assign the parsed link
                    hikeToEdit = newHike
                }
            }
        case .failure(let error):
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Views

private struct HikeRow: View {
    @ObservedObject var hike: HikeWishlistItem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(hike.wrappedName).font(.headline)
            Text(hike.wrappedRegion).font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Label(String(format: "%.1f km", hike.distance), systemImage: "arrow.left.arrow.right")
                Label(String(format: "%.0f m", hike.elevationGain), systemImage: "arrow.up.arrow.down")
                Spacer()
                if hike.priority > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<Int(hike.priority), id: \.self) { _ in
                            Image(systemName: "star.fill")
                        }
                    }
                    .foregroundStyle(.yellow)
                    .font(.caption)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct QuickAddView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter hike details as a comma-separated list:")
                    .font(.headline)
                
                Text("Example: Skyline Trail, Jasper, 44, 1600, 3, alpine, https://example.com/gpx")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("Name, Region, Distance, Elevation, Priority, Tag, URL", text: $inputText, axis: .vertical)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Add Hike") {
                    parseAndAddHike()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Invalid Input", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text("Could not parse input. Please ensure you have at least 3 values: Name, Region, and Distance.")
            }
        }
    }
    
    private func parseAndAddHike() {
        let components = inputText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count >= 3 else {
            showingError = true
            return
        }
        
        let newHike = HikeWishlistItem(context: viewContext)
        newHike.name = String(components[0])
        newHike.region = String(components[1])
        newHike.distance = Double(components[2]) ?? 0.0
        
        if components.count > 3 { newHike.elevationGain = Double(components[3]) ?? 0.0 }
        if components.count > 4 { newHike.priority = Int16(components[4]) ?? 1 }
        if components.count > 5 { newHike.tagsArray = [String(components[5])] }
        if components.count > 6, let url = URL(string: String(components[6])) { newHike.gpxLink = url }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save quick add hike: \(error)")
        }
    }
}
