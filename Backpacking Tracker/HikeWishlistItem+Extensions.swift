import Foundation
import CoreData

// This extension adds our helper variables back to the auto-generated class.
extension HikeWishlistItem {
    
    public var wrappedName: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    public var wrappedRegion: String {
        get { region ?? "" }
        set { region = newValue }
    }
    
    public var wrappedNotes: String {
        get { notes ?? "" }
        set { notes = newValue }
    }

    // This property now correctly handles casting for the Transformable 'tags' attribute.
    public var tagsArray: [String] {
        get {
            return (tags as? [String]) ?? []
        }
        set {
            tags = newValue as NSObject
        }
    }
}
