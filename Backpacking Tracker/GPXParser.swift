import Foundation
import CoreLocation
import UniformTypeIdentifiers

struct ParsedHike {
    var name: String
    var distance: Double
    var elevation: Double
    var notes: String
    var link: URL?
}

class GPXParser: NSObject, XMLParserDelegate {
    
    private var trackPoints: [CLLocation] = []
    private var currentTrackpointAttributes: [String: String]?
    private var currentElementName: String?
    private var currentElementValue: String = ""
    
    private var hikeName: String?
    private var hikeDesc: String?
    private var hikeLink: URL? // <-- Added property for link

    static func parse(url: URL) -> ParsedHike? {
        guard let parser = XMLParser(contentsOf: url) else { return nil }
        let delegate = GPXParser()
        parser.delegate = delegate
        
        if parser.parse() {
            var name = delegate.hikeName ?? url.deletingPathExtension().lastPathComponent
            if name.lowercased() == "trail planner map" {
                name = url.deletingPathExtension().lastPathComponent
            }
            
            let distance = delegate.calculateDistance()
            let elevation = delegate.calculateElevation()
            let notes = delegate.hikeDesc ?? ""
            let link = delegate.hikeLink // <-- Get the parsed link
            
            return ParsedHike(name: name, distance: distance / 1000.0, elevation: elevation, notes: notes, link: link)
        }
        
        return nil
    }

    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
        currentElementValue = ""
        if elementName == "trkpt" {
            currentTrackpointAttributes = attributeDict
        } else if elementName == "link", let href = attributeDict["href"] { // <-- Added logic to capture the link
            self.hikeLink = URL(string: href)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentElementValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let value = currentElementValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if elementName == "ele" {
            if let latString = currentTrackpointAttributes?["lat"],
               let lonString = currentTrackpointAttributes?["lon"],
               let lat = Double(latString),
               let lon = Double(lonString),
               let ele = Double(value) {
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let location = CLLocation(coordinate: coordinate, altitude: ele, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
                trackPoints.append(location)
            }
        } else if elementName == "name" {
            if hikeName == nil || currentElementName == "trk" {
                 hikeName = value
            }
        } else if elementName == "desc" {
            hikeDesc = value
        }
        
        currentElementName = nil
        if elementName == "trkpt" {
            currentTrackpointAttributes = nil
        }
    }

    // MARK: - Calculation Logic
    
    private func calculateDistance() -> CLLocationDistance {
        guard trackPoints.count > 1 else { return 0.0 }
        var totalDistance: CLLocationDistance = 0
        for i in 0..<(trackPoints.count - 1) {
            totalDistance += trackPoints[i].distance(from: trackPoints[i+1])
        }
        return totalDistance
    }
    
    private func calculateElevation() -> Double {
        guard trackPoints.count > 1 else { return 0.0 }
        var totalGain: Double = 0
        for i in 0..<(trackPoints.count - 1) {
            let gain = trackPoints[i+1].altitude - trackPoints[i].altitude
            if gain > 0 {
                totalGain += gain
            }
        }
        return totalGain
    }
}

extension UTType {
    static var gpx: UTType {
        UTType(importedAs: "com.topografix.gpx")
    }
}
