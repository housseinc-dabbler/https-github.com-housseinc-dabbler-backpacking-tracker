// CSVParserService.swift
import Foundation

// A simple structure to hold the parsed CSV data.
struct CSVParseResult: Identifiable {
    let id = UUID()
    let headers: [String]
    let rows: [[String]]
}

// Represents the mapping from a CSV column to an app data field.
struct ColumnMapping: Identifiable {
    let id = UUID()
    let csvHeader: String
    var mappedTo: GearFieldType = .ignore
}

// An enum of all possible fields a column can be mapped to.
enum GearFieldType: String, CaseIterable, Identifiable {
    case ignore = "Ignore"
    case name = "Name"
    case category = "Category"
    case weight = "Weight"
    case price = "Price"
    case quantity = "Quantity"
    case consumable = "Consumable"
    case worn = "Worn Weight"
    case notes = "Notes"
    case link = "Link"
    
    var id: Self { self }
}

class CSVParserService {
    
    static func parse(url: URL) -> CSVParseResult? {
        guard let content = try? String(contentsOf: url) else { return nil }
        
        var rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard !rows.isEmpty else { return nil }
        
        let headerRow = rows.removeFirst().components(separatedBy: ",")
        let dataRows = rows.map { $0.components(separatedBy: ",") }
        
        return CSVParseResult(headers: headerRow, rows: dataRows)
    }
    
    // This function performs the "intelligent" mapping guess.
    static func mapHeaders(_ headers: [String]) -> [ColumnMapping] {
        return headers.map { header in
            let cleanedHeader = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            var mapping = ColumnMapping(csvHeader: header)
            
            // IMPROVED: Added more common variations to the switch statement.
            switch cleanedHeader {
            case "item", "name", "gear", "item name":
                mapping.mappedTo = .name
            case "category", "cat", "type":
                mapping.mappedTo = .category
            case "weight", "weight (g)", "grams", "g":
                mapping.mappedTo = .weight
            case "weight (oz)", "oz", "ounces":
                mapping.mappedTo = .weight
            case "weight (kg)", "kg", "kilograms":
                mapping.mappedTo = .weight
            case "weight (lbs)", "lbs", "pounds":
                mapping.mappedTo = .weight
            case "price", "cost", "value":
                mapping.mappedTo = .price
            case "qty", "quantity", "count":
                mapping.mappedTo = .quantity
            case "consumable", "food":
                mapping.mappedTo = .consumable
            case "worn", "worn weight":
                mapping.mappedTo = .worn
            case "notes", "description", "desc":
                mapping.mappedTo = .notes
            case "url", "link", "product url":
                mapping.mappedTo = .link
            default:
                mapping.mappedTo = .ignore
            }
            return mapping
        }
    }
}
