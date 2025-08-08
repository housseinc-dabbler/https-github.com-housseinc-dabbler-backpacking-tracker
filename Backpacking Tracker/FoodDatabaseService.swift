// FoodDatabaseService.swift
import Foundation

// MARK: - USDA API Response Models
struct FoodSearchResponse: Codable {
    let foods: [FoundFood]
}

struct FoundFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [FoodNutrient]
}

struct FoodNutrient: Codable {
    let nutrientName: String
    let value: Double
    let unitName: String
}

// MARK: - Service
class FoodDatabaseService {
    
    private let baseURL = "https://api.nal.usda.gov/fdc/v1/foods/search"
    
    func search(for query: String) async throws -> [FoodItem] {
        // Read the API key from UserDefaults
        guard let apiKey = UserDefaults.standard.string(forKey: "usdaApiKey"), !apiKey.isEmpty else {
            print("⚠️ ERROR: USDA API Key is missing from UserDefaults.")
            throw URLError(.userAuthenticationRequired)
        }
        
        guard var components = URLComponents(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "dataType", value: "Branded,Foundation,SR Legacy")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let response = try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        
        return response.foods.map { food in
            // Helper function to find a nutrient value
            func nutrientValue(for name: String) -> Double {
                food.foodNutrients.first { $0.nutrientName.contains(name) }?.value ?? 0.0
            }
            
            // CORRECTED: Initializer no longer includes 'mealType'
            return FoodItem(
                name: food.description,
                weightInGrams: 100, // Standard reference is per 100g
                calories: nutrientValue(for: "Energy"),
                fat: nutrientValue(for: "Total lipid (fat)"),
                carbs: nutrientValue(for: "Carbohydrate, by difference"),
                protein: nutrientValue(for: "Protein")
            )
        }
    }
}
