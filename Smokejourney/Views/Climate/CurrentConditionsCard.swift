import SwiftUI

struct CurrentConditionsCard: View {
    @ObservedObject private(set) var viewModel: ClimateViewModel
    let showTitle: Bool
    
    init(viewModel: ClimateViewModel, showTitle: Bool = true) {
        self.viewModel = viewModel
        self.showTitle = showTitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showTitle {
                Text("Current Conditions")
                    .font(.headline)
                    .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                if let temp = viewModel.averageTemperature {
                    ReadingView(
                        value: String(format: "%.1f°F", temp),
                        title: "Temperature",
                        icon: "thermometer",
                        color: .orange
                    )
                }
                
                if let humidity = viewModel.averageHumidity {
                    ReadingView(
                        value: String(format: "%.1f%%", humidity),
                        title: "Humidity",
                        icon: "humidity",
                        color: .blue
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}