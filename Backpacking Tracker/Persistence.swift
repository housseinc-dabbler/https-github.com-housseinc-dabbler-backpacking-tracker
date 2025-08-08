import CoreData
import SwiftUI

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    @Published var isDataLoaded: Bool = false

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Backpacking_Tracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            DispatchQueue.main.async {
                self.isDataLoaded = true
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
