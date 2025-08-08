import SwiftUI
import CoreData

struct CampsiteListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Campsite.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Campsite.name, ascending: true)],
        animation: .default)
    private var campsites: FetchedResults<Campsite>
    
    @State private var campsiteToEdit: Campsite?
    @State private var showingAddSheet = false

    var body: some View {
        List {
            ForEach(campsites) { campsite in
                CampsiteRow(campsite: campsite)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Use the correct initializer for editing
                        campsiteToEdit = campsite
                    }
            }
            .onDelete(perform: deleteCampsites)
        }
        .navigationTitle("Campsite Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AllCampsitesMapView()) {
                    Image(systemName: "map.fill")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            // Use the initializer for a new, blank campsite
            CampsiteFormView(campsite: nil)
        }
        .sheet(item: $campsiteToEdit) { campsite in
            // This correctly shows the form for the selected campsite
            CampsiteFormView(campsite: campsite)
        }
    }

    private func deleteCampsites(offsets: IndexSet) {
        withAnimation {
            offsets.map { campsites[$0] }.forEach(viewContext.delete)
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
}

private struct CampsiteRow: View {
    @ObservedObject var campsite: Campsite
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            Image(systemName: campsite.visited ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(campsite.visited ? .green : .secondary)
                .onTapGesture {
                    campsite.visited.toggle()
                    try? viewContext.save()
                }

            if let imageData = campsite.photo, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading) {
                Text(campsite.wrappedName)
                    .font(.headline)
                
                // This section is now corrected to use the new `primaryType`
                if campsite.primaryType != .other {
                    Text(campsite.primaryType.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(campsite.primaryType.color, in: Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}
