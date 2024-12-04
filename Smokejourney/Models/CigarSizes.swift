import Foundation

struct CigarSize: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let length: String
    let ringGauge: String
    let category: SizeCategory
}

enum SizeCategory: String, CaseIterable {
    case traditional = "Traditional Sizes"
    case figurado = "Figurado (Shaped) Cigars"
    case largeRing = "Large Ring Gauge Cigars"
    case other = "Other Sizes"
}

class CigarSizes {
    static let shared = CigarSizes()
    
    let sizes: [CigarSize] = [
        // Traditional Sizes
        CigarSize(
            name: "Corona",
            description: "Classic size, medium length with moderate ring gauge",
            length: "5.5\" - 6\"",
            ringGauge: "42-44",
            category: .traditional
        ),
        CigarSize(
            name: "Petit Corona",
            description: "Shorter version of the Corona",
            length: "4.5\" - 5\"",
            ringGauge: "40-42",
            category: .traditional
        ),
        CigarSize(
            name: "Robusto",
            description: "Popular short format with thick ring gauge",
            length: "4.75\" - 5.5\"",
            ringGauge: "48-52",
            category: .traditional
        ),
        CigarSize(
            name: "Churchill",
            description: "Long format named after Winston Churchill",
            length: "6.75\" - 7\"",
            ringGauge: "47-50",
            category: .traditional
        ),
        CigarSize(
            name: "Double Corona",
            description: "Extra long format",
            length: "7.5\" - 8.5\"",
            ringGauge: "49-52",
            category: .traditional
        ),
        CigarSize(
            name: "Toro",
            description: "Medium-long with substantial ring gauge",
            length: "6\" - 6.5\"",
            ringGauge: "50-54",
            category: .traditional
        ),
        CigarSize(
            name: "Lonsdale",
            description: "Long and slender format",
            length: "6.5\" - 7\"",
            ringGauge: "42-44",
            category: .traditional
        ),
        CigarSize(
            name: "Lancero",
            description: "Extra long and very slender",
            length: "7\" - 7.5\"",
            ringGauge: "38-40",
            category: .traditional
        ),
        CigarSize(
            name: "Panatela",
            description: "Long and very thin format",
            length: "5\" - 7.5\"",
            ringGauge: "34-38",
            category: .traditional
        ),
        
        // Figurado Cigars
        CigarSize(
            name: "Pyramid",
            description: "Tapered head with gradual ring gauge increase",
            length: "6\" - 7\"",
            ringGauge: "40-54",
            category: .figurado
        ),
        CigarSize(
            name: "Belicoso",
            description: "Short pyramid with pointed head",
            length: "5\" - 5.5\"",
            ringGauge: "50-54",
            category: .figurado
        ),
        CigarSize(
            name: "Torpedo",
            description: "Similar to Pyramid but with pointed head and closed foot",
            length: "6\" - 7\"",
            ringGauge: "46-54",
            category: .figurado
        ),
        CigarSize(
            name: "Perfecto",
            description: "Tapered at both ends with bulbous middle",
            length: "4.5\" - 9\"",
            ringGauge: "38-60",
            category: .figurado
        ),
        CigarSize(
            name: "Culebra",
            description: "Three intertwined cigars",
            length: "5\" - 6\"",
            ringGauge: "38",
            category: .figurado
        ),
        CigarSize(
            name: "Diadema",
            description: "Large Perfecto format",
            length: "8\" - 10\"",
            ringGauge: "40-52",
            category: .figurado
        ),
        
        // Large Ring Gauge
        CigarSize(
            name: "Gordo",
            description: "Also called Gigante or Magnum",
            length: "6\" - 7\"",
            ringGauge: "56-60+",
            category: .largeRing
        ),
        
        // Other Sizes
        CigarSize(
            name: "Petit Robusto",
            description: "Shorter version of the Robusto",
            length: "4\" - 4.5\"",
            ringGauge: "48-52",
            category: .other
        ),
        CigarSize(
            name: "Nub",
            description: "Short and stubby format",
            length: "3.75\" - 4\"",
            ringGauge: "58-66",
            category: .other
        )
    ]
    
    func searchSizes(_ query: String) -> [CigarSize] {
        if query.isEmpty {
            return sizes
        }
        return sizes.filter { size in
            size.name.localizedCaseInsensitiveContains(query) ||
            size.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getSize(_ name: String) -> CigarSize? {
        sizes.first { size in
            size.name.localizedCaseInsensitiveContains(name)
        }
    }
    
    var sizesByCategory: [SizeCategory: [CigarSize]] {
        Dictionary(grouping: sizes) { $0.category }
    }
} 