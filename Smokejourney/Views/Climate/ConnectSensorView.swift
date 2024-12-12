import SwiftUI

struct ConnectSensorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @State private var isScanning = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScanningSection(
                    isScanning: isScanning,
                    onScanTapped: startScanning
                )
                
                InstructionsSection()
            }
            .padding()
        }
        .navigationTitle("Connect Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startScanning() {
        Task { @MainActor in
            guard !isScanning else { return }
            
            isScanning = true
            defer { isScanning = false }
            
            do {
                let manager = sensorPushManager
                if try await manager.scanForSensors() {
                    dismiss()
                } else {
                    errorMessage = "No sensors found. Make sure your sensor is in pairing mode."
                    showError = true
                }
            } catch {
                if let sensorError = error as? SensorPushError {
                    errorMessage = sensorError.localizedDescription
                } else {
                    errorMessage = "An unexpected error occurred while scanning"
                }
                showError = true
            }
        }
    }
}

private struct ScanningSection: View {
    let isScanning: Bool
    let onScanTapped: () -> Void
    
    var body: some View {
        GroupBox {
            if isScanning {
                HStack {
                    ProgressView()
                        .controlSize(.regular)
                    Text("Scanning for sensors...")
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                Button(action: onScanTapped) {
                    Label("Scan for Sensors", systemImage: "sensor.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .disabled(isScanning)
            }
        } label: {
            Text("Scan")
                .font(.headline)
        }
    }
}

private struct InstructionsSection: View {
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("How to Connect")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint("Press and hold the button on your SensorPush device")
                    BulletPoint("Wait for the LED to start blinking")
                    BulletPoint("Tap 'Scan for Sensors' above")
                    BulletPoint("Select your sensor when it appears")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Instructions")
                .font(.headline)
        }
    }
}

private struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        ConnectSensorView()
            .environmentObject(SensorPushService())
    }
} 