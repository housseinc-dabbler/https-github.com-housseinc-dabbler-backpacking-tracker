import SwiftUI
import CoreData

struct BackpackListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Backpack.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Backpack.name, ascending: true)],
        animation: .default
    ) private var backpacks: FetchedResults<Backpack>

    var body: some View {
        List {
            ForEach(backpacks) { backpack in
                NavigationLink(destination: BackpackDetailView(backpack: backpack)) {
                    VStack(alignment: .leading) {
                        Text(backpack.name ?? "New Backpack")
                            .font(.headline)
                    }
                }
            }
            .onDelete(perform: deleteBackpacks)
        }
        .navigationTitle("Backpacks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addBackpack) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func addBackpack() {
        withAnimation {
            let newBackpack = Backpack(context: viewContext)
            newBackpack.id = UUID()
            newBackpack.name = "New Backpack"
            
            saveContext()
        }
    }

    private func deleteBackpacks(offsets: IndexSet) {
        withAnimation {
            offsets.map { backpacks[$0] }.forEach(viewContext.delete)
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
