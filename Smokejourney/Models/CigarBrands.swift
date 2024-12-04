import Foundation

struct CigarBrandLine: Identifiable {
    let id = UUID()
    let name: String
}

struct CigarBrand: Identifiable {
    let id = UUID()
    let name: String
    let lines: [CigarBrandLine]
    let description: String
    let country: String
}

class CigarBrands {
    static let shared = CigarBrands()
    
    let brands: [CigarBrand] = [
        CigarBrand(
            name: "ACID",
            lines: [
                CigarBrandLine(name: "20"),
                CigarBrandLine(name: "20 Connecticut"),
                CigarBrandLine(name: "Blondie"),
                CigarBrandLine(name: "Cigars"),
                CigarBrandLine(name: "Cigars by Drew Estate Opulence 3"),
                CigarBrandLine(name: "Kuba Kuba"),
                CigarBrandLine(name: "Ltd. Def Sea")
            ],
            description: "Infused premium cigars by Drew Estate",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "ADVentura",
            lines: [
                CigarBrandLine(name: "5-Packs"),
                CigarBrandLine(name: "Barbarroja's Invasion"),
                CigarBrandLine(name: "Blue Eyed Jack's Revenge"),
                CigarBrandLine(name: "La Llorona"),
                CigarBrandLine(name: "The Conqueror"),
                CigarBrandLine(name: "The Explorer"),
                CigarBrandLine(name: "The Navigator"),
                CigarBrandLine(name: "The Royal Return King's Gold"),
                CigarBrandLine(name: "The Royal Return Queen's Pearls")
            ],
            description: "Boutique brand with adventurous blends",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Aganorsa",
            lines: [
                CigarBrandLine(name: "JFR Connecticut"),
                CigarBrandLine(name: "JFR Corojo"),
                CigarBrandLine(name: "JFR Lunatic Corojo Torch"),
                CigarBrandLine(name: "JFR Lunatic Habano"),
                CigarBrandLine(name: "JFR Lunatic Loco"),
                CigarBrandLine(name: "JFR Lunatic Maduro"),
                CigarBrandLine(name: "JFR Maduro"),
                CigarBrandLine(name: "JFR XT Corojo"),
                CigarBrandLine(name: "JFR XT Maduro"),
                CigarBrandLine(name: "Leaf Aniversario"),
                CigarBrandLine(name: "Leaf Aniversario Maduro"),
                CigarBrandLine(name: "Leaf Anniversario Connecticut"),
                CigarBrandLine(name: "Leaf La Validacion Connecticut"),
                CigarBrandLine(name: "Leaf La Validacion Corojo"),
                CigarBrandLine(name: "Leaf La Validacion Habano"),
                CigarBrandLine(name: "Leaf La Validacion Maduro"),
                CigarBrandLine(name: "Leaf Signature Selection"),
                CigarBrandLine(name: "Overruns"),
                CigarBrandLine(name: "Rare Leaf"),
                CigarBrandLine(name: "Rare Leaf Maduro"),
                CigarBrandLine(name: "Signature Maduro")
            ],
            description: "Premium Nicaraguan tobacco producer",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Aging Room",
            lines: [
                CigarBrandLine(name: "Pura Cepa"),
                CigarBrandLine(name: "Quattro Connecticut"),
                CigarBrandLine(name: "Quattro Maduro"),
                CigarBrandLine(name: "Quattro Nicaragua"),
                CigarBrandLine(name: "Quattro Nicaragua Sonata"),
                CigarBrandLine(name: "Quattro Original")
            ],
            description: "Boutique brand known for small-batch production",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Alec Bradley",
            lines: [
                CigarBrandLine(name: "American Classic Blend"),
                CigarBrandLine(name: "American Sun Grown"),
                CigarBrandLine(name: "Black Market"),
                CigarBrandLine(name: "Black Market Esteli"),
                CigarBrandLine(name: "Black Market Illicit"),
                CigarBrandLine(name: "Black Market Vandal"),
                CigarBrandLine(name: "Black Market Vandal The Con"),
                CigarBrandLine(name: "Blind Faith"),
                CigarBrandLine(name: "Boy/Girl"),
                CigarBrandLine(name: "Caribbean Cask"),
                CigarBrandLine(name: "Cazadores"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Coyol"),
                CigarBrandLine(name: "Double Broadleaf"),
                CigarBrandLine(name: "Filthy Ghoolian"),
                CigarBrandLine(name: "Filthy Hooligan 2024"),
                CigarBrandLine(name: "Filthy Hooligan Shamrock 2024"),
                CigarBrandLine(name: "Gatekeeper"),
                CigarBrandLine(name: "Kintsugi"),
                CigarBrandLine(name: "Magic Toast"),
                CigarBrandLine(name: "MAXX"),
                CigarBrandLine(name: "Medalist"),
                CigarBrandLine(name: "Post Embargo Blend Code B15"),
                CigarBrandLine(name: "Prensado"),
                CigarBrandLine(name: "Prensado Fumas"),
                CigarBrandLine(name: "Prensado Lost Art"),
                CigarBrandLine(name: "Project 40"),
                CigarBrandLine(name: "Project 40 Maduro"),
                CigarBrandLine(name: "Puck"),
                CigarBrandLine(name: "Safe Keepings"),
                CigarBrandLine(name: "Select Connecticut"),
                CigarBrandLine(name: "Select Corojo"),
                CigarBrandLine(name: "Select Maduro"),
                CigarBrandLine(name: "Superstition"),
                CigarBrandLine(name: "Tempus"),
                CigarBrandLine(name: "Tempus Fumas"),
                CigarBrandLine(name: "Tempus Maduro"),
                CigarBrandLine(name: "Tempus Nicaragua"),
                CigarBrandLine(name: "Texas Lancero"),
                CigarBrandLine(name: "The Lineage"),
                CigarBrandLine(name: "Trilogy"),
                CigarBrandLine(name: "V2L Black"),
                CigarBrandLine(name: "White Gold")
            ],
            description: "Premium cigar manufacturer known for innovative blends",
            country: "Honduras"
        ),
        CigarBrand(
            name: "Aladino",
            lines: [
                CigarBrandLine(name: "Cameroon"),
                CigarBrandLine(name: "Candela"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Corojo"),
                CigarBrandLine(name: "Corojo Reserva"),
                CigarBrandLine(name: "Fuma Noche"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Sumatra"),
                CigarBrandLine(name: "Vintage")
            ],
            description: "Honduran brand focusing on traditional methods",
            country: "Honduras"
        ),
        CigarBrand(
            name: "Arturo Fuente",
            lines: [
                CigarBrandLine(name: "Chateau Fuente Series"),
                CigarBrandLine(name: "Chateau Fuente Series Sun Grown"),
                CigarBrandLine(name: "Don Carlos"),
                CigarBrandLine(name: "Gran Reserva"),
                CigarBrandLine(name: "Hemingway"),
                CigarBrandLine(name: "Hemingway Short Story")
            ],
            description: "Legendary Dominican cigar maker known for exceptional quality",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Ashton",
            lines: [
                CigarBrandLine(name: "Aged Maduro"),
                CigarBrandLine(name: "Cabinet Selection"),
                CigarBrandLine(name: "ESG"),
                CigarBrandLine(name: "Heritage Puro Sol"),
                CigarBrandLine(name: "Small Cigars"),
                CigarBrandLine(name: "Symmetry"),
                CigarBrandLine(name: "VSG")
            ],
            description: "Premium brand known for consistency and elegance",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Asylum",
            lines: [
                CigarBrandLine(name: "13"),
                CigarBrandLine(name: "13 Authentic Corojo"),
                CigarBrandLine(name: "13 Connecticut"),
                CigarBrandLine(name: "13 Cool Brew"),
                CigarBrandLine(name: "13 Medulla"),
                CigarBrandLine(name: "13 Medulla Maduro"),
                CigarBrandLine(name: "13 Oblongata"),
                CigarBrandLine(name: "13 Oblongata Maduro"),
                CigarBrandLine(name: "13 Ogre"),
                CigarBrandLine(name: "867 Auntie"),
                CigarBrandLine(name: "867 Midnight Oil"),
                CigarBrandLine(name: "867 Zero"),
                CigarBrandLine(name: "Insidious"),
                CigarBrandLine(name: "Insidious Maduro"),
                CigarBrandLine(name: "Nyctophilia")
            ],
            description: "Bold and innovative brand with unique blends",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "AVO",
            lines: [
                CigarBrandLine(name: "Classic"),
                CigarBrandLine(name: "Classic Maduro"),
                CigarBrandLine(name: "Heritage"),
                CigarBrandLine(name: "Syncro Caribe"),
                CigarBrandLine(name: "Syncro Nicaragua"),
                CigarBrandLine(name: "Syncro Nicaragua Fogata"),
                CigarBrandLine(name: "Syncro South America Ritmo"),
                CigarBrandLine(name: "XO")
            ],
            description: "Sophisticated blends with Dominican heritage",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Baccarat",
            lines: [
                CigarBrandLine(name: "Candela"),
                CigarBrandLine(name: "Nicaragua")
            ],
            description: "Known for mild, sweet-tipped cigars",
            country: "Honduras"
        ),
        CigarBrand(
            name: "Bahia",
            lines: [
                CigarBrandLine(name: "Blu"),
                CigarBrandLine(name: "Brazil"),
                CigarBrandLine(name: "Cafe"),
                CigarBrandLine(name: "Connecticut Deluxe"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Trinidad")
            ],
            description: "Brazilian tobacco specialist",
            country: "Brazil"
        ),
        CigarBrand(
            name: "Black Label Trading Co.",
            lines: [
                CigarBrandLine(name: "Bishop's Blend Novemdiales"),
                CigarBrandLine(name: "Bishop's Blend 2022"),
                CigarBrandLine(name: "Bishop's Blend 2024"),
                CigarBrandLine(name: "Last Rites"),
                CigarBrandLine(name: "Lawless"),
                CigarBrandLine(name: "Memento Mori"),
                CigarBrandLine(name: "Orthodox"),
                CigarBrandLine(name: "Porcelain"),
                CigarBrandLine(name: "Royalty"),
                CigarBrandLine(name: "Salvation")
            ],
            description: "Boutique brand known for bold blends",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Black Works Studio",
            lines: [
                CigarBrandLine(name: "Green Hornet"),
                CigarBrandLine(name: "Hyena"),
                CigarBrandLine(name: "Killer Bee"),
                CigarBrandLine(name: "Killer Bee Connecticut"),
                CigarBrandLine(name: "Rorschach"),
                CigarBrandLine(name: "Intergalactic Event Horizon")
            ],
            description: "Experimental boutique blends",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Bolivar",
            lines: [
                CigarBrandLine(name: "Cofradia"),
                CigarBrandLine(name: "Cofradia Oscuro"),
                CigarBrandLine(name: "Gran Republica")
            ],
            description: "Historic Cuban heritage brand",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Brick House",
            lines: [
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Fumas"),
                CigarBrandLine(name: "Fumas Connecticut"),
                CigarBrandLine(name: "Fumas Maduro"),
                CigarBrandLine(name: "Maduro")
            ],
            description: "Value-driven premium cigars",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Cain",
            lines: [
                CigarBrandLine(name: "Daytona"),
                CigarBrandLine(name: "F Nub"),
                CigarBrandLine(name: "Nub")
            ],
            description: "Full-bodied cigars by Oliva",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Caldwell",
            lines: [
                CigarBrandLine(name: "Anastasia"),
                CigarBrandLine(name: "Antoinette Culebra Lanceros"),
                CigarBrandLine(name: "Blind Man's Bluff"),
                CigarBrandLine(name: "Blind Man's Bluff Connecticut"),
                CigarBrandLine(name: "Blind Man's Bluff Maduro"),
                CigarBrandLine(name: "Blind Man's Bluff Nicaragua"),
                CigarBrandLine(name: "Collection - E.S. Midnight Express"),
                CigarBrandLine(name: "Collection - Long Live The King"),
                CigarBrandLine(name: "Collection - The King Is Dead"),
                CigarBrandLine(name: "Eastern Standard"),
                CigarBrandLine(name: "Eastern Standard Habano"),
                CigarBrandLine(name: "Essex"),
                CigarBrandLine(name: "Long Live the King Limited Bar-None"),
                CigarBrandLine(name: "Long Live the King Mad MoFo"),
                CigarBrandLine(name: "Long Live the Queen"),
                CigarBrandLine(name: "Long Live the Queen Maduro"),
                CigarBrandLine(name: "Lost and Found Series"),
                CigarBrandLine(name: "Louis The Last"),
                CigarBrandLine(name: "Montrose"),
                CigarBrandLine(name: "Savages"),
                CigarBrandLine(name: "The Industrialist"),
                CigarBrandLine(name: "The Last Tsar")
            ],
            description: "Boutique brand known for unique blends and creative marketing",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Camacho",
            lines: [
                CigarBrandLine(name: "Broadleaf"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Corojo"),
                CigarBrandLine(name: "Coyolar"),
                CigarBrandLine(name: "Ecuador"),
                CigarBrandLine(name: "Factory Unleashed 3"),
                CigarBrandLine(name: "Nicaragua"),
                CigarBrandLine(name: "Pre-Embargo"),
                CigarBrandLine(name: "Scorpion Fumas Connecticut"),
                CigarBrandLine(name: "Scorpion Fumas Sun Grown"),
                CigarBrandLine(name: "Scorpion Sun Grown"),
                CigarBrandLine(name: "Triple Maduro")
            ],
            description: "Bold and flavorful Honduran cigars",
            country: "Honduras"
        ),
        CigarBrand(
            name: "CAO",
            lines: [
                CigarBrandLine(name: "America"),
                CigarBrandLine(name: "Arcana Firewalker"),
                CigarBrandLine(name: "Arcana Thunder Smoke"),
                CigarBrandLine(name: "Black"),
                CigarBrandLine(name: "Bones"),
                CigarBrandLine(name: "Brazilia"),
                CigarBrandLine(name: "BX3"),
                CigarBrandLine(name: "Colombia"),
                CigarBrandLine(name: "Consigliere"),
                CigarBrandLine(name: "Expedicion 2020"),
                CigarBrandLine(name: "Extreme"),
                CigarBrandLine(name: "Flathead"),
                CigarBrandLine(name: "Flathead Steel Horse"),
                CigarBrandLine(name: "Flathead V23"),
                CigarBrandLine(name: "Flavours Series"),
                CigarBrandLine(name: "Gold"),
                CigarBrandLine(name: "Gold Maduro"),
                CigarBrandLine(name: "Italia"),
                CigarBrandLine(name: "L'Anniversaire Cameroon"),
                CigarBrandLine(name: "L'Anniversaire Maduro"),
                CigarBrandLine(name: "Mortal Coil"),
                CigarBrandLine(name: "Mx2"),
                CigarBrandLine(name: "Nicaragua"),
                CigarBrandLine(name: "Pilon"),
                CigarBrandLine(name: "Pilon Anejo"),
                CigarBrandLine(name: "Session"),
                CigarBrandLine(name: "Zocalo")
            ],
            description: "Known for innovative blends and unique presentations",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Cohiba",
            lines: [
                CigarBrandLine(name: "Black"),
                CigarBrandLine(name: "Blue"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Macassar"),
                CigarBrandLine(name: "Nicaragua"),
                CigarBrandLine(name: "Pequenos"),
                CigarBrandLine(name: "Puro Dominicana"),
                CigarBrandLine(name: "Red Dot"),
                CigarBrandLine(name: "Riviera"),
                CigarBrandLine(name: "Royale"),
                CigarBrandLine(name: "WELLER® 2024")
            ],
            description: "Luxury brand with Cuban heritage",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Crowned Heads",
            lines: [
                CigarBrandLine(name: "Azul y Oro"),
                CigarBrandLine(name: "Blood Medicine 2024"),
                CigarBrandLine(name: "Coroneta Habano"),
                CigarBrandLine(name: "Coroneta Maduro"),
                CigarBrandLine(name: "Four Kicks"),
                CigarBrandLine(name: "Four Kicks Capa Especial"),
                CigarBrandLine(name: "Four Kicks Maduro"),
                CigarBrandLine(name: "Four Kicks Mule Kick LE 2023"),
                CigarBrandLine(name: "J Juarez"),
                CigarBrandLine(name: "J.D. Howard Reserve"),
                CigarBrandLine(name: "Jericho Hill"),
                CigarBrandLine(name: "La Imperiosa"),
                CigarBrandLine(name: "Las Calaveras Edicion Limitada 2023"),
                CigarBrandLine(name: "Le Careme"),
                CigarBrandLine(name: "Le Patissier"),
                CigarBrandLine(name: "Mil Dias"),
                CigarBrandLine(name: "Mil Dias Maduro"),
                CigarBrandLine(name: "Mil Dias Marranitos Edición Limitada 2023")
            ],
            description: "Boutique brand known for limited editions",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Davidoff",
            lines: [
                CigarBrandLine(name: "Aniversario Series"),
                CigarBrandLine(name: "Anniversario No. 1 LE 2023"),
                CigarBrandLine(name: "Cigarillos"),
                CigarBrandLine(name: "Colorado Claro"),
                CigarBrandLine(name: "Escurio"),
                CigarBrandLine(name: "Grand Cru"),
                CigarBrandLine(name: "Millennium"),
                CigarBrandLine(name: "Nicaragua"),
                CigarBrandLine(name: "Primeros"),
                CigarBrandLine(name: "Royal"),
                CigarBrandLine(name: "Signature Series"),
                CigarBrandLine(name: "Special Series"),
                CigarBrandLine(name: "Winston Churchill"),
                CigarBrandLine(name: "Winston Churchill The Late Hour"),
                CigarBrandLine(name: "Yamasa")
            ],
            description: "Ultra-premium Swiss brand known for exceptional quality",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Diesel",
            lines: [
                CigarBrandLine(name: "d.10th"),
                CigarBrandLine(name: "Disciple"),
                CigarBrandLine(name: "Esteli Puro"),
                CigarBrandLine(name: "Fool's Errand Simple Fool"),
                CigarBrandLine(name: "Heart of Darkness"),
                CigarBrandLine(name: "Rage"),
                CigarBrandLine(name: "Uncut"),
                CigarBrandLine(name: "Uncut d.CT"),
                CigarBrandLine(name: "Unlimited"),
                CigarBrandLine(name: "Unlimited Maduro"),
                CigarBrandLine(name: "Vintage Series Maduro"),
                CigarBrandLine(name: "Vintage Series Natural"),
                CigarBrandLine(name: "Whiskey Row"),
                CigarBrandLine(name: "Whiskey Row Founder's Collection"),
                CigarBrandLine(name: "Whiskey Row Founders Collection Mizunara"),
                CigarBrandLine(name: "Whiskey Row Sherry Cask"),
                CigarBrandLine(name: "Wicked"),
                CigarBrandLine(name: "Wicked Witches Brew")
            ],
            description: "Full-bodied cigars with bold flavors",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Don Pepin Garcia",
            lines: [
                CigarBrandLine(name: "Blue"),
                CigarBrandLine(name: "Cuban Classic"),
                CigarBrandLine(name: "Series JJ"),
                CigarBrandLine(name: "Vegas Cubanas")
            ],
            description: "Master blender known for traditional Cuban style",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Drew Estate",
            lines: [
                CigarBrandLine(name: "20 Acre Farm"),
                CigarBrandLine(name: "Blackened M81"),
                CigarBrandLine(name: "Blackened S84 Shade to Black"),
                CigarBrandLine(name: "Chateau Real Series"),
                CigarBrandLine(name: "Cigars"),
                CigarBrandLine(name: "Deadwood Series"),
                CigarBrandLine(name: "Factory Smokes Series"),
                CigarBrandLine(name: "Freestyle Live Kit"),
                CigarBrandLine(name: "Herrera Esteli Series"),
                CigarBrandLine(name: "Isla del Sol Series"),
                CigarBrandLine(name: "Kentucky Fire Cured Series"),
                CigarBrandLine(name: "Liga Privada Series"),
                CigarBrandLine(name: "MUWAT Series"),
                CigarBrandLine(name: "Nica Rustica Broadleaf"),
                CigarBrandLine(name: "Tabak Especial Series"),
                CigarBrandLine(name: "Undercrown Series")
            ],
            description: "Innovative manufacturer known for Liga Privada and infused cigars",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Dunbarton Tobacco & Trust",
            lines: [
                CigarBrandLine(name: "Mi Querida Series"),
                CigarBrandLine(name: "Muestra de Saka Series"),
                CigarBrandLine(name: "Polpetta"),
                CigarBrandLine(name: "Red Meat Lovers"),
                CigarBrandLine(name: "Sin Compromiso"),
                CigarBrandLine(name: "Sobremesa Series"),
                CigarBrandLine(name: "Stillwell Star Series"),
                CigarBrandLine(name: "Umbagog")
            ],
            description: "Boutique brand by Steve Saka",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "E.P. Carrillo",
            lines: [
                CigarBrandLine(name: "Allegiance"),
                CigarBrandLine(name: "Encore"),
                CigarBrandLine(name: "Essence Series"),
                CigarBrandLine(name: "INCH Series"),
                CigarBrandLine(name: "La Historia"),
                CigarBrandLine(name: "New Wave"),
                CigarBrandLine(name: "Pledge"),
                CigarBrandLine(name: "Short Run 2023")
            ],
            description: "Premium brand by master blender Ernesto Perez-Carrillo",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Eiroa",
            lines: [
                CigarBrandLine(name: "CBT Maduro"),
                CigarBrandLine(name: "Jamastran"),
                CigarBrandLine(name: "The First 20 Years"),
                CigarBrandLine(name: "The First 20 Years Colorado")
            ],
            description: "Premium Honduran brand by Christian Eiroa",
            country: "Honduras"
        ),
        CigarBrand(
            name: "Espinosa",
            lines: [
                CigarBrandLine(name: "10 Years Anniversary"),
                CigarBrandLine(name: "601 La Bomba Warhead X"),
                CigarBrandLine(name: "Comfortably Numb Series"),
                CigarBrandLine(name: "Crema"),
                CigarBrandLine(name: "Habano"),
                CigarBrandLine(name: "Knuckle Sandwich Series"),
                CigarBrandLine(name: "Laranja Reserva Series"),
                CigarBrandLine(name: "Las 6 Provincias Series"),
                CigarBrandLine(name: "Murcielago")
            ],
            description: "Boutique brand known for bold blends",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Foundation Cigar Company",
            lines: [
                CigarBrandLine(name: "Aksum Series"),
                CigarBrandLine(name: "Charter Oak Series"),
                CigarBrandLine(name: "El Gueguense"),
                CigarBrandLine(name: "Highclere Castle Series"),
                CigarBrandLine(name: "Olmec Series"),
                CigarBrandLine(name: "The Tabernacle Series"),
                CigarBrandLine(name: "Wise Man Series")
            ],
            description: "Boutique brand by Nicholas Melillo",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Fratello",
            lines: [
                CigarBrandLine(name: "Arlequin Series"),
                CigarBrandLine(name: "Classico"),
                CigarBrandLine(name: "Navetta Series"),
                CigarBrandLine(name: "Oro"),
                CigarBrandLine(name: "Sorella")
            ],
            description: "Boutique brand with Italian heritage",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "God of Fire",
            lines: [
                CigarBrandLine(name: "by Carlito"),
                CigarBrandLine(name: "by Don Carlos"),
                CigarBrandLine(name: "Sencillo Black"),
                CigarBrandLine(name: "Sencillo Platinum"),
                CigarBrandLine(name: "Serie Aniversario"),
                CigarBrandLine(name: "Serie B")
            ],
            description: "Ultra-premium brand by Arturo Fuente",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Gran Habano",
            lines: [
                CigarBrandLine(name: "#1 Connecticut"),
                CigarBrandLine(name: "#3 Habano"),
                CigarBrandLine(name: "#5 Corojo"),
                CigarBrandLine(name: "#5 Corojo Maduro"),
                CigarBrandLine(name: "Minis"),
                CigarBrandLine(name: "Vintage Series")
            ],
            description: "Family-owned brand known for value",
            country: "Honduras"
        ),
        CigarBrand(
            name: "Joya de Nicaragua",
            lines: [
                CigarBrandLine(name: "Antano 1970"),
                CigarBrandLine(name: "Antano Connecticut"),
                CigarBrandLine(name: "Antano Dark Corojo"),
                CigarBrandLine(name: "Antano Gran Reserva"),
                CigarBrandLine(name: "Black"),
                CigarBrandLine(name: "Cabinetta"),
                CigarBrandLine(name: "Cinco de Cinco"),
                CigarBrandLine(name: "Cuatro Cinco"),
                CigarBrandLine(name: "JOYA Red"),
                CigarBrandLine(name: "Numero Uno"),
                CigarBrandLine(name: "Silver")
            ],
            description: "Nicaragua's oldest premium cigar manufacturer",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Kristoff",
            lines: [
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Criollo"),
                CigarBrandLine(name: "GC Signature Series"),
                CigarBrandLine(name: "Kristania"),
                CigarBrandLine(name: "Kristania Maduro"),
                CigarBrandLine(name: "Ligero Maduro"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "San Andres"),
                CigarBrandLine(name: "Sumatra"),
                CigarBrandLine(name: "Tres Compadres"),
                CigarBrandLine(name: "Twentieth Anniversary")
            ],
            description: "Boutique brand known for unique box-pressed designs",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "La Aroma de Cuba",
            lines: [
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Edicion Especial"),
                CigarBrandLine(name: "Mi Amor"),
                CigarBrandLine(name: "Noblesse"),
                CigarBrandLine(name: "Pasion"),
                CigarBrandLine(name: "Reserva")
            ],
            description: "Classic Cuban heritage brand made in Nicaragua",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "La Aurora",
            lines: [
                CigarBrandLine(name: "107"),
                CigarBrandLine(name: "107 Maduro"),
                CigarBrandLine(name: "107 Nicaragua"),
                CigarBrandLine(name: "115 Robusto"),
                CigarBrandLine(name: "1495 Series"),
                CigarBrandLine(name: "1985 Maduro"),
                CigarBrandLine(name: "1987 Connecticut"),
                CigarBrandLine(name: "Preferidos Series"),
                CigarBrandLine(name: "Principes")
            ],
            description: "Dominican Republic's oldest cigar factory",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "La Flor Dominicana",
            lines: [
                CigarBrandLine(name: "1994"),
                CigarBrandLine(name: "Air Bender"),
                CigarBrandLine(name: "Andalusian Bull"),
                CigarBrandLine(name: "Cameroon Cabinet"),
                CigarBrandLine(name: "Coronado"),
                CigarBrandLine(name: "Double Claro"),
                CigarBrandLine(name: "Double Ligero"),
                CigarBrandLine(name: "Double Ligero Maduro"),
                CigarBrandLine(name: "La Volcada"),
                CigarBrandLine(name: "Ligero"),
                CigarBrandLine(name: "Ligero Cabinet"),
                CigarBrandLine(name: "Reserva Especial")
            ],
            description: "Known for strong, full-bodied cigars",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "La Gloria Cubana",
            lines: [
                CigarBrandLine(name: "Criollo De Oro"),
                CigarBrandLine(name: "Esteli"),
                CigarBrandLine(name: "Gran Legado"),
                CigarBrandLine(name: "Medio Tiempo"),
                CigarBrandLine(name: "Serie R"),
                CigarBrandLine(name: "Serie R Black"),
                CigarBrandLine(name: "Serie R Black Maduro"),
                CigarBrandLine(name: "Serie R Esteli"),
                CigarBrandLine(name: "Serie R Esteli Maduro"),
                CigarBrandLine(name: "Serie S"),
                CigarBrandLine(name: "Serie S Maduro"),
                CigarBrandLine(name: "Spanish Press"),
                CigarBrandLine(name: "Spirit of the Lady")
            ],
            description: "Historic Cuban brand now made in Dominican Republic",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "La Palina",
            lines: [
                CigarBrandLine(name: "125 Anos"),
                CigarBrandLine(name: "1948"),
                CigarBrandLine(name: "Black Label"),
                CigarBrandLine(name: "Blue Label"),
                CigarBrandLine(name: "Bronze Label"),
                CigarBrandLine(name: "Classic Series"),
                CigarBrandLine(name: "El Diario"),
                CigarBrandLine(name: "Fuego Verde"),
                CigarBrandLine(name: "Goldie"),
                CigarBrandLine(name: "KB Series"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Nicaragua Series"),
                CigarBrandLine(name: "Red Label"),
                CigarBrandLine(name: "White Label")
            ],
            description: "Luxury brand with pre-revolution Cuban heritage",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Macanudo",
            lines: [
                CigarBrandLine(name: "1968"),
                CigarBrandLine(name: "Ascots"),
                CigarBrandLine(name: "Cafe"),
                CigarBrandLine(name: "Cru Royale"),
                CigarBrandLine(name: "Emissary"),
                CigarBrandLine(name: "Gold Label"),
                CigarBrandLine(name: "Inspirado Series"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Vintage Series")
            ],
            description: "Known for mild, consistent cigars",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Man O' War",
            lines: [
                CigarBrandLine(name: "Abomination"),
                CigarBrandLine(name: "Armada"),
                CigarBrandLine(name: "Damnation"),
                CigarBrandLine(name: "Dark Aged Maduro"),
                CigarBrandLine(name: "Dark Horse"),
                CigarBrandLine(name: "Puro Authentico"),
                CigarBrandLine(name: "Ruination"),
                CigarBrandLine(name: "Ruination 10th Anniversary"),
                CigarBrandLine(name: "Side Projects"),
                CigarBrandLine(name: "Valkyrie"),
                CigarBrandLine(name: "Virtue"),
                CigarBrandLine(name: "Virtue 10th Anniversary")
            ],
            description: "Bold, full-bodied cigars with warrior theme",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Montecristo",
            lines: [
                CigarBrandLine(name: "1935 Anniversary Series"),
                CigarBrandLine(name: "Classic"),
                CigarBrandLine(name: "Crafted By AJ Fernandez"),
                CigarBrandLine(name: "Epic"),
                CigarBrandLine(name: "Epic Vintage 12"),
                CigarBrandLine(name: "Espada"),
                CigarBrandLine(name: "Espada Oscuro"),
                CigarBrandLine(name: "Media Noche"),
                CigarBrandLine(name: "Memories (Cigarillos)"),
                CigarBrandLine(name: "Monte"),
                CigarBrandLine(name: "Nicaragua"),
                CigarBrandLine(name: "Original"),
                CigarBrandLine(name: "Perlado"),
                CigarBrandLine(name: "Platinum"),
                CigarBrandLine(name: "Viejo")
            ],
            description: "Legendary Cuban heritage brand",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "My Father",
            lines: [
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "El Centurion"),
                CigarBrandLine(name: "Flor de Las Antillas"),
                CigarBrandLine(name: "Fonseca"),
                CigarBrandLine(name: "Fonseca Edicion San Andres"),
                CigarBrandLine(name: "Jaime Garcia Series"),
                CigarBrandLine(name: "La Antiguedad"),
                CigarBrandLine(name: "La Gran Oferta"),
                CigarBrandLine(name: "La Opulencia"),
                CigarBrandLine(name: "La Promesa"),
                CigarBrandLine(name: "Le Bijou 1922"),
                CigarBrandLine(name: "The Judge")
            ],
            description: "Premium Nicaraguan brand by the Garcia family",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Nica Libre",
            lines: [
                CigarBrandLine(name: "Aganorsa"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Estopilla"),
                CigarBrandLine(name: "Oliva"),
                CigarBrandLine(name: "Silver 25th Anniversary"),
                CigarBrandLine(name: "Sun Grown")
            ],
            description: "Value-driven Nicaraguan cigars",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Nub",
            lines: [
                CigarBrandLine(name: "Cain FF"),
                CigarBrandLine(name: "Cameroon"),
                CigarBrandLine(name: "Connecticut"),
                CigarBrandLine(name: "Double Maduro"),
                CigarBrandLine(name: "Habano"),
                CigarBrandLine(name: "Habano Sun Grown Double Perfecto"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Nuance"),
                CigarBrandLine(name: "Sumatra")
            ],
            description: "Short, thick cigars by Oliva",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Oliva",
            lines: [
                CigarBrandLine(name: "Connecticut Reserve"),
                CigarBrandLine(name: "Flor de Oliva"),
                CigarBrandLine(name: "Master Blends 3"),
                CigarBrandLine(name: "Melanio CI 25th Anniversary"),
                CigarBrandLine(name: "Saison"),
                CigarBrandLine(name: "Saison Maduro"),
                CigarBrandLine(name: "Serie G"),
                CigarBrandLine(name: "Serie G Maduro"),
                CigarBrandLine(name: "Serie O"),
                CigarBrandLine(name: "Serie O Maduro"),
                CigarBrandLine(name: "Serie V"),
                CigarBrandLine(name: "Serie V 135th Anniversary Edicion Limitada"),
                CigarBrandLine(name: "Serie V Maduro"),
                CigarBrandLine(name: "Serie V Melanio"),
                CigarBrandLine(name: "Serie V Melanio Edicion Ano 2023 Figurino"),
                CigarBrandLine(name: "Serie V Melanio Edicion Ano 2024"),
                CigarBrandLine(name: "Serie V Melanio Maduro"),
                CigarBrandLine(name: "Serie V Nub")
            ],
            description: "Premium Nicaraguan manufacturer known for Serie V",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Padron",
            lines: [
                CigarBrandLine(name: "1926 Series 40th Anniversary"),
                CigarBrandLine(name: "1926 Series 80th Anniversary"),
                CigarBrandLine(name: "1926 Series Maduro"),
                CigarBrandLine(name: "1926 Series Natural"),
                CigarBrandLine(name: "1926 Series No. 90"),
                CigarBrandLine(name: "1964 Anniversary Series Maduro"),
                CigarBrandLine(name: "1964 Anniversary Series Natural"),
                CigarBrandLine(name: "Damaso"),
                CigarBrandLine(name: "Family Reserve"),
                CigarBrandLine(name: "Maduro"),
                CigarBrandLine(name: "Natural")
            ],
            description: "Ultra-premium Nicaraguan brand known for consistency",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Partagas",
            lines: [
                CigarBrandLine(name: "1845 Series"),
                CigarBrandLine(name: "Anejo"),
                CigarBrandLine(name: "Black Label"),
                CigarBrandLine(name: "Cifuentes"),
                CigarBrandLine(name: "Cortado"),
                CigarBrandLine(name: "de Bronce"),
                CigarBrandLine(name: "Heritage"),
                CigarBrandLine(name: "Legend"),
                CigarBrandLine(name: "Valle Verde")
            ],
            description: "Historic Cuban brand now made in Dominican Republic",
            country: "Dominican Republic"
        ),
        CigarBrand(
            name: "Perdomo",
            lines: [
                CigarBrandLine(name: "20th Anniversary Series"),
                CigarBrandLine(name: "30th Anniversary Series"),
                CigarBrandLine(name: "Double Aged 12 Year Vintage Series"),
                CigarBrandLine(name: "Fresco"),
                CigarBrandLine(name: "Fresh-Rolled Cuban Wheels"),
                CigarBrandLine(name: "Habano Bourbon Barrel-Aged Series"),
                CigarBrandLine(name: "Inmenso Seventy Series"),
                CigarBrandLine(name: "Lot 23 Series"),
                CigarBrandLine(name: "Reserve 10th Anniversary Series"),
                CigarBrandLine(name: "Slow-Aged Lot 826 Series")
            ],
            description: "Family-owned Nicaraguan manufacturer",
            country: "Nicaragua"
        ),
        CigarBrand(
            name: "Plasencia",
            lines: [
                CigarBrandLine(name: "1865 Alma Fuerte"),
                CigarBrandLine(name: "1865 Alma Fuerte Colorado"),
                CigarBrandLine(name: "Alma del Campo"),
                CigarBrandLine(name: "Alma del Fuego"),
                CigarBrandLine(name: "Alma del Fuego Ometepe"),
                CigarBrandLine(name: "Cosecha 149"),
                CigarBrandLine(name: "Cosecha 151"),
                CigarBrandLine(name: "Reserva Original"),
                CigarBrandLine(name: "Year of the Dragon")
            ],
            description: "Premium tobacco grower and cigar manufacturer",
            country: "Nicaragua"
        )
        // Continue with more brands...
    ]
    
    func searchBrands(_ query: String) -> [CigarBrand] {
        if query.isEmpty {
            return brands
        }
        return brands.filter { brand in
            brand.name.localizedCaseInsensitiveContains(query) ||
            brand.country.localizedCaseInsensitiveContains(query) ||
            brand.lines.contains { line in
                line.name.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func getBrand(_ name: String) -> CigarBrand? {
        brands.first { brand in
            brand.name.localizedCaseInsensitiveContains(name)
        }
    }
    
    func getLines(for brand: String) -> [CigarBrandLine] {
        guard let brand = getBrand(brand) else { return [] }
        return brand.lines
    }
} 