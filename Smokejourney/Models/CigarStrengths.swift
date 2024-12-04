import Foundation

struct CigarStrengthDetail: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let characteristics: String
    let examples: [String]
    let category: StrengthCategory
}

enum StrengthCategory: String, CaseIterable {
    case light = "Light Strength"
    case medium = "Medium Strength"
    case full = "Full Strength"
}

class CigarStrengths {
    static let shared = CigarStrengths()
    
    let strengths: [CigarStrengthDetail] = [
        // Light Strength
        CigarStrengthDetail(
            name: "Mild",
            description: "Perfect for beginners",
            characteristics: "Smooth, light flavor, lower nicotine content",
            examples: [
                "Macanudo Café",
                "Ashton Classic",
                "Montecristo White Series",
                "Davidoff Signature",
                "Arturo Fuente Hemingway (mild-to-medium)"
            ],
            category: .light
        ),
        CigarStrengthDetail(
            name: "Mild to Medium",
            description: "Transitional strength",
            characteristics: "Slightly more flavor and strength than mild cigars, good for new smokers transitioning",
            examples: [
                "Romeo y Julieta 1875",
                "H. Upmann Vintage Cameroon",
                "Rocky Patel Vintage 1999",
                "Oliva Connecticut Reserve",
                "Perdomo Champagne"
            ],
            category: .light
        ),
        
        // Medium Strength
        CigarStrengthDetail(
            name: "Medium",
            description: "Balanced strength",
            characteristics: "Balanced flavor and nicotine strength; suitable for intermediate smokers",
            examples: [
                "Arturo Fuente Gran Reserva",
                "My Father Flor de Las Antillas",
                "Padron 3000 Series",
                "Alec Bradley Prensado",
                "CAO Flathead V554 Camshaft"
            ],
            category: .medium
        ),
        CigarStrengthDetail(
            name: "Medium to Full",
            description: "Enhanced strength",
            characteristics: "Richer flavors, noticeable nicotine content, often complex",
            examples: [
                "Montecristo Espada",
                "Romeo y Julieta Reserva Real Nicaragua",
                "Oliva Serie V",
                "La Aroma de Cuba Mi Amor",
                "Rocky Patel Decade"
            ],
            category: .medium
        ),
        
        // Full Strength
        CigarStrengthDetail(
            name: "Full",
            description: "Bold and strong",
            characteristics: "Bold flavors, high nicotine, often spicy and complex; for experienced smokers",
            examples: [
                "Liga Privada No. 9 by Drew Estate",
                "Padron 1926 Series",
                "Arturo Fuente Opus X",
                "My Father Le Bijou 1922",
                "AJ Fernandez Enclave"
            ],
            category: .full
        ),
        CigarStrengthDetail(
            name: "Full to Extra-Full",
            description: "Maximum strength",
            characteristics: "Extremely robust flavors and very high nicotine content; for seasoned aficionados",
            examples: [
                "Camacho Triple Maduro",
                "LFD (La Flor Dominicana) Double Ligero",
                "Asylum Straight Jacket",
                "Tatuaje Fausto",
                "Diesel Unlimited Maduro"
            ],
            category: .full
        )
    ]
    
    func searchStrengths(_ query: String) -> [CigarStrengthDetail] {
        if query.isEmpty {
            return strengths
        }
        return strengths.filter { strength in
            strength.name.localizedCaseInsensitiveContains(query) ||
            strength.characteristics.localizedCaseInsensitiveContains(query) ||
            strength.examples.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func getStrength(_ name: String) -> CigarStrengthDetail? {
        strengths.first { strength in
            strength.name.localizedCaseInsensitiveContains(name)
        }
    }
    
    var strengthsByCategory: [StrengthCategory: [CigarStrengthDetail]] {
        Dictionary(grouping: strengths) { $0.category }
    }
} 