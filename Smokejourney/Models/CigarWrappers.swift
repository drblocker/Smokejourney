import Foundation

struct CigarWrapper: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let origin: String
    let color: String
    let characteristics: String
    let details: String
    let category: WrapperCategory
}

enum WrapperCategory: String, CaseIterable {
    case connecticut = "Connecticut Varieties"
    case maduro = "Maduro & Dark"
    case cuban = "Cuban Heritage"
    case exotic = "Exotic Origins"
    case brazilian = "Brazilian"
    case mexican = "Mexican"
    case specialty = "Specialty Types"
}

class CigarWrappers {
    static let shared = CigarWrappers()
    
    let wrappers: [CigarWrapper] = [
        // Connecticut Varieties
        CigarWrapper(
            name: "Connecticut Shade",
            description: "Premium shade-grown wrapper",
            origin: "Connecticut River Valley, USA; also grown in Ecuador",
            color: "Light tan to golden brown",
            characteristics: "Mild flavor profile with creamy, smooth, and slightly sweet notes",
            details: "Grown under shade cloths to produce thinner, more delicate leaves with fewer veins. The controlled environment reduces direct sunlight, resulting in a lighter-colored wrapper",
            category: .connecticut
        ),
        CigarWrapper(
            name: "Connecticut Broadleaf",
            description: "Sun-grown broadleaf tobacco",
            origin: "Connecticut River Valley, USA",
            color: "Dark brown to near-black",
            characteristics: "Rich, sweet, and earthy flavors with a robust profile",
            details: "Grown in direct sunlight, leading to thicker leaves ideal for Maduro wrappers. Known for its sweetness and depth of flavor",
            category: .connecticut
        ),
        CigarWrapper(
            name: "Pennsylvania Broadleaf",
            description: "American broadleaf tobacco",
            origin: "Pennsylvania, USA",
            color: "Dark brown",
            characteristics: "Full-bodied with rich, earthy flavors",
            details: "Similar to Connecticut Broadleaf but with a distinct profile due to different soil and climate",
            category: .connecticut
        ),
        
        // Maduro & Dark
        CigarWrapper(
            name: "Maduro",
            description: "Fermented dark wrapper",
            origin: "Not region-specific; refers to the fermentation process",
            color: "Dark brown to black",
            characteristics: "Sweet, rich flavors with notes of chocolate, coffee, and spices",
            details: "\"Maduro\" means \"ripe\" in Spanish. The leaves undergo longer fermentation at higher temperatures, enhancing sweetness and complexity",
            category: .maduro
        ),
        CigarWrapper(
            name: "Oscuro",
            description: "Extra dark fermented wrapper",
            origin: "Nicaragua, Mexico, Brazil, and others",
            color: "Very dark brown to black",
            characteristics: "Bold, robust flavors with intense sweetness",
            details: "Harvested from the top leaves of the tobacco plant and fermented longer than Maduro wrappers. Often called \"double Maduro\"",
            category: .maduro
        ),
        
        // Cuban Heritage
        CigarWrapper(
            name: "Habano",
            description: "Cuban-seed wrapper",
            origin: "Originally Cuba; now also grown in Nicaragua, Ecuador, and Dominican Republic",
            color: "Medium to dark brown",
            characteristics: "Full-bodied with spicy, rich flavors and a peppery finish",
            details: "Derived from Cuban seed tobacco, known for its strength and complexity",
            category: .cuban
        ),
        CigarWrapper(
            name: "Corojo",
            description: "Classic Cuban-style wrapper",
            origin: "Originally Cuba; now primarily Honduras and Nicaragua",
            color: "Reddish-brown",
            characteristics: "Spicy, peppery notes with a hint of sweetness",
            details: "Once the standard wrapper leaf in Cuba, it's prized for its bold flavors. Modern Corojo is often a hybrid for disease resistance",
            category: .cuban
        ),
        CigarWrapper(
            name: "Criollo",
            description: "Native Cuban seed tobacco",
            origin: "Cuba originally; now cultivated in Nicaragua and Honduras",
            color: "Medium brown",
            characteristics: "Complex flavors with notes of spice, cocoa, and a natural sweetness",
            details: "\"Criollo\" means \"native seed.\" Used both as a wrapper and filler tobacco",
            category: .cuban
        ),
        CigarWrapper(
            name: "Corojo '99",
            description: "Modern Cuban seed hybrid",
            origin: "Nicaragua and Honduras",
            color: "Reddish-brown",
            characteristics: "Spicy, robust flavors with a complex profile",
            details: "A hybrid developed for better disease resistance while maintaining flavor",
            category: .cuban
        ),
        CigarWrapper(
            name: "Criollo '98",
            description: "Modern Cuban seed hybrid",
            origin: "Nicaragua and Honduras",
            color: "Medium brown",
            characteristics: "Medium to full-bodied with rich, complex flavors",
            details: "Bred for resilience and flavor, it's a staple in many premium cigars",
            category: .cuban
        ),
        CigarWrapper(
            name: "Cuban Seed",
            description: "Cuban seed tobacco grown in various regions",
            origin: "Seeds from Cuba grown in various countries",
            color: "Varies based on growing region",
            characteristics: "Attempts to replicate the classic Cuban flavor profile",
            details: "The soil and climate of the growing region impart unique qualities despite the common seed origin",
            category: .cuban
        ),
        CigarWrapper(
            name: "Piloto Cubano",
            description: "Cuban seed tobacco grown in Dominican Republic",
            origin: "Dominican Republic",
            color: "Medium to dark brown",
            characteristics: "Rich, full-bodied flavors with spicy notes",
            details: "Cuban seed tobacco grown in the Dominican Republic, known for its strength",
            category: .cuban
        ),
        
        // Exotic Origins
        CigarWrapper(
            name: "Cameroon",
            description: "African wrapper leaf",
            origin: "Cameroon, West Africa",
            color: "Reddish-brown to tan",
            characteristics: "Mild to medium-bodied with a delicate sweetness and subtle spicy undertones",
            details: "Thin and toothy wrapper valued for its unique flavor profile. Difficult to grow and harvest",
            category: .exotic
        ),
        CigarWrapper(
            name: "Sumatra",
            description: "Indonesian wrapper leaf",
            origin: "Sumatra, Indonesia; also grown in Ecuador",
            color: "Light to medium brown",
            characteristics: "Mild to medium-bodied with a smooth, sweet, and spicy flavor",
            details: "Ecuadorian Sumatra benefits from natural cloud cover, producing silky wrappers with nuanced flavors",
            category: .exotic
        ),
        CigarWrapper(
            name: "Sumatra Maduro",
            description: "Dark-processed Sumatra leaf",
            origin: "Indonesia",
            color: "Dark brown",
            characteristics: "Sweet, rich flavors with a smooth finish",
            details: "Combines the qualities of Sumatra tobacco with Maduro fermentation",
            category: .exotic
        ),
        CigarWrapper(
            name: "Java",
            description: "Indonesian island tobacco",
            origin: "Java, Indonesia",
            color: "Medium brown",
            characteristics: "Mild, slightly sweet flavors",
            details: "Often used in machine-made cigars due to its consistency",
            category: .exotic
        ),
        CigarWrapper(
            name: "Indonesian",
            description: "Traditional Indonesian tobacco",
            origin: "Java and Sumatra, Indonesia",
            color: "Medium brown",
            characteristics: "Mild flavor with subtle sweetness and spice",
            details: "Resistant to disease, making it a reliable choice for many manufacturers",
            category: .exotic
        ),
        CigarWrapper(
            name: "Peruvian",
            description: "Andean tobacco",
            origin: "Peru",
            color: "Medium brown",
            characteristics: "Unique earthy flavors with hints of sweetness and spice",
            details: "Grown in the fertile soils of the Andes, adding diversity to cigar blends",
            category: .exotic
        ),
        
        // Brazilian
        CigarWrapper(
            name: "Brazilian Arapiraca",
            description: "Brazilian wrapper leaf",
            origin: "Arapiraca region, Brazil",
            color: "Dark brown",
            characteristics: "Sweet, earthy notes with a hint of spice",
            details: "Known as the \"Brazilian wrapper,\" it's celebrated for its aromatic qualities",
            category: .brazilian
        ),
        CigarWrapper(
            name: "Brazilian Mata Fina",
            description: "Premium Brazilian wrapper",
            origin: "Mata Fina region, Brazil",
            color: "Dark brown",
            characteristics: "Sweet, rich flavors with complex notes of cocoa and spice",
            details: "Grown in a microclimate that imparts unique characteristics, often used in premium cigars",
            category: .brazilian
        ),
        
        // Mexican
        CigarWrapper(
            name: "Mexican San Andrés",
            description: "Premium Mexican wrapper",
            origin: "San Andrés Valley, Mexico",
            color: "Dark brown to black",
            characteristics: "Earthy, sweet flavors with a rich aroma",
            details: "Highly regarded for its versatility and depth of flavor, often used in Maduro cigars",
            category: .mexican
        ),
        
        // Specialty Types
        CigarWrapper(
            name: "Candela",
            description: "Green wrapper leaf",
            origin: "Various, including USA and Central America",
            color: "Bright green",
            characteristics: "Mild, grassy, and herbal flavors",
            details: "Cured rapidly to preserve the green chlorophyll, resulting in a unique color and flavor",
            category: .specialty
        ),
        CigarWrapper(
            name: "Fire-Cured",
            description: "Smoke-cured wrapper",
            origin: "USA and other regions",
            color: "Dark brown to black",
            characteristics: "Smoky, barbecue-like flavors with a bold profile",
            details: "Cured over open fires, allowing the tobacco to absorb smoky aromas",
            category: .specialty
        ),
        CigarWrapper(
            name: "Rosado",
            description: "Reddish wrapper leaf",
            origin: "Primarily Cuba, Nicaragua, Honduras",
            color: "Reddish hue",
            characteristics: "Medium to full-bodied with spicy, sweet flavors",
            details: "The reddish color comes from being sun-grown, which enhances the leaf's oils and flavors",
            category: .specialty
        ),
        CigarWrapper(
            name: "Ligero",
            description: "Top leaf tobacco",
            origin: "Various tobacco-growing regions",
            color: "Dark",
            characteristics: "Strong, rich flavors with higher nicotine content",
            details: "Leaves come from the top of the tobacco plant, receiving the most sunlight",
            category: .specialty
        ),
        CigarWrapper(
            name: "Seco",
            description: "Middle leaf tobacco",
            origin: "Various",
            color: "Medium brown",
            characteristics: "Mild to medium flavors with good combustion properties",
            details: "Harvested from the middle of the plant, balancing strength and burn quality",
            category: .specialty
        ),
        CigarWrapper(
            name: "Volado",
            description: "Bottom leaf tobacco",
            origin: "Various",
            color: "Light brown",
            characteristics: "Mild flavor, primarily used for its excellent burning qualities",
            details: "Leaves are from the bottom of the plant and are essential for construction",
            category: .specialty
        ),
        CigarWrapper(
            name: "Dark Air-Cured",
            description: "Air-cured dark tobacco",
            origin: "Various",
            color: "Dark brown",
            characteristics: "Rich, robust flavors with a natural sweetness",
            details: "Leaves are air-cured over longer periods, intensifying their flavors",
            category: .specialty
        ),
        CigarWrapper(
            name: "Florida Sun Grown (FSG)",
            description: "American sun-grown tobacco",
            origin: "Florida, USA",
            color: "Medium to dark brown",
            characteristics: "Earthy and spicy flavors with a unique aroma",
            details: "Reviving Florida's tobacco heritage, FSG offers a distinctive profile",
            category: .specialty
        ),
        CigarWrapper(
            name: "Burley",
            description: "American air-cured tobacco",
            origin: "USA, mainly Kentucky and Tennessee",
            color: "Light to medium brown",
            characteristics: "Mild to medium flavors with a nutty undertone",
            details: "Primarily used in pipe and cigarette tobacco; occasionally in cigars",
            category: .specialty
        ),
        CigarWrapper(
            name: "Piloto",
            description: "Dominican tobacco",
            origin: "Dominican Republic",
            color: "Medium brown",
            characteristics: "Rich flavors with a balance of strength and aroma",
            details: "Often used as filler but also as a wrapper in some blends",
            category: .specialty
        ),
        CigarWrapper(
            name: "Olor Dominicano",
            description: "Dominican wrapper leaf",
            origin: "Dominican Republic",
            color: "Light to medium brown",
            characteristics: "Mild, aromatic with a smooth profile",
            details: "Often used as a binder or filler but occasionally as a wrapper for its excellent combustion",
            category: .specialty
        ),
        CigarWrapper(
            name: "Dominican",
            description: "Traditional Dominican tobacco",
            origin: "Dominican Republic",
            color: "Varies from light to dark brown",
            characteristics: "Generally mild with smooth, creamy flavors",
            details: "The Dominican Republic is a leading producer of premium cigar tobacco",
            category: .specialty
        ),
        CigarWrapper(
            name: "Sumatra Seed Grown in Ecuador",
            description: "Ecuadorian Sumatra tobacco",
            origin: "Ecuador",
            color: "Light to medium brown",
            characteristics: "Rich flavors with a balance of sweetness and spice",
            details: "Ecuador's climate and volcanic soil enhance the tobacco's characteristics",
            category: .exotic
        )
    ]
    
    func searchWrappers(_ query: String) -> [CigarWrapper] {
        if query.isEmpty {
            return wrappers
        }
        return wrappers.filter { wrapper in
            wrapper.name.localizedCaseInsensitiveContains(query) ||
            wrapper.origin.localizedCaseInsensitiveContains(query) ||
            wrapper.characteristics.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getWrapper(_ name: String) -> CigarWrapper? {
        wrappers.first { wrapper in
            wrapper.name.localizedCaseInsensitiveContains(name)
        }
    }
    
    var wrappersByCategory: [WrapperCategory: [CigarWrapper]] {
        Dictionary(grouping: wrappers) { $0.category }
    }
} 