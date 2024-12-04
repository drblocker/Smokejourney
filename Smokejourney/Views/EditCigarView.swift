import SwiftUI
import SwiftData
import PhotosUI

struct EditCigarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var cigar: Cigar
    
    @State private var brand: String
    @State private var name: String
    @State private var wrapperType: String
    @State private var size: String
    @State private var strength: CigarStrength
    @State private var searchText = ""
    @State private var sizeSearchText = ""
    @State private var wrapperSearchText = ""
    @State private var strengthSearchText = ""
    @State private var showBrandPicker = false
    @State private var showSizePicker = false
    @State private var showWrapperPicker = false
    @State private var showStrengthPicker = false
    @State private var showPhotoOptions = false
    @State private var photoSource: PhotoSource?
    @State private var wrapperImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedQuantity: Int
    @State private var priceString: String
    @State private var vendor: String
    @State private var url: String
    
    private let brands = CigarBrands.shared
    private let sizes = CigarSizes.shared
    private let wrappers = CigarWrappers.shared
    private let strengths = CigarStrengths.shared
    @State private var selectedBrand: CigarBrand?
    @State private var selectedSize: CigarSize?
    @State private var selectedWrapper: CigarWrapper?
    @State private var selectedStrength: CigarStrengthDetail?
    
    init(cigar: Cigar) {
        self.cigar = cigar
        _brand = State(initialValue: cigar.brand ?? "")
        _name = State(initialValue: cigar.name ?? "")
        _wrapperType = State(initialValue: cigar.wrapperType ?? "")
        _size = State(initialValue: cigar.size ?? "")
        _strength = State(initialValue: cigar.strength ?? .medium)
        
        if let latestPurchase = cigar.purchases?.last {
            _selectedQuantity = State(initialValue: latestPurchase.quantity ?? 1)
            _priceString = State(initialValue: latestPurchase.price?.description ?? "")
            _vendor = State(initialValue: latestPurchase.vendor ?? "")
            _url = State(initialValue: latestPurchase.url ?? "")
        } else {
            _selectedQuantity = State(initialValue: 1)
            _priceString = State(initialValue: "")
            _vendor = State(initialValue: "")
            _url = State(initialValue: "")
        }
        
        if let imageData = cigar.wrapperImageData,
           let image = UIImage(data: imageData) {
            _wrapperImage = State(initialValue: image)
        }
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
        strengthSearchText.isEmpty ? strengths.strengths : strengths.searchStrengths(strengthSearchText)
    }
    
    private var isValid: Bool {
        !brand.isEmpty && !name.isEmpty && !size.isEmpty && !wrapperType.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Brand Information") {
                    HStack {
                        Text("Brand")
                        Spacer()
                        Button(action: { showBrandPicker = true }) {
                            Text(brand.isEmpty ? "Select Brand" : brand)
                                .foregroundColor(brand.isEmpty ? .secondary : .primary)
                        }
                    }
                    
                    TextField("Name", text: $name)
                }
                
                Section("Cigar Details") {
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
                        Label("Change Photo", systemImage: "photo.on.rectangle.angled")
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
            .navigationTitle("Edit Cigar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(!isValid)
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
            .sheet(isPresented: $showSizePicker) {
                NavigationStack {
                    List(filteredSizes) { size in
                        Button(action: {
                            self.size = size.name
                            self.selectedSize = size
                            showSizePicker = false
                        }) {
                            Text(size.name)
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
                            Text(wrapper.name)
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
                            Text(strength.name)
                        }
                    }
                    .searchable(text: $strengthSearchText, prompt: "Search strengths...")
                    .navigationTitle("Select Strength")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func saveChanges() {
        cigar.brand = brand
        cigar.name = name
        cigar.wrapperType = wrapperType
        cigar.size = size
        cigar.strength = strength
        
        if let wrapperImage {
            cigar.wrapperImageData = wrapperImage.jpegData(compressionQuality: 0.8)
        }
        
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
    }
} 