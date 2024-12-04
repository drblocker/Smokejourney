import SwiftUI
import SwiftData

struct ReviewDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var review: Review
    @State private var showEditSheet = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        List {
            Section("Basic Information") {
                LabeledContent("Date", value: dateFormatter.string(from: review.effectiveDate))
                
                if let duration = review.smokingDuration {
                    LabeledContent("Duration", value: formatDuration(duration))
                }
                
                if let environment = review.environment {
                    LabeledContent("Environment", value: environment)
                }
                
                if let pairings = review.pairings {
                    LabeledContent("Pairings", value: pairings)
                }
            }
            
            if let photos = review.photos, !photos.isEmpty {
                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photos.indices, id: \.self) { index in
                                if let image = UIImage(data: photos[index]) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 200, height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            }
            
            if let appearance = review.appearanceRating {
                Section("Appearance") {
                    RatingDetailRow(title: "Wrapper Color Consistency", rating: appearance.wrapperColorConsistency)
                    RatingDetailRow(title: "Surface Texture", rating: appearance.surfaceTexture)
                    RatingDetailRow(title: "Visible Veins", rating: appearance.visibleVeins)
                    RatingDetailRow(title: "Overall Construction", rating: appearance.overallConstruction)
                    if let notes = appearance.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let aroma = review.aromaRating {
                Section("Aroma") {
                    RatingDetailRow(title: "Pre-Light Scent", rating: aroma.preLightScent)
                    RatingDetailRow(title: "Foot Aroma", rating: aroma.footAroma)
                    RatingDetailRow(title: "Cold Draw Notes", rating: aroma.coldDrawNotes)
                    if let notes = aroma.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let construction = review.constructionRating {
                Section("Construction") {
                    RatingDetailRow(title: "Firmness Consistency", rating: construction.firmnessConsistency)
                    RatingDetailRow(title: "Cap Application", rating: construction.capApplication)
                    RatingDetailRow(title: "Wrapper Integrity", rating: construction.wrapperIntegrity)
                    RatingDetailRow(title: "Visible Defects", rating: construction.visibleDefects)
                    if let notes = construction.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let draw = review.drawRating {
                Section("Draw") {
                    RatingDetailRow(title: "Resistance Level", rating: draw.resistanceLevel)
                    RatingDetailRow(title: "Smoke Production", rating: draw.smokeProduction)
                    RatingDetailRow(title: "Draw Consistency", rating: draw.drawConsistency)
                    if let notes = draw.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let flavor = review.flavorRating {
                Section("Flavor") {
                    RatingDetailRow(title: "Complexity", rating: flavor.complexity)
                    RatingDetailRow(title: "Flavor Transitions", rating: flavor.flavorTransitions)
                    RatingDetailRow(title: "Flavor Intensity", rating: flavor.flavorIntensity)
                    if !flavor.tasteNotes.isEmpty {
                        Text("Taste Notes: \(flavor.tasteNotes.joined(separator: ", "))")
                            .font(.caption)
                    }
                    if let notes = flavor.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let burn = review.burnRating {
                Section("Burn") {
                    RatingDetailRow(title: "Burn Line Evenness", rating: burn.burnLineEvenness)
                    RatingDetailRow(title: "Touch-ups Needed", rating: burn.touchUpsNeeded)
                    RatingDetailRow(title: "Tunneling", rating: burn.tunneling)
                    RatingDetailRow(title: "Burn Rate", rating: burn.burnRate)
                    if let notes = burn.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let ash = review.ashRating {
                Section("Ash") {
                    RatingDetailRow(title: "Color", rating: ash.color)
                    RatingDetailRow(title: "Firmness", rating: ash.firmness)
                    RatingDetailRow(title: "Stack Consistency", rating: ash.stackConsistency)
                    RatingDetailRow(title: "Hold Length", rating: ash.holdLength)
                    if let notes = ash.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let strength = review.strengthRating {
                Section("Strength") {
                    RatingDetailRow(title: "Body", rating: strength.body)
                    RatingDetailRow(title: "Nicotine Impact", rating: strength.nicotineImpact)
                    RatingDetailRow(title: "Progression", rating: strength.progression)
                    if let notes = strength.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let consistency = review.consistencyRating {
                Section("Consistency") {
                    RatingDetailRow(title: "Flavor Stability", rating: consistency.flavorStability)
                    RatingDetailRow(title: "Draw Maintenance", rating: consistency.drawMaintenance)
                    RatingDetailRow(title: "Performance Reliability", rating: consistency.performanceReliability)
                    if let notes = consistency.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let finish = review.finishRating {
                Section("Finish") {
                    RatingDetailRow(title: "Aftertaste Quality", rating: finish.aftertasteQuality)
                    RatingDetailRow(title: "Flavor Evolution", rating: finish.flavorEvolution)
                    RatingDetailRow(title: "Finish Length", rating: finish.finishLength)
                    if let notes = finish.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let overall = review.overallRating {
                Section("Overall") {
                    RatingDetailRow(title: "Value for Money", rating: overall.valueForMoney)
                    RatingDetailRow(title: "Enjoyment Level", rating: overall.enjoymentLevel)
                    RatingDetailRow(title: "Would Smoke Again", rating: overall.wouldSmokeAgain)
                    RatingDetailRow(title: "Recommendation Level", rating: overall.recommendationLevel)
                    if let notes = overall.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let notes = review.notes {
                Section("General Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Review Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditReviewView(review: review)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

struct RatingDetailRow: View {
    let title: String
    let rating: Int
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .foregroundColor(value <= rating ? .yellow : .gray)
                }
            }
        }
    }
} 