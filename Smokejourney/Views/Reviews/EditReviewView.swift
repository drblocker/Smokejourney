import SwiftUI
import SwiftData
import PhotosUI

struct EditReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var review: Review
    
    @State private var date: Date
    @State private var smokingDuration: TimeInterval
    @State private var isPrivate: Bool
    @State private var notes: String
    @State private var environment: String
    @State private var pairings: String
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage]
    
    // Rating States
    @State private var appearanceRating: AppearanceRating
    @State private var aromaRating: AromaRating
    @State private var constructionRating: ConstructionRating
    @State private var drawRating: DrawRating
    @State private var flavorRating: FlavorRating
    @State private var burnRating: BurnRating
    @State private var ashRating: AshRating
    @State private var strengthRating: StrengthRating
    @State private var consistencyRating: ConsistencyRating
    @State private var finishRating: FinishRating
    @State private var overallRating: OverallRating
    
    init(review: Review) {
        self.review = review
        _date = State(initialValue: review.effectiveDate)
        _smokingDuration = State(initialValue: review.smokingDuration ?? 3600)
        _isPrivate = State(initialValue: review.effectiveIsPrivate)
        _notes = State(initialValue: review.notes ?? "")
        _environment = State(initialValue: review.environment ?? "")
        _pairings = State(initialValue: review.pairings ?? "")
        _photos = State(initialValue: review.photos?.compactMap { UIImage(data: $0) } ?? [])
        
        // Initialize rating states with existing values or defaults
        _appearanceRating = State(initialValue: review.appearanceRating ?? AppearanceRating(
            wrapperColorConsistency: 3,
            surfaceTexture: 3,
            visibleVeins: 3,
            overallConstruction: 3,
            notes: ""
        ))
        
        _aromaRating = State(initialValue: review.aromaRating ?? AromaRating(
            preLightScent: 3,
            footAroma: 3,
            coldDrawNotes: 3,
            notes: ""
        ))
        
        _constructionRating = State(initialValue: review.constructionRating ?? ConstructionRating(
            firmnessConsistency: 3,
            capApplication: 3,
            wrapperIntegrity: 3,
            visibleDefects: 3,
            notes: ""
        ))
        
        _drawRating = State(initialValue: review.drawRating ?? DrawRating(
            resistanceLevel: 3,
            smokeProduction: 3,
            drawConsistency: 3,
            notes: ""
        ))
        
        _flavorRating = State(initialValue: review.flavorRating ?? FlavorRating(
            complexity: 3,
            flavorTransitions: 3,
            flavorIntensity: 3,
            tasteNotes: [],
            notes: ""
        ))
        
        _burnRating = State(initialValue: review.burnRating ?? BurnRating(
            burnLineEvenness: 3,
            touchUpsNeeded: 3,
            tunneling: 3,
            burnRate: 3,
            notes: ""
        ))
        
        _ashRating = State(initialValue: review.ashRating ?? AshRating(
            color: 3,
            firmness: 3,
            stackConsistency: 3,
            holdLength: 3,
            notes: ""
        ))
        
        _strengthRating = State(initialValue: review.strengthRating ?? StrengthRating(
            body: 3,
            nicotineImpact: 3,
            progression: 3,
            notes: ""
        ))
        
        _consistencyRating = State(initialValue: review.consistencyRating ?? ConsistencyRating(
            flavorStability: 3,
            drawMaintenance: 3,
            performanceReliability: 3,
            notes: ""
        ))
        
        _finishRating = State(initialValue: review.finishRating ?? FinishRating(
            aftertasteQuality: 3,
            flavorEvolution: 3,
            finishLength: 3,
            notes: ""
        ))
        
        _overallRating = State(initialValue: review.overallRating ?? OverallRating(
            valueForMoney: 3,
            enjoymentLevel: 3,
            wouldSmokeAgain: 3,
            recommendationLevel: 3,
            notes: ""
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(smokingDuration))
                    }
                    
                    Toggle("Private Review", isOn: $isPrivate)
                    
                    TextField("Environment", text: $environment, prompt: Text("Where did you smoke this cigar?"))
                    TextField("Pairings", text: $pairings, prompt: Text("What did you pair with this cigar?"))
                }
                
                Section("Appearance") {
                    RatingRow(title: "Wrapper Color Consistency", rating: $appearanceRating.wrapperColorConsistency)
                    RatingRow(title: "Surface Texture", rating: $appearanceRating.surfaceTexture)
                    RatingRow(title: "Visible Veins", rating: $appearanceRating.visibleVeins)
                    RatingRow(title: "Overall Construction", rating: $appearanceRating.overallConstruction)
                    TextField("Notes", text: Binding(
                        get: { appearanceRating.notes ?? "" },
                        set: { appearanceRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                // Continue with similar sections for other rating categories...
                
                Section("Photos") {
                    if !photos.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(photos.indices, id: \.self) { index in
                                    Image(uiImage: photos[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    Button(action: { showPhotoOptions = true }) {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }
                }
                
                Section("General Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Edit Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            // Photo handling sheets and dialogs remain the same as AddReviewView
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func saveChanges() {
        review.date = date
        review.smokingDuration = smokingDuration
        review.isPrivate = isPrivate
        review.notes = notes
        review.environment = environment
        review.pairings = pairings
        review.photos = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        // Update all ratings
        review.appearanceRating = appearanceRating
        review.aromaRating = aromaRating
        review.constructionRating = constructionRating
        review.drawRating = drawRating
        review.flavorRating = flavorRating
        review.burnRating = burnRating
        review.ashRating = ashRating
        review.strengthRating = strengthRating
        review.consistencyRating = consistencyRating
        review.finishRating = finishRating
        review.overallRating = overallRating
        
        dismiss()
    }
} 