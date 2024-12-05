import SwiftUI
import SwiftData
import PhotosUI
import os.log

struct CigarDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var cigar: Cigar
    
    @State private var isEditing = false
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var wrapperImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showDeleteAlert = false
    @State private var showAddReview = false
    @State private var hasActiveSession = false
    @State private var showGiftSheet = false
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "CigarDetailView")
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Brand", value: cigar.brand ?? "Unknown")
                LabeledContent("Name", value: cigar.name ?? "Unknown")
                LabeledContent("Size", value: cigar.size ?? "Unknown")
                LabeledContent("Wrapper", value: cigar.wrapperType ?? "Unknown")
                LabeledContent("Strength", value: cigar.strength?.rawValue.capitalized ?? "Unknown")
            }
            
            Section("Purchase Information") {
                NavigationLink(destination: PurchaseHistoryView(cigar: cigar)) {
                    VStack(alignment: .leading) {
                        Text("Purchase History")
                        Text("\(cigar.totalQuantity) cigars • \(cigar.purchaseHistory.count) transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if cigar.totalCost > 0 {
                    if let formattedTotal = currencyFormatter.string(from: cigar.totalCost as NSDecimalNumber) {
                        LabeledContent("Total Cost", value: formattedTotal)
                    }
                    if let formattedAvg = currencyFormatter.string(from: cigar.averagePricePerCigar as NSDecimalNumber) {
                        LabeledContent("Average Price per Cigar", value: formattedAvg)
                    }
                }
            }
            
            if let imageData = cigar.wrapperImageData,
               let uiImage = UIImage(data: imageData) {
                Section("Wrapper Photo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }
            }
            
            Section("Actions") {
                if hasActiveSession {
                    NavigationLink(destination: SmokingSessionView(cigar: cigar)) {
                        HStack {
                            Label("Resume Smoking Session", systemImage: "flame.fill")
                                .foregroundColor(.orange)
                            Spacer()
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 10, height: 10)
                                .modifier(PulseAnimation())
                        }
                    }
                } else {
                    NavigationLink(destination: SmokingSessionView(cigar: cigar)) {
                        Label("Start Smoking Session", systemImage: "flame")
                    }
                }
                
                if cigar.totalQuantity > 0 {
                    Button {
                        showGiftSheet = true
                    } label: {
                        Label("Gift Cigar", systemImage: "gift")
                    }
                }
            }
            
            Section("Reviews") {
                Button(action: { showAddReview = true }) {
                    Label("Add Review", systemImage: "star.bubble")
                }
                
                if let reviews = cigar.reviews {
                    ForEach(reviews) { review in
                        NavigationLink(destination: ReviewDetailView(review: review)) {
                            ReviewRowView(review: review)
                        }
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Cigar", systemImage: "trash")
                }
            }
        }
        .navigationTitle("\(cigar.brand ?? "") - \(cigar.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditCigarView(cigar: cigar)
        }
        .alert("Delete Cigar", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCigar()
            }
        } message: {
            Text("Are you sure you want to delete this cigar? This action cannot be undone.")
        }
        .sheet(isPresented: $showAddReview) {
            AddReviewView(cigar: cigar, smokingDuration: 0)
        }
        .sheet(isPresented: $showGiftSheet) {
            GiftCigarView(cigar: cigar)
        }
        .onAppear {
            checkForActiveSession()
        }
    }
    
    private func deleteCigar() {
        modelContext.delete(cigar)
        dismiss()
    }
    
    private func checkForActiveSession() {
        // Simple predicate just for active sessions
        let descriptor = FetchDescriptor<SmokingSession>(
            predicate: #Predicate<SmokingSession> { session in
                session.isActive
            }
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            // Filter in memory
            hasActiveSession = sessions.contains { session in
                session.cigar?.id == cigar.id
            }
            logger.debug("Found active session: \(hasActiveSession)")
        } catch {
            logger.error("Error fetching active session: \(error.localizedDescription)")
            hasActiveSession = false
        }
    }
}

struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(review.effectiveDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                HStack {
                    Text(String(format: "%.1f", review.averageRating))
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            if let notes = review.notes, !notes.isEmpty {
                Text(notes)
                    .lineLimit(2)
                    .font(.subheadline)
            }
            
            if let photos = review.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(photos.indices, id: \.self) { index in
                            if let image = UIImage(data: photos[index]) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1)
            .scaleEffect(isAnimating ? 1.2 : 1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
} 