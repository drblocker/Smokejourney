import Foundation

struct CigarSize: Identifiable {
    let id = UUID()
    let name: String
    let length: Double  // Length in inches
    let ringGauge: Int  // Ring gauge in 64ths of an inch
    let description: String
    
    var displayName: String {
        "\(name) (\(length)\" x \(ringGauge))"
    }
}

class CigarSizes {
    static let shared = CigarSizes()
    
    let sizes: [CigarSize] = [
        CigarSize(name: "Petit Corona", length: 4.5, ringGauge: 42, 
                  description: "A small, slender cigar"),
        CigarSize(name: "Corona", length: 5.5, ringGauge: 42, 
                  description: "Classic size, balanced proportions"),
        CigarSize(name: "Robusto", length: 5.0, ringGauge: 50, 
                  description: "Popular short format with good girth"),
        CigarSize(name: "Toro", length: 6.0, ringGauge: 52, 
                  description: "Larger format with substantial smoking time"),
        CigarSize(name: "Churchill", length: 7.0, ringGauge: 48, 
                  description: "Long format named after Winston Churchill"),
        CigarSize(name: "Double Corona", length: 7.5, ringGauge: 49, 
                  description: "Extra long format for extended smoking"),
        CigarSize(name: "Gordo", length: 6.0, ringGauge: 60, 
                  description: "Thick ring gauge format"),
        CigarSize(name: "Lancero", length: 7.5, ringGauge: 38, 
                  description: "Long, thin elegant format"),
        CigarSize(name: "Lonsdale", length: 6.5, ringGauge: 42, 
                  description: "Classic long format"),
        CigarSize(name: "Belicoso", length: 5.5, ringGauge: 52, 
                  description: "Tapered head format"),
        CigarSize(name: "Torpedo", length: 6.25, ringGauge: 52, 
                  description: "Pointed head format"),
        CigarSize(name: "Perfecto", length: 5.75, ringGauge: 48, 
                  description: "Tapered at both ends"),
        // Add more sizes as needed
    ]
    
    func searchSizes(_ query: String) -> [CigarSize] {
        if query.isEmpty {
            return sizes
        }
        return sizes.filter { size in
            size.displayName.localizedCaseInsensitiveContains(query) ||
            size.description.localizedCaseInsensitiveContains(query)
        }
    }
} 