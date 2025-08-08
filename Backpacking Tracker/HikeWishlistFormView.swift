import SwiftUI
import CoreData

struct HikeWishlistFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    private var hike: HikeWishlistItem?
    
    @State private var name: String = ""
    @State private var region: String = ""
    @State private var distance: Double = 0.0
    @State private var elevationGain: Double = 0.0
    @State private var estimatedDuration: Double = 0.0
    @State private var priority: Int16 = 1 // <-- FIX: Default priority is now 1
    @State private var tags: String = ""
    @State private var gpxLink: String = ""
    @State private var notes: String = ""
    
    private var isNew: Bool {
        hike == nil
    }
    
    init(hike: HikeWishlistItem?) {
        self.hike = hike
        
        if let hike = hike {
            _name = State(initialValue: hike.wrappedName)
            _region = State(initialValue: hike.wrappedRegion)
            _distance = State(initialValue: hike.distance)
            _elevationGain = State(initialValue: hike.elevationGain)
            _estimatedDuration = State(initialValue: hike.estimatedDuration)
            _priority = State(initialValue: hike.priority)
            _tags = State(initialValue: hike.tagsArray.joined(separator: ", "))
            _gpxLink = State(initialValue: hike.gpxLink?.absoluteString ?? "")
            _notes = State(initialValue: hike.wrappedNotes)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // ... All form sections remain the same ...
                Section("Primary Details") {
                    TextField("Hike Name", text: $name)
                    TextField("Region (e.g., Kananaskis, Jasper)", text: $region)
                }
                
                Section("Statistics") {
                    HStack {
                        Text("Distance (km)")
                        Spacer()
                        TextField("Distance", value: $distance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Elevation Gain (m)")
                        Spacer()
                        TextField("Elevation", value: $elevationGain, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Est. Duration (hours)")
                        Spacer()
                        TextField("Duration", value: $estimatedDuration, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Planning") {
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(Int16(1))
                        Text("Medium").tag(Int16(2))
                        Text("High").tag(Int16(3))
                        Text("Very High").tag(Int16(4))
                        Text("Must Do!").tag(Int16(5))
                    }
                    .pickerStyle(.menu)
                    
                    TextField("Tags (comma-separated)", text: $tags)
                }
                
                Section("Links & Notes") {
                    TextField("GPX or Web Link", text: $gpxLink)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(isNew ? "New Wishlist Hike" : "Edit Hike")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // For imported GPX files, we need to delete the object if cancelled.
                        if let hike = hike, hike.isInserted {
                            viewContext.delete(hike)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHike()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveHike() {
        let hikeToSave = hike ?? HikeWishlistItem(context: viewContext)
        
        hikeToSave.name = name
        hikeToSave.region = region
        hikeToSave.distance = distance
        hikeToSave.elevationGain = elevationGain
        hikeToSave.estimatedDuration = estimatedDuration
        hikeToSave.priority = priority
        hikeToSave.tagsArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        hikeToSave.gpxLink = URL(string: gpxLink)
        hikeToSave.notes = notes
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}
