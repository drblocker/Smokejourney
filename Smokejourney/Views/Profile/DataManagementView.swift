import SwiftUI
import SwiftData

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingClearDataAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                
                Button(role: .destructive) {
                    showingClearDataAlert = true
                } label: {
                    Label("Clear All Data", systemImage: "trash")
                }
            } header: {
                Text("Data Management")
            } footer: {
                Text("Export your data for backup or transfer to another device.")
            }
        }
        .navigationTitle("Data Management")
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await clearAllData()
                }
            }
        } message: {
            Text("Are you sure you want to clear all data? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView()
        }
    }
    
    private func clearAllData() async {
        do {
            try await modelContext.delete(model: User.self)
            try await modelContext.delete(model: Humidor.self)
            try await modelContext.delete(model: Cigar.self)
            try await modelContext.delete(model: CigarPurchase.self)
            try await modelContext.delete(model: Review.self)
            try await modelContext.delete(model: SmokingSession.self)
            try await modelContext.delete(model: EnvironmentSettings.self)
            
            try modelContext.save()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Supporting Views
private struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Export functionality coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Import functionality coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementView()
            .modelContainer(for: [
                User.self,
                Humidor.self,
                Cigar.self,
                CigarPurchase.self,
                Review.self,
                SmokingSession.self,
                EnvironmentSettings.self
            ], inMemory: true)
    }
} 