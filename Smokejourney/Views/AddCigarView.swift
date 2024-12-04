import SwiftUI
import SwiftData
import PhotosUI
import AVKit

enum PhotoSource: Identifiable {
    case camera
    case photoLibrary
    
    var id: Self { self }
}

struct AddCigarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var humidor: Humidor
    
    @State private var brand = ""
    @State private var name = ""
    @State private var wrapperType = ""
    @State private var size = ""
    @State private var strength = CigarStrength.medium
    @State private var searchText = ""
    @State private var sizeSearchText = ""
    @State private var wrapperSearchText = ""
    @State private var isCustomBrand = false
    @State private var showBrandPicker = false
    @State private var showSizePicker = false
    @State private var showWrapperPicker = false
    @State private var strengthSearchText = ""
    @State private var showStrengthPicker = false
    @State private var selectedQuantity = 1
    @State private var priceString = ""
    @State private var vendor = ""
    @State private var url = ""
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var wrapperImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var selectedBrandLine: CigarBrandLine?
    @State private var showBrandLinePicker = false
    @State private var isCustomName = false
    @State private var customName = ""
    @State private var customNameError: String?
    
    private let brands = CigarBrands.shared
    private let sizes = CigarSizes.shared
    private let wrappers = CigarWrappers.shared
    private let strengths = CigarStrengths.shared
    @State private var selectedBrand: CigarBrand?
    @State private var selectedSize: CigarSize?
    @State private var selectedWrapper: CigarWrapper?
    @State private var selectedStrength: CigarStrengthDetail?
    
    private var isValidCustomName: Bool {
        guard isCustomName else { return true }
        
        // Name cannot be empty
        if customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            customNameError = "Name cannot be empty"
            return false
        }
        
        // Name should be at least 2 characters
        if customName.count < 2 {
            customNameError = "Name must be at least 2 characters"
            return false
        }
        
        // Name should not be too long (arbitrary limit of 50 characters)
        if customName.count > 50 {
            customNameError = "Name must be less than 50 characters"
            return false
        }
        
        // Clear any previous error
        customNameError = nil
        return true
    }
    
    private var isSaveDisabled: Bool {
        brand.isEmpty || 
        (isCustomName ? !isValidCustomName : name.isEmpty) || 
        wrapperType.isEmpty || 
        size.isEmpty || 
        humidor.effectiveCigars.count >= humidor.effectiveCapacity
    }
    
    var filteredBrands: [CigarBrand] {
        if searchText.isEmpty {
            return brands.brands
        }
        return brands.searchBrands(searchText)
    }
    
    var filteredSizes: [CigarSize] {
        if sizeSearchText.isEmpty {
            return sizes.sizes
        }
        return sizes.searchSizes(sizeSearchText)
    }
    
    var filteredWrappers: [CigarWrapper] {
        if wrapperSearchText.isEmpty {
            return wrappers.wrappers
        }
        return wrappers.searchWrappers(wrapperSearchText)
    }
    
    var filteredStrengths: [CigarStrengthDetail] {
        if strengthSearchText.isEmpty {
            return strengths.strengths
        }
        return strengths.searchStrengths(strengthSearchText)
    }
    
    var filteredBrandLines: [CigarBrandLine] {
        selectedBrand?.lines ?? []
    }
    
    private var isValid: Bool {
        // Basic validation
        guard !brand.isEmpty else { return false }
        guard !name.isEmpty else { return false }
        guard !size.isEmpty else { return false }
        guard !wrapperType.isEmpty else { return false }
        guard selectedQuantity > 0 else { return false }
        
        // Price validation if entered
        if !priceString.isEmpty {
            guard let _ = Decimal(string: priceString) else { return false }
        }
        
        // URL validation if entered
        if !url.isEmpty {
            guard URL(string: url) != nil else { return false }
        }
        
        // Capacity check
        if humidor.effectiveCigars.count + selectedQuantity > humidor.effectiveCapacity {
            return false
        }
        
        return true
    }
    
    var body: some View {
        Form {
            Section("Brand Selection") {
                HStack {
                    Text("Brand")
                    Spacer()
                    Button(action: { showBrandPicker = true }) {
                        Text(brand.isEmpty ? "Select Brand" : brand)
                            .foregroundColor(brand.isEmpty ? .secondary : .primary)
                    }
                }
                
                if selectedBrand != nil {
                    HStack {
                        Text("Name")
                        Spacer()
                        Button(action: { showBrandLinePicker = true }) {
                            Text(name.isEmpty ? "Select Name" : name)
                                .foregroundColor(name.isEmpty ? .secondary : .primary)
                        }
                    }
                }
                
                Toggle("Custom Brand", isOn: $isCustomBrand)
                
                if isCustomBrand {
                    TextField("Enter Brand Name", text: $brand)
                    TextField("Enter Name", text: $name)
                }
            }
            
            if let selectedBrand, !isCustomBrand {
                Section("Brand Info") {
                    Text(selectedBrand.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Country: \(selectedBrand.country)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Cigar Details") {
                TextField("Name", text: $name)
                
                HStack {
                    Text("Size")
                    Spacer()
                    Button(action: { showSizePicker = true }) {
                        Text(size.isEmpty ? "Select Size" : size)
                            .foregroundColor(size.isEmpty ? .secondary : .primary)
                    }
                }
                
                if let selectedSize {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedSize.description)
                            .font(.caption)
                        Text("Length: \(selectedSize.length)")
                            .font(.caption)
                        Text("Ring Gauge: \(selectedSize.ringGauge)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Wrapper")
                    Spacer()
                    Button(action: { showWrapperPicker = true }) {
                        Text(wrapperType.isEmpty ? "Select Wrapper" : wrapperType)
                            .foregroundColor(wrapperType.isEmpty ? .secondary : .primary)
                    }
                }
                
                if let selectedWrapper {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedWrapper.description)
                            .font(.caption)
                        Text("Origin: \(selectedWrapper.origin)")
                            .font(.caption)
                        Text("Color: \(selectedWrapper.color)")
                            .font(.caption)
                        Text("Characteristics: \(selectedWrapper.characteristics)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Strength")
                    Spacer()
                    Button(action: { showStrengthPicker = true }) {
                        Text(selectedStrength?.name ?? "Select Strength")
                            .foregroundColor(selectedStrength == nil ? .secondary : .primary)
                    }
                }
                
                if let selectedStrength {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedStrength.description)
                            .font(.caption)
                        Text("Characteristics: \(selectedStrength.characteristics)")
                            .font(.caption)
                        Text("Examples:")
                            .font(.caption)
                        ForEach(selectedStrength.examples, id: \.self) { example in
                            Text("• \(example)")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Section("Wrapper Photo") {
                if let wrapperImage {
                    Image(uiImage: wrapperImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                }
                
                Button(action: { showPhotoOptions = true }) {
                    Label("Add Photo", systemImage: "photo.on.rectangle.angled")
                }
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
                    CameraView(image: $wrapperImage)
                case .photoLibrary:
                    PhotosPicker(selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()) {
                        Text("Select Photo")
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quantity")
                        .foregroundColor(.primary)
                    HStack {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.secondary)
                        TextField("1", value: $selectedQuantity, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: selectedQuantity) {
                                // Ensure quantity stays within valid range
                                if selectedQuantity < 1 {
                                    selectedQuantity = 1
                                } else if selectedQuantity > 99 {
                                    selectedQuantity = 99
                                }
                            }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price")
                        .foregroundColor(.primary)
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $priceString)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vendor")
                        .foregroundColor(.primary)
                    HStack {
                        Image(systemName: "bag.circle.fill")
                            .foregroundColor(.secondary)
                        TextField("Store or website name", text: $vendor)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Purchase URL")
                        .foregroundColor(.primary)
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.secondary)
                        TextField("https://", text: $url)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } header: {
                Text("Purchase Details")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enter a number between 1-99")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !priceString.isEmpty {
                        Text("Enter price per cigar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Add Cigar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if validateAndSave() {
                        dismiss()
                    }
                }
                .disabled(!isValid)
            }
        }
        .sheet(isPresented: $showBrandPicker) {
            NavigationStack {
                List(filteredBrands) { brand in
                    Button(action: {
                        self.brand = brand.name
                        self.selectedBrand = brand
                        showBrandPicker = false
                    }) {
                        Text(brand.name)
                    }
                }
                .searchable(text: $searchText, prompt: "Search brands...")
                .navigationTitle("Select Brand")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showBrandLinePicker) {
            NavigationStack {
                List(filteredBrandLines) { line in
                    Button(action: {
                        self.name = line.name
                        showBrandLinePicker = false
                    }) {
                        Text(line.name)
                    }
                }
                .navigationTitle("Select Line")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showSizePicker) {
            NavigationStack {
                List(filteredSizes) { size in
                    Button(action: {
                        self.size = size.name
                        self.selectedSize = size
                        showSizePicker = false
                    }) {
                        VStack(alignment: .leading) {
                            Text(size.displayName)
                            Text(size.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .searchable(text: $sizeSearchText, prompt: "Search sizes...")
                .navigationTitle("Select Size")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showWrapperPicker) {
            NavigationStack {
                List(filteredWrappers) { wrapper in
                    Button(action: {
                        self.wrapperType = wrapper.name
                        self.selectedWrapper = wrapper
                        showWrapperPicker = false
                    }) {
                        VStack(alignment: .leading) {
                            Text(wrapper.name)
                            Text(wrapper.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .searchable(text: $wrapperSearchText, prompt: "Search wrappers...")
                .navigationTitle("Select Wrapper")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showStrengthPicker) {
            NavigationStack {
                List(filteredStrengths) { strength in
                    Button(action: {
                        self.strength = CigarStrength(rawValue: strength.name.lowercased()) ?? .medium
                        self.selectedStrength = strength
                        showStrengthPicker = false
                    }) {
                        VStack(alignment: .leading) {
                            Text(strength.name)
                            Text(strength.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .searchable(text: $strengthSearchText, prompt: "Search strengths...")
                .navigationTitle("Select Strength")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private func saveCigar() {
        let cigar = Cigar(
            brand: brand,
            name: isCustomName ? customName.trimmingCharacters(in: .whitespacesAndNewlines) : name,
            wrapperType: wrapperType,
            size: size,
            strength: strength
        )
        
        let purchase = CigarPurchase(
            quantity: selectedQuantity,
            price: Decimal(string: priceString),
            vendor: vendor.isEmpty ? nil : vendor,
            url: url.isEmpty ? nil : url
        )
        
        purchase.cigar = cigar
        if cigar.purchases == nil {
            cigar.purchases = []
        }
        cigar.purchases?.append(purchase)
        
        cigar.humidor = humidor
        if humidor.cigars == nil {
            humidor.cigars = []
        }
        humidor.cigars?.append(cigar)
        
        dismiss()
    }
    
    private func validateAndSave() -> Bool {
        // Validate quantity
        guard selectedQuantity > 0 else { return false }
        
        // Validate price if entered
        if !priceString.isEmpty {
            guard let _ = Decimal(string: priceString) else { return false }
        }
        
        // Validate URL if entered
        if !url.isEmpty {
            guard URL(string: url) != nil else { return false }
        }
        
        // Check humidor capacity
        if humidor.effectiveCigars.count + selectedQuantity > humidor.effectiveCapacity {
            return false
        }
        
        // If all validations pass, save the cigar
        saveCigar()
        return true
    }
} 