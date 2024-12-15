import SwiftUI
import HomeKit

struct HomeKitAutomationView: View {
    @EnvironmentObject private var homeKit: HomeKitService
    @State private var showAddAutomation = false
    @State private var selectedTrigger: AutomationTrigger?
    @State private var selectedAction: AutomationAction?
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        List {
            Section {
                Button(action: { showAddAutomation = true }) {
                    Label("Add Automation", systemImage: "plus")
                }
            }
            
            Section("Active Automations") {
                if let home = homeKit.home {
                    ForEach(home.triggers, id: \.uniqueIdentifier) { trigger in
                        if let eventTrigger = trigger as? HMEventTrigger {
                            AutomationRow(trigger: eventTrigger)
                        }
                    }
                }
            }
        }
        .navigationTitle("Automations")
        .sheet(isPresented: $showAddAutomation) {
            AddAutomationView()
                .environmentObject(homeKit)
        }
        .alert("Error", isPresented: $showError, presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

struct AutomationRow: View {
    let trigger: HMEventTrigger
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(trigger.name)
                .font(.headline)
            
            Toggle("Enabled", isOn: .constant(trigger.isEnabled))
                .toggleStyle(.switch)
            
            if let actionSets = trigger.actionSets as? [HMActionSet], !actionSets.isEmpty {
                ForEach(actionSets, id: \.uniqueIdentifier) { actionSet in
                    Text(actionSet.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeKitAutomationView()
            .environmentObject(HomeKitService.shared)
    }
} 