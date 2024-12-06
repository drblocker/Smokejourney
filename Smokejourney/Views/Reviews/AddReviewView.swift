import SwiftUI
import SwiftData
import PhotosUI

struct AddReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = SmokingSessionManager.shared
    @Bindable var cigar: Cigar
    let smokingDuration: TimeInterval
    var onDismiss: (() -> Void)?
    
    @State private var date = Date()
    @State private var isPrivate = false
    @State private var notes = ""
    @State private var environment = ""
    @State private var pairings = ""
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var photos: [UIImage] = []
    
    // Rating States
    @State private var appearanceRating = AppearanceRating(
        wrapperColorConsistency: 3,
        surfaceTexture: 3,
        visibleVeins: 3,
        overallConstruction: 3,
        notes: ""
    )
    
    @State private var aromaRating = AromaRating(
        preLightScent: 3,
        footAroma: 3,
        coldDrawNotes: 3,
        notes: ""
    )
    
    @State private var constructionRating = ConstructionRating(
        firmnessConsistency: 3,
        capApplication: 3,
        wrapperIntegrity: 3,
        visibleDefects: 3,
        notes: ""
    )
    
    @State private var drawRating = DrawRating(
        resistanceLevel: 3,
        smokeProduction: 3,
        drawConsistency: 3,
        notes: ""
    )
    
    @State private var flavorRating = FlavorRating(
        complexity: 3,
        flavorTransitions: 3,
        flavorIntensity: 3,
        tasteNotes: [],
        notes: ""
    )
    
    @State private var burnRating = BurnRating(
        burnLineEvenness: 3,
        touchUpsNeeded: 3,
        tunneling: 3,
        burnRate: 3,
        notes: ""
    )
    
    @State private var ashRating = AshRating(
        color: 3,
        firmness: 3,
        stackConsistency: 3,
        holdLength: 3,
        notes: ""
    )
    
    @State private var strengthRating = StrengthRating(
        body: 3,
        nicotineImpact: 3,
        progression: 3,
        notes: ""
    )
    
    @State private var consistencyRating = ConsistencyRating(
        flavorStability: 3,
        drawMaintenance: 3,
        performanceReliability: 3,
        notes: ""
    )
    
    @State private var finishRating = FinishRating(
        aftertasteQuality: 3,
        flavorEvolution: 3,
        finishLength: 3,
        notes: ""
    )
    
    @State private var overallRating = OverallRating(
        valueForMoney: 3,
        enjoymentLevel: 3,
        wouldSmokeAgain: 3,
        recommendationLevel: 3,
        notes: ""
    )
    
    // Add state for validation
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    @State private var cutType = ""
    @State private var humidity: String = ""  // Using string for input validation
    
    // Add computed property for validation
    private var isValid: Bool {
        // Basic ratings validation (ensure at least some ratings are provided)
        let hasAppearanceRating = appearanceRating.overallConstruction > 0
        let hasAromaRating = aromaRating.preLightScent > 0
        let hasConstructionRating = constructionRating.firmnessConsistency > 0
        let hasDrawRating = drawRating.resistanceLevel > 0
        let hasFlavorRating = flavorRating.complexity > 0
        let hasBurnRating = burnRating.burnLineEvenness > 0
        
        // Require at least appearance, construction, and flavor ratings
        return hasAppearanceRating && 
               hasConstructionRating && 
               hasFlavorRating
    }
    
    init(cigar: Cigar, smokingDuration: TimeInterval, onDismiss: (() -> Void)? = nil) {
        self.cigar = cigar
        self.smokingDuration = smokingDuration
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Section("Smoking Duration") {
                        Text(formatDuration(TimeInterval(smokingDuration)))
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Cut Type", text: $cutType, prompt: Text("How did you cut this cigar?"))
                    
                    HStack {
                        Text("Humidity")
                        TextField("65", text: $humidity)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
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
                
                Section("Aroma") {
                    RatingRow(title: "Pre-Light Scent", rating: $aromaRating.preLightScent)
                    RatingRow(title: "Foot Aroma", rating: $aromaRating.footAroma)
                    RatingRow(title: "Cold Draw Notes", rating: $aromaRating.coldDrawNotes)
                    TextField("Notes", text: Binding(
                        get: { aromaRating.notes ?? "" },
                        set: { aromaRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Construction") {
                    RatingRow(title: "Firmness Consistency", rating: $constructionRating.firmnessConsistency)
                    RatingRow(title: "Cap Application", rating: $constructionRating.capApplication)
                    RatingRow(title: "Wrapper Integrity", rating: $constructionRating.wrapperIntegrity)
                    RatingRow(title: "Visible Defects", rating: $constructionRating.visibleDefects)
                    TextField("Notes", text: Binding(
                        get: { constructionRating.notes ?? "" },
                        set: { constructionRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Draw") {
                    RatingRow(title: "Resistance Level", rating: $drawRating.resistanceLevel)
                    RatingRow(title: "Smoke Production", rating: $drawRating.smokeProduction)
                    RatingRow(title: "Draw Consistency", rating: $drawRating.drawConsistency)
                    TextField("Notes", text: Binding(
                        get: { drawRating.notes ?? "" },
                        set: { drawRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Flavor") {
                    RatingRow(title: "Complexity", rating: $flavorRating.complexity)
                    RatingRow(title: "Flavor Transitions", rating: $flavorRating.flavorTransitions)
                    RatingRow(title: "Flavor Intensity", rating: $flavorRating.flavorIntensity)
                    TextField("Notes", text: Binding(
                        get: { flavorRating.notes ?? "" },
                        set: { flavorRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Burn") {
                    RatingRow(title: "Burn Line Evenness", rating: $burnRating.burnLineEvenness)
                    RatingRow(title: "Touch-ups Needed", rating: $burnRating.touchUpsNeeded)
                    RatingRow(title: "Tunneling", rating: $burnRating.tunneling)
                    RatingRow(title: "Burn Rate", rating: $burnRating.burnRate)
                    TextField("Notes", text: Binding(
                        get: { burnRating.notes ?? "" },
                        set: { burnRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Ash") {
                    RatingRow(title: "Color", rating: $ashRating.color)
                    RatingRow(title: "Firmness", rating: $ashRating.firmness)
                    RatingRow(title: "Stack Consistency", rating: $ashRating.stackConsistency)
                    RatingRow(title: "Hold Length", rating: $ashRating.holdLength)
                    TextField("Notes", text: Binding(
                        get: { ashRating.notes ?? "" },
                        set: { ashRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Strength") {
                    RatingRow(title: "Body", rating: $strengthRating.body)
                    RatingRow(title: "Nicotine Impact", rating: $strengthRating.nicotineImpact)
                    RatingRow(title: "Progression", rating: $strengthRating.progression)
                    TextField("Notes", text: Binding(
                        get: { strengthRating.notes ?? "" },
                        set: { strengthRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Consistency") {
                    RatingRow(title: "Flavor Stability", rating: $consistencyRating.flavorStability)
                    RatingRow(title: "Draw Maintenance", rating: $consistencyRating.drawMaintenance)
                    RatingRow(title: "Performance Reliability", rating: $consistencyRating.performanceReliability)
                    TextField("Notes", text: Binding(
                        get: { consistencyRating.notes ?? "" },
                        set: { consistencyRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Finish") {
                    RatingRow(title: "Aftertaste Quality", rating: $finishRating.aftertasteQuality)
                    RatingRow(title: "Flavor Evolution", rating: $finishRating.flavorEvolution)
                    RatingRow(title: "Finish Length", rating: $finishRating.finishLength)
                    TextField("Notes", text: Binding(
                        get: { finishRating.notes ?? "" },
                        set: { finishRating.notes = $0 }
                    ), axis: .vertical)
                }
                
                Section("Overall") {
                    RatingRow(title: "Value for Money", rating: $overallRating.valueForMoney)
                    RatingRow(title: "Enjoyment Level", rating: $overallRating.enjoymentLevel)
                    RatingRow(title: "Would Smoke Again", rating: $overallRating.wouldSmokeAgain)
                    RatingRow(title: "Recommendation Level", rating: $overallRating.recommendationLevel)
                    TextField("Notes", text: Binding(
                        get: { overallRating.notes ?? "" },
                        set: { overallRating.notes = $0 }
                    ), axis: .vertical)
                }
                
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
            .navigationTitle("Add Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReview()
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Missing Information", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showPhotoOptions) {
                Button("Take Photo") {
                    photoSource = .camera
                }
                Button("Choose from Library") {
                    photoSource = .photoLibrary
                }
                Button("Cancel", role: .cancel) {
                    photoSource = nil
                }
            }
            .sheet(item: $photoSource) { source in
                switch source {
                case .camera:
                    CameraView(image: Binding(
                        get: { nil },
                        set: { if let image = $0 { photos.append(image) }}
                    ))
                case .photoLibrary:
                    PhotosPicker(selection: $selectedPhotoItems,
                               matching: .images,
                               photoLibrary: .shared()) {
                        Text("Select Photos")
                    }
                }
            }
            .onChange(of: selectedPhotoItems) {
                Task {
                    for item in selectedPhotoItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            photos.append(image)
                        }
                    }
                    selectedPhotoItems.removeAll()
                }
            }
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func saveReview() {
        let review = Review(date: date)
        review.smokingDuration = TimeInterval(smokingDuration)
        review.isPrivate = isPrivate
        review.environment = environment.isEmpty ? nil : environment
        review.pairings = pairings.isEmpty ? nil : pairings
        review.cutType = cutType.isEmpty ? "Guillotine" : cutType
        review.notes = notes.isEmpty ? nil : notes
        
        // Set all the ratings
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
        
        // Convert photos to data
        if !photos.isEmpty {
            review.photos = photos.compactMap { $0.jpegData(compressionQuality: 0.8) }
        }
        
        // Add review to cigar
        review.cigar = cigar
        if cigar.reviews == nil {
            cigar.reviews = []
        }
        cigar.reviews?.append(review)
        
        // Create consumption record
        let consumptionRecord = CigarPurchase(
            quantity: 1,
            price: nil,
            vendor: nil,
            url: nil,
            type: .smoke
        )
        consumptionRecord.cigar = cigar
        consumptionRecord.date = date
        
        // Save to model context
        modelContext.insert(review)
        modelContext.insert(consumptionRecord)
        
        try? modelContext.save()
        
        // Clear session state
        sessionManager.clearLastEndedSession()
        
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

struct RatingRow: View {
    let title: String
    @Binding var rating: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
            HStack {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .foregroundColor(value <= rating ? .yellow : .gray)
                        .onTapGesture {
                            rating = value
                        }
                }
            }
        }
    }
} 