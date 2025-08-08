// Campsite+Extensions.swift
import Foundation
import CoreData
import SwiftUI

// This enum helps determine the primary visual icon for a campsite on the map.
// It checks the tags and picks the most relevant type.
public enum PrimaryCampsiteType: String, CaseIterable, Identifiable {
    case backcountry = "Backcountry"
    case established = "Established"
    case crownLand = "Crown Land"
    case privatePaid = "Private / Paid"
    case dispersed = "Dispersed"
    case other = "Other"
    
    public var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .backcountry: return .purple
        case .established: return .blue
        case .crownLand: return .green
        case .privatePaid: return .orange
        case .dispersed: return .brown
        case .other: return .gray
        }
    }
}


extension Campsite {

    public var wrappedName: String {
        get { name ?? "New Campsite" }
        set { name = newValue }
    }

    public var wrappedAccessNotes: String {
        get { accessNotes ?? "" }
        set { accessNotes = newValue }
    }
    
    public var wrappedLinkedHikeName: String {
        get { linkedHikeName ?? "" }
        set { linkedHikeName = newValue }
    }
    
    public var wrappedMapLink: String {
        get { mapLink ?? "" }
        set { mapLink = newValue }
    }

    // Safely handles the new tags array.
    public var tagsArray: [String] {
        get { (tags as? [String]) ?? [] }
        set { tags = newValue as NSObject }
    }
    
    // Determines the primary type for map visualization based on tags.
    public var primaryType: PrimaryCampsiteType {
        let lowercasedTags = Set(tagsArray.map { $0.lowercased() })
        
        if lowercasedTags.contains("backcountry") { return .backcountry }
        if lowercasedTags.contains("established campground") || lowercasedTags.contains("provincial park") || lowercasedTags.contains("national park") { return .established }
        if lowercasedTags.contains("crown land") { return .crownLand }
        if lowercasedTags.contains("private campground") || lowercasedTags.contains("paid campground") { return .privatePaid }
        if lowercasedTags.contains("dispersed") { return .dispersed }
        
        return .other
    }
}

// NOTE: The old CampsiteType enum is no longer needed and can be deleted from this file if it's there.
