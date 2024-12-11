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
    @State private var isShowingPhotoSource = false
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var isShowingPhotoOptions = false
    
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
        
        let customName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if customName.isEmpty {
            customNameError = "Name cannot be empty"
            return false
        }
        
        if customName.count < 2 {
            customNameError = "Name must be at least 2 characters"
            return false
        }
        
        if customName.count > 50 {
            customNameError = "Name must be less than 50 characters"
            return false
        }
        
        customNameError = nil
        return true
    }
    
    private var isSaveDisabled: Bool {
        brand.isEmpty || 
        (isCustomName ? !isValidCustomName : name.isEmpty) || 
        wrapperType.isEmpty || 
        size.isEmpty || 
        (humidor.effectiveCigars.count >= humidor.effectiveCapacity)
    }
    
    var filteredBrands: [CigarBrand] {
        searchText.isEmpty ? brands.brands : brands.searchBrands(searchText)
    }
    
    var filteredSizes: [CigarSize] {
        sizeSearchText.isEmpty ? sizes.sizes : sizes.searchSizes(sizeSearchText)
    }
    
    var filteredWrappers: [CigarWrapper] {
        wrapperSearchText.isEmpty ? wrappers.wrappers : wrappers.searchWrappers(wrapperSearchText)
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
        NavigationStack {
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
                    
                    Button(action: {
                        isShowingPhotoOptions = true
                    }) {
                        Label("Add Photo", systemImage: "photo.on.rectangle.angled")
                    }
                }
            }
            .navigationTitle("Add Cigar")
            .confirmationDialog("Choose Photo Source", isPresented: $isShowingPhotoOptions) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        isShowingCamera = true
                    }
                }
                Button("Choose from Library") {
                    isShowingPhotoPicker = true
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraView(image: $wrapperImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $isShowingPhotoPicker) {
                PhotosPicker(selection: $selectedPhotoItem,
                           matching: .images,
                           photoLibrary: .shared()) {
                    Text("Select Photo")
                }
            }
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            wrapperImage = image
                        }
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
                    saveCigar()
                }
                .disabled(isSaveDisabled)
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
        let effectiveName = isCustomName ? customName : name
        let cigar = Cigar(
            brand: brand,
            name: effectiveName,
            wrapperType: wrapperType,
            size: size,
            strength: strength
        )
        
        if let price = Decimal(string: priceString), price > 0 {
            let purchase = CigarPurchase(
                quantity: selectedQuantity,
                price: price,
                vendor: vendor,
                url: url
            )
            cigar.purchases = [purchase]
        }
        
        // Initialize cigars array if nil
        if humidor.cigars == nil {
            humidor.cigars = []
        }
        humidor.cigars?.append(cigar)
        dismiss()
    }
} 