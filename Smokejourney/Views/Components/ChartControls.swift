import SwiftUI

struct ChartControls: View {
    @Binding var timeRange: TimeRange
    @Binding var chartType: ChartType
    
    var body: some View {
        HStack {
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Chart Type", selection: $chartType) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    Image(systemName: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
    }
} 