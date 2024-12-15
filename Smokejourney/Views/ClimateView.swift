import SwiftUI
import SwiftData
import HomeKit
import Charts

struct ClimateView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ClimateViewModel
    @State private var showAddSensor = false
    @State private var showingAlerts = false
    @State private var showSensorManagement = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ClimateViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasAnySensors {
                    ContentUnavailableView {
                        Label("No Sensors", systemImage: "sensor.fill")
                    } description: {
                        Text("Add a sensor to monitor climate conditions")
                    } actions: {
                        Button(action: { showAddSensor = true }) {
                            Label("Add Sensor", systemImage: "plus")
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if !viewModel.alerts.isEmpty {
                                AlertsBanner(alerts: viewModel.alerts)
                            }
                            
                            ClimateTimeRangePicker(selectedRange: $viewModel.selectedTimeRange)
                                .onChange(of: viewModel.selectedTimeRange) { _ in
                                    Task {
                                        await viewModel.refreshData()
                                    }
                                }
                            
                            CurrentConditionsCard(viewModel: viewModel)
                            EnvironmentChartsSection(viewModel: viewModel)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationTitle("Climate")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSensor = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                if !viewModel.alerts.isEmpty {
                    ToolbarItem(placement: .status) {
                        Button {
                            showingAlerts = true
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSensorManagement = true
                    } label: {
                        Image(systemName: "sensor.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSensor) {
                NavigationStack {
                    SensorSelectionSheet { sensor in
                        try? modelContext.save()
                        Task {
                            await viewModel.loadSensorData(for: sensor)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAlerts) {
                NavigationStack {
                    AlertsView(alerts: viewModel.alerts)
                }
            }
            .sheet(isPresented: $showSensorManagement) {
                NavigationStack {
                    SensorManagementView()
                }
            }
        }
    }
}