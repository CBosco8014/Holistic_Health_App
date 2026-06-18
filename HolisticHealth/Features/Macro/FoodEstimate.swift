import Foundation

/// A Gemini-estimated single food (typed-food fallback and menu visualize).
struct ParsedFoodEstimate: Decodable, Hashable {
    var name: String
    var servingDescription: String
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var calories: Double
    var confidence: Double?
    var assumptions: String?

    var macros: MacroNutrients {
        MacroNutrients(proteinGrams: proteinGrams, carbGrams: carbGrams, fatGrams: fatGrams, calories: calories)
    }
}

/// A Gemini-estimated multi-item result (meal photo analysis).
struct ParsedMealEstimate: Decodable, Hashable {
    var items: [ParsedFoodEstimate]
}

/// A visualized dish (menu photo/screenshot/text) — a generated visual
/// description plus the macro estimate.
struct VisualizedFoodEstimate: Decodable, Hashable {
    var visualDescription: String
    var name: String
    var servingDescription: String
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
    var calories: Double
    var confidence: Double?
    var assumptions: String?

    var asFood: ParsedFoodEstimate {
        ParsedFoodEstimate(name: name, servingDescription: servingDescription,
                           proteinGrams: proteinGrams, carbGrams: carbGrams, fatGrams: fatGrams,
                           calories: calories, confidence: confidence, assumptions: assumptions)
    }
}

/// Response schemas for the food estimation features.
enum FoodEstimateSchema {
    static let foodProperties: [String: [String: Any]] = [
        "name": JSONSchema.string,
        "servingDescription": JSONSchema.string,
        "proteinGrams": JSONSchema.number,
        "carbGrams": JSONSchema.number,
        "fatGrams": JSONSchema.number,
        "calories": JSONSchema.number,
        "confidence": JSONSchema.number,
        "assumptions": JSONSchema.string
    ]

    static let required = ["name", "servingDescription", "proteinGrams", "carbGrams", "fatGrams", "calories"]

    /// Schema for a single estimated food.
    static var single: [String: Any] {
        JSONSchema.object(properties: foodProperties, required: required)
    }

    /// Schema for a meal of multiple estimated foods.
    static var meal: [String: Any] {
        JSONSchema.object(
            properties: ["items": JSONSchema.array(of: JSONSchema.object(properties: foodProperties, required: required))],
            required: ["items"]
        )
    }

    /// Schema for a visualized dish (adds a generated visual description).
    static var visualize: [String: Any] {
        var props = foodProperties
        props["visualDescription"] = JSONSchema.string
        return JSONSchema.object(properties: props, required: required + ["visualDescription"])
    }
}
