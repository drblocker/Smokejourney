import SwiftUI
import HomeKit

struct AddAutomationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeKit = HomeKitService.shared
    
    // MARK: - State Properties
    @State private var name = ""
    @State private var triggerType: TriggerType = .threshold
    @State private var sensorType = HomeKitService.SensorType.temperature
    @State private var thresholdValue = 70.0
    @State private var comparisonType: ComparisonType = .above
    @State private var timeComponents = DateComponents()
    @State private var actionType: ActionType = .notification
    @State private var notificationMessage = ""
    @State private var targetValue = 70.0
    
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    
    // MARK: - Types
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
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            Form {
                nameSection
                triggerSection
                actionSection
            }
            .navigationTitle("Add Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - View Components
    private var nameSection: some View {
        Section("Automation Name") {
            TextField("Name", text: $name)
        }
    }
    
    private var triggerSection: some View {
        Section("Trigger") {
            Picker("Type", selection: $triggerType) {
                ForEach(TriggerType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            
            if triggerType == .threshold {
                thresholdTriggerOptions
            } else {
                timeTriggerOptions
            }
        }
    }
    
    private var thresholdTriggerOptions: some View {
        Group {
            Picker("Sensor", selection: $sensorType) {
                ForEach(HomeKitService.SensorType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
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
        }
    }
    
    private var timeTriggerOptions: some View {
        DatePicker(
            "Time",
            selection: .constant(Date()),
            displayedComponents: [.hourAndMinute]
        )
    }
    
    private var actionSection: some View {
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
    
    private var cancelButton: ToolbarItem<(), some View> {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
    
    private var saveButton: ToolbarItem<(), some View> {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveAutomation()
            }
            .disabled(!isValid || isLoading)
        }
    }
    
    // MARK: - Helper Methods
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
                let trigger = createTrigger()
                let action = createAction()
                
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
    
    private func createTrigger() -> AutomationTrigger {
        if triggerType == .threshold {
            let type = AutomationTrigger.TriggerType.threshold(
                value: thresholdValue,
                comparison: comparisonType.predicateOperator
            )
            return sensorType == .temperature ? .temperature(type) : .humidity(type)
        } else {
            return sensorType == .temperature ? 
                .temperature(.time(timeComponents)) : 
                .humidity(.time(timeComponents))
        }
    }
    
    private func createAction() -> AutomationAction {
        let actionType = self.actionType == .notification ?
            AutomationAction.ActionType.notification(notificationMessage) :
            AutomationAction.ActionType.setValue(targetValue, HMCharacteristic())
        return .alert(actionType)
    }
}

#Preview {
    AddAutomationView()
} 