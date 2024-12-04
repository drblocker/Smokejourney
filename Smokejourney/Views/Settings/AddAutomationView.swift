import SwiftUI
import HomeKit

struct AddAutomationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeKit = HomeKitService.shared
    
    @State private var name = ""
    @State private var triggerType: TriggerType = .threshold
    @State private var sensorType: HomeKitService.SensorType = .temperature
    @State private var thresholdValue = 70.0
    @State private var comparisonType: ComparisonType = .above
    @State private var timeComponents = DateComponents()
    @State private var actionType: ActionType = .notification
    @State private var notificationMessage = ""
    @State private var targetValue = 70.0
    
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    
    enum TriggerType: String, CaseIterable {
        case threshold = "Threshold"
        case time = "Time"
    }
    
    enum ComparisonType: String, CaseIterable {
        case above = "Above"
        case below = "Below"
        
        var predicateOperator: NSComparisonPredicate.Operator {
            switch self {
            case .above: return .greaterThan
            case .below: return .lessThan
            }
        }
    }
    
    enum ActionType: String, CaseIterable {
        case notification = "Send Notification"
        case adjust = "Adjust Value"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Automation Name") {
                    TextField("Name", text: $name)
                }
                
                Section("Trigger") {
                    Picker("Type", selection: $triggerType) {
                        ForEach(TriggerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    if triggerType == .threshold {
                        Picker("Sensor", selection: $sensorType) {
                            Text("Temperature").tag(HomeKitService.SensorType.temperature)
                            Text("Humidity").tag(HomeKitService.SensorType.humidity)
                        }
                        
                        HStack {
                            Text("Value")
                            Spacer()
                            TextField("Value", value: $thresholdValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(sensorType == .temperature ? "°F" : "%")
                        }
                        
                        Picker("Condition", selection: $comparisonType) {
                            ForEach(ComparisonType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    } else {
                        DatePicker("Time", selection: .constant(Date()), displayedComponents: [.hourAndMinute])
                    }
                }
                
                Section("Action") {
                    Picker("Type", selection: $actionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    switch actionType {
                    case .notification:
                        TextField("Message", text: $notificationMessage)
                    case .adjust:
                        HStack {
                            Text("Target Value")
                            Spacer()
                            TextField("Value", value: $targetValue, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(sensorType == .temperature ? "°F" : "%")
                        }
                    }
                }
            }
            .navigationTitle("Add Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAutomation()
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private var isValid: Bool {
        if name.isEmpty { return false }
        
        switch actionType {
        case .notification:
            return !notificationMessage.isEmpty
        case .adjust:
            return targetValue > 0
        }
    }
    
    private func saveAutomation() {
        isLoading = true
        
        Task {
            do {
                // Create trigger
                let trigger: AutomationTrigger
                if triggerType == .threshold {
                    let type = AutomationTrigger.TriggerType.threshold(
                        value: thresholdValue,
                        comparison: comparisonType.predicateOperator
                    )
                    trigger = sensorType == .temperature ? .temperature(type) : .humidity(type)
                } else {
                    trigger = sensorType == .temperature ? 
                        .temperature(.time(timeComponents)) : 
                        .humidity(.time(timeComponents))
                }
                
                // Create action
                let actionType = actionType == .notification ?
                    AutomationAction.ActionType.notification(notificationMessage) :
                    AutomationAction.ActionType.setValue(targetValue, HMCharacteristic())
                let action: AutomationAction = .alert(actionType)
                
                // Setup automation
                try await homeKit.setupAutomation(trigger: trigger, action: action)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AddAutomationView()
} 