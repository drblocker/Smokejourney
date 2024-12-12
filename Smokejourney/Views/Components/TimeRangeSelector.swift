import SwiftUI

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
} 