import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var humidors: [Humidor]
    @Query private var cigars: [Cigar]
    @Query private var reviews: [Review]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Collection Overview") {
                    StatCard(title: "Total Humidors", value: "\(humidors.count)")
                    StatCard(title: "Total Cigars", value: "\(cigars.count)")
                    StatCard(title: "Total Reviews", value: "\(reviews.count)")
                }
                
                if !reviews.isEmpty {
                    Section("Ratings Distribution") {
                        Chart(reviews) { review in
                            BarMark(
                                x: .value("Rating", review.averageRating),
                                y: .value("Count", 1)
                            )
                        }
                        .frame(height: 200)
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
} 