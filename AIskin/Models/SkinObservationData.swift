import Foundation

/// Observation values shared by analysis mapping and report presentation.
struct BlackheadsData {
    var exists: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String? = nil
}

struct AcneData {
    var exists: Bool?
    var count: String?
    var types: [String]?
    var distribution: [String]?
    var severity: String? = nil
    var activity: String? = nil
    var description: String? = nil
}

struct PoresData {
    var enlarged: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String? = nil
}

struct SkinToneEvennessData {
    var score: Int?
    var description: String?
}

struct RednessData {
    var exists: Bool?
    var severity: String?
    var description: String?
    var distribution: [String]?
}

struct HyperpigmentationData {
    var exists: Bool?
    var severity: String?
    var description: String?
    var types: [String]?
    var distribution: [String]?
}

struct FineLinesData {
    var exists: Bool?
    var severity: String?
    var description: String?
    var distribution: [String]?
}

struct SensitivityData {
    var exists: Bool?
    var severity: String?
    var description: String?
    var signs: [String]?
}
