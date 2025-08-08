// IconPicker.swift
import SwiftUI

struct IconPicker: View {
    @Binding var selectedIcon: String
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)
    
    // A comprehensive list of relevant SF Symbols for backpacking
    let icons = [
        "backpack.fill", "tent.fill", "bed.double.fill", "stove.fill",
        "tshirt.fill", "mountain.2.fill", "map.fill", "binoculars.fill",
        "camera.fill", "lightbulb.fill", "battery.100.bolt", "cross.case.fill",
        "fork.knife", "archivebox.fill", "drop.fill", "wind",
        "snow", "sun.max.fill", "moon.fill", "sparkles",
        "wrench.and.screwdriver.fill", "comb.fill", "hand.sparkles.fill", "leaf.fill",
        "macmini.fill", "headphones", "speaker.wave.3.fill", "book.fill",
        "gamecontroller.fill", "scissors", "bandage.fill", "pills.fill",
        "sailboat.fill", "airplane", "car.fill", "bus.fill"
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title)
                            .padding()
                            .background(selectedIcon == icon ? Color.accentColor : Color.clear)
                            .foregroundColor(selectedIcon == icon ? .white : .primary)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Select Icon")
    }
}
