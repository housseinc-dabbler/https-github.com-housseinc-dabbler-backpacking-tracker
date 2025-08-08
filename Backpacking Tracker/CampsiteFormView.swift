// CampsiteFormView.swift
import SwiftUI
import CoreData
import MapKit

struct CampsiteFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    private var campsiteToEdit: Campsite?
    
    @State private var name: String
    @State private var latitude: Double
    @State private var longitude: Double
    @State private var permitRequired: Bool
    @State private var visited: Bool
    @State private var needsInvestigation: Bool
    @State private var accessNotes: String
    @State private var linkedHikeName: String
    @State private var photoData: Data?
    @State private var mapLink: String
    @State private var tags: [String]
    
    private var isNew: Bool { campsiteToEdit == nil }
    
    private var hasValidCoordinates: Bool {
        latitude != 0.0 && longitude != 0.0 &&
        CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }

    // Initializer for editing an existing campsite
    init(campsite: Campsite?) {
        self.campsiteToEdit = campsite
        _name = State(initialValue: campsite?.wrappedName ?? "")
        _latitude = State(initialValue: campsite?.latitude ?? 0.0)
        _longitude = State(initialValue: campsite?.longitude ?? 0.0)
        _permitRequired = State(initialValue: campsite?.permitRequired ?? false)
        _visited = State(initialValue: campsite?.visited ?? false)
        _needsInvestigation = State(initialValue: campsite?.needsInvestigation ?? false)
        _accessNotes = State(initialValue: campsite?.wrappedAccessNotes ?? "")
        _linkedHikeName = State(initialValue: campsite?.wrappedLinkedHikeName ?? "")
        _photoData = State(initialValue: campsite?.photo)
        _mapLink = State(initialValue: campsite?.wrappedMapLink ?? "")
        _tags = State(initialValue: campsite?.tagsArray ?? [])
    }
    
    // Initializer for adding a new campsite with pre-filled coordinates
    init(coordinate: CLLocationCoordinate2D) {
        self.campsiteToEdit = nil
        _name = State(initialValue: "")
        _latitude = State(initialValue: coordinate.latitude)
        _longitude = State(initialValue: coordinate.longitude)
        _permitRequired = State(initialValue: false)
        _visited = State(initialValue: false)
        _needsInvestigation = State(initialValue: false)
        _accessNotes = State(initialValue: "")
        _linkedHikeName = State(initialValue: "")
        _photoData = State(initialValue: nil)
        _mapLink = State(initialValue: "")
        _tags = State(initialValue: [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Campsite Name", text: $name)
                    Toggle("Permit Required", isOn: $permitRequired)
                    Toggle("Visited", isOn: $visited)
                    Toggle("Investigate Later", isOn: $needsInvestigation)
                }
                
                Section("Campsite Attributes & Tags") {
                    TagInputView(tags: $tags)
                }
                
                Section("Location") {
                    TextField("Paste FULL map link from url", text: $mapLink)
                        .keyboardType(.URL).autocapitalization(.none)
                        .onChange(of: mapLink) { parseCoordinates(from: mapLink) }
                    TextField("Latitude", value: $latitude, format: .number).keyboardType(.decimalPad)
                    TextField("Longitude", value: $longitude, format: .number).keyboardType(.decimalPad)
                    
                    if hasValidCoordinates {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker(name.isEmpty ? "Campsite" : name, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        }
                        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 12)).listRowInsets(EdgeInsets())
                    }
                }
                
                Section("Photo") { PhotoPicker(imageData: $photoData) }
                
                Section("Notes") {
                    TextField("Linked Hike (optional)", text: $linkedHikeName)
                    TextEditor(text: $accessNotes).frame(minHeight: 100)
                }
            }
            .navigationTitle(isNew ? "New Campsite" : "Edit Campsite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCampsite()
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveCampsite() {
        let campsiteToSave = campsiteToEdit ?? Campsite(context: viewContext)
        campsiteToSave.name = name
        campsiteToSave.latitude = latitude
        campsiteToSave.longitude = longitude
        campsiteToSave.permitRequired = permitRequired
        campsiteToSave.visited = visited
        campsiteToSave.needsInvestigation = needsInvestigation
        campsiteToSave.tagsArray = tags
        campsiteToSave.accessNotes = accessNotes
        campsiteToSave.linkedHikeName = linkedHikeName
        campsiteToSave.photo = photoData
        campsiteToSave.mapLink = mapLink
        
        do { try viewContext.save() }
        catch { let nsError = error as NSError; fatalError("Unresolved error \(nsError), \(nsError.userInfo)") }
    }
    
    private func parseCoordinates(from urlString: String) {
        if let coords = parseStandardLink(urlString) {
            updateCoordinates(with: coords, source: "Standard Link")
            return
        }
        if urlString.contains("goo.gl") || urlString.contains("maps.app.goo.gl") {
            resolveShortenedURLAndParse(from: urlString)
        } else {
            print("⚠️ Could not parse coordinates. Link format not recognized.")
        }
    }
    private func resolveShortenedURLAndParse(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { _, response, error in
            guard let finalURLString = response?.url?.absoluteString, error == nil else {
                return
            }
            DispatchQueue.main.async {
                if let coords = self.parseStandardLink(finalURLString) {
                    self.updateCoordinates(with: coords, source: "Resolved Short Link")
                }
            }
        }
        task.resume()
    }
    
    private func parseStandardLink(_ urlString: String) -> CLLocationCoordinate2D? {
        if let url = URL(string: urlString), let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItem = components.queryItems?.first(where: { $0.name == "ll" }), let value = queryItem.value {
            let parts = value.split(separator: ",").compactMap { Double($0) }
            if parts.count == 2, let lat = parts.first, let lon = parts.last {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        if let range = urlString.range(of: "@[\\d.-]+,[\\d.-]+", options: .regularExpression) {
            let parts = urlString[range].dropFirst().split(separator: ",").compactMap { Double($0) }
            if parts.count >= 2, let lat = parts.first, let lon = parts.last {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        do {
            let regex = try NSRegularExpression(pattern: "!3d(-?\\d+\\.\\d+)!4d(-?\\d+\\.\\d+)")
            if let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) {
                if let latRange = Range(match.range(at: 1), in: urlString),
                   let lonRange = Range(match.range(at: 2), in: urlString),
                   let lat = Double(urlString[latRange]),
                   let lon = Double(urlString[lonRange]) {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
            }
        } catch { print("Regex error: \(error)") }
        
        // This is the line that was missing, causing the error.
        return nil
    }
    
    private func updateCoordinates(with coords: CLLocationCoordinate2D, source: String) {
        self.latitude = coords.latitude
        self.longitude = coords.longitude
    }
}

// All helper views are included below.
private struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    private let suggestedTags = [
        "Backcountry", "Frontcountry / Car Camping", "Crown Land", "Private Campground", "Dispersed", "Established Campground",
        "Walk-in", "Hike-in", "Paddle-in", "Drive-in",
        "Reservation Required", "FCFS", "Bear Box Available", "Pit Toilets", "Flush Toilets",
        "Water Access", "Fire Pit", "Shelter / Lean-to", "Tent Pad"
    ]

    var body: some View {
        VStack(alignment: .leading) {
            if !tags.isEmpty {
                TagCloudView(tags: tags) { tagToRemove in
                    tags.removeAll { $0 == tagToRemove }
                }
            }
            
            HStack {
                TextField("Add custom tag (e.g., 'Requires 4x4')", text: $newTag)
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newTag.isEmpty)
            }
            
            Divider().padding(.vertical, 4)
            
            Text("Suggestions").font(.caption).foregroundStyle(.secondary)
            TagCloudView(tags: suggestedTags.filter { !tags.contains($0) }) { tagToAdd in
                tags.append(tagToAdd)
            }
        }
    }

    private func addTag() {
        guard !newTag.isEmpty, !tags.contains(newTag) else { return }
        tags.append(newTag.trimmingCharacters(in: .whitespaces))
        newTag = ""
    }
}

private struct TagCloudView: View {
    let tags: [String]
    let onTagTapped: (String) -> Void
    
    @State private var totalHeight = CGFloat.zero

    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(self.tags, id: \.self) { tag in
                    self.item(for: tag)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if tag == self.tags.last! {
                                width = 0
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { d in
                            let result = height
                            if tag == self.tags.last! {
                                height = 0
                            }
                            return result
                        })
                }
            }.background(viewHeightReader($totalHeight))
        }
        .frame(height: totalHeight)
    }

    private func item(for text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(Color.accentColor.opacity(0.2))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
            .onTapGesture {
                onTagTapped(text)
            }
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}
