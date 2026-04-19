import Foundation

// Verified against Apple Support "Identify your Mac..." pages and local macOS
// CoreTypes model bundles on April 19, 2026.
struct AppleSiliconMacDefinition: Hashable {
    let modelIdentifier: String
    let marketingName: String
    let chipFamilyName: String
}

enum AppleSiliconMacCatalog {
    static let entries: [AppleSiliconMacDefinition] = [
        .init(modelIdentifier: "MacBookAir10,1", marketingName: "MacBook Air (M1, 2020)", chipFamilyName: "Apple M1"),
        .init(modelIdentifier: "Mac14,2", marketingName: "MacBook Air (M2, 2022)", chipFamilyName: "Apple M2"),
        .init(modelIdentifier: "Mac14,15", marketingName: "MacBook Air (15-inch, M2, 2023)", chipFamilyName: "Apple M2"),
        .init(modelIdentifier: "Mac15,12", marketingName: "MacBook Air (13-inch, M3, 2024)", chipFamilyName: "Apple M3"),
        .init(modelIdentifier: "Mac15,13", marketingName: "MacBook Air (15-inch, M3, 2024)", chipFamilyName: "Apple M3"),
        .init(modelIdentifier: "Mac16,12", marketingName: "MacBook Air (13-inch, M4, 2025)", chipFamilyName: "Apple M4"),
        .init(modelIdentifier: "Mac16,13", marketingName: "MacBook Air (15-inch, M4, 2025)", chipFamilyName: "Apple M4"),
        .init(modelIdentifier: "Mac17,3", marketingName: "MacBook Air (13-inch, M5, 2026)", chipFamilyName: "Apple M5"),
        .init(modelIdentifier: "Mac17,4", marketingName: "MacBook Air (15-inch, M5, 2026)", chipFamilyName: "Apple M5"),

        .init(modelIdentifier: "MacBookPro17,1", marketingName: "MacBook Pro (13-inch, M1, 2020)", chipFamilyName: "Apple M1"),
        .init(modelIdentifier: "MacBookPro18,3", marketingName: "MacBook Pro (14-inch, 2021)", chipFamilyName: "Apple M1 Pro / M1 Max"),
        .init(modelIdentifier: "MacBookPro18,4", marketingName: "MacBook Pro (14-inch, 2021)", chipFamilyName: "Apple M1 Pro / M1 Max"),
        .init(modelIdentifier: "MacBookPro18,1", marketingName: "MacBook Pro (16-inch, 2021)", chipFamilyName: "Apple M1 Pro / M1 Max"),
        .init(modelIdentifier: "MacBookPro18,2", marketingName: "MacBook Pro (16-inch, 2021)", chipFamilyName: "Apple M1 Pro / M1 Max"),
        .init(modelIdentifier: "Mac14,7", marketingName: "MacBook Pro (13-inch, M2, 2022)", chipFamilyName: "Apple M2"),
        .init(modelIdentifier: "Mac14,5", marketingName: "MacBook Pro (14-inch, 2023)", chipFamilyName: "Apple M2 Pro / M2 Max"),
        .init(modelIdentifier: "Mac14,9", marketingName: "MacBook Pro (14-inch, 2023)", chipFamilyName: "Apple M2 Pro / M2 Max"),
        .init(modelIdentifier: "Mac14,6", marketingName: "MacBook Pro (16-inch, 2023)", chipFamilyName: "Apple M2 Pro / M2 Max"),
        .init(modelIdentifier: "Mac14,10", marketingName: "MacBook Pro (16-inch, 2023)", chipFamilyName: "Apple M2 Pro / M2 Max"),
        .init(modelIdentifier: "Mac15,3", marketingName: "MacBook Pro (14-inch, Nov 2023)", chipFamilyName: "Apple M3"),
        .init(modelIdentifier: "Mac15,6", marketingName: "MacBook Pro (14-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac15,8", marketingName: "MacBook Pro (14-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac15,10", marketingName: "MacBook Pro (14-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac15,7", marketingName: "MacBook Pro (16-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac15,9", marketingName: "MacBook Pro (16-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac15,11", marketingName: "MacBook Pro (16-inch, Nov 2023)", chipFamilyName: "Apple M3 Pro / M3 Max"),
        .init(modelIdentifier: "Mac16,1", marketingName: "MacBook Pro (14-inch, 2024)", chipFamilyName: "Apple M4"),
        .init(modelIdentifier: "Mac16,6", marketingName: "MacBook Pro (14-inch, 2024)", chipFamilyName: "Apple M4 Pro / M4 Max"),
        .init(modelIdentifier: "Mac16,8", marketingName: "MacBook Pro (14-inch, 2024)", chipFamilyName: "Apple M4 Pro / M4 Max"),
        .init(modelIdentifier: "Mac16,7", marketingName: "MacBook Pro (16-inch, 2024)", chipFamilyName: "Apple M4 Pro / M4 Max"),
        .init(modelIdentifier: "Mac16,5", marketingName: "MacBook Pro (16-inch, 2024)", chipFamilyName: "Apple M4 Pro / M4 Max"),
        .init(modelIdentifier: "Mac17,2", marketingName: "MacBook Pro (14-inch, M5, 2025)", chipFamilyName: "Apple M5"),
        .init(modelIdentifier: "Mac17,7", marketingName: "MacBook Pro (14-inch, M5 Pro or M5 Max, 2026)", chipFamilyName: "Apple M5 Pro / M5 Max"),
        .init(modelIdentifier: "Mac17,9", marketingName: "MacBook Pro (14-inch, M5 Pro or M5 Max, 2026)", chipFamilyName: "Apple M5 Pro / M5 Max"),
        .init(modelIdentifier: "Mac17,6", marketingName: "MacBook Pro (16-inch, M5 Pro or M5 Max, 2026)", chipFamilyName: "Apple M5 Pro / M5 Max"),
        .init(modelIdentifier: "Mac17,8", marketingName: "MacBook Pro (16-inch, M5 Pro or M5 Max, 2026)", chipFamilyName: "Apple M5 Pro / M5 Max"),

        .init(modelIdentifier: "Macmini9,1", marketingName: "Mac mini (M1, 2020)", chipFamilyName: "Apple M1"),
        .init(modelIdentifier: "Mac14,3", marketingName: "Mac mini (2023)", chipFamilyName: "Apple M2"),
        .init(modelIdentifier: "Mac14,12", marketingName: "Mac mini (2023)", chipFamilyName: "Apple M2 Pro"),
        .init(modelIdentifier: "Mac16,10", marketingName: "Mac mini (2024)", chipFamilyName: "Apple M4 / M4 Pro"),
        .init(modelIdentifier: "Mac16,11", marketingName: "Mac mini (2024)", chipFamilyName: "Apple M4 / M4 Pro"),

        .init(modelIdentifier: "iMac21,1", marketingName: "iMac (24-inch, M1, 2021)", chipFamilyName: "Apple M1"),
        .init(modelIdentifier: "iMac21,2", marketingName: "iMac (24-inch, M1, 2021)", chipFamilyName: "Apple M1"),
        .init(modelIdentifier: "Mac15,4", marketingName: "iMac (24-inch, 2023, Two ports)", chipFamilyName: "Apple M3"),
        .init(modelIdentifier: "Mac15,5", marketingName: "iMac (24-inch, 2023, Four ports)", chipFamilyName: "Apple M3"),
        .init(modelIdentifier: "Mac16,2", marketingName: "iMac (24-inch, 2024, Two ports)", chipFamilyName: "Apple M4"),
        .init(modelIdentifier: "Mac16,3", marketingName: "iMac (24-inch, 2024, Four ports)", chipFamilyName: "Apple M4"),

        .init(modelIdentifier: "Mac13,1", marketingName: "Mac Studio (2022)", chipFamilyName: "Apple M1 Max"),
        .init(modelIdentifier: "Mac13,2", marketingName: "Mac Studio (2022)", chipFamilyName: "Apple M1 Ultra"),
        .init(modelIdentifier: "Mac14,13", marketingName: "Mac Studio (2023)", chipFamilyName: "Apple M2 Max"),
        .init(modelIdentifier: "Mac14,14", marketingName: "Mac Studio (2023)", chipFamilyName: "Apple M2 Ultra"),
        .init(modelIdentifier: "Mac16,9", marketingName: "Mac Studio (2025)", chipFamilyName: "Apple M4 Max"),
        .init(modelIdentifier: "Mac15,14", marketingName: "Mac Studio (2025)", chipFamilyName: "Apple M3 Ultra"),

        .init(modelIdentifier: "Mac14,8", marketingName: "Mac Pro (2023)", chipFamilyName: "Apple M2 Ultra"),
    ]

    static func entry(for modelIdentifier: String) -> AppleSiliconMacDefinition? {
        entries.first { $0.modelIdentifier == modelIdentifier }
    }
}
