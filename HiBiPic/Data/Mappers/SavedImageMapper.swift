import Foundation

/// Bidirectional mapper between the persistence layer (`SavedImageRow`) and
/// the domain layer (`SavedImage`).
enum SavedImageMapper {

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    // MARK: - Row -> Domain

    static func toDomain(_ row: SavedImageRow) -> SavedImage {
        SavedImage(
            id: row.id,
            eventId: row.eventId,
            fileName: row.fileName,
            originalFileName: row.originalFileName,
            editRecipe: decodeEditRecipe(from: row.editRecipeJSON),
            createdAt: row.createdAt
        )
    }

    // MARK: - Domain -> Row

    static func toRow(_ image: SavedImage) -> SavedImageRow {
        SavedImageRow(
            id: image.id,
            eventId: image.eventId,
            fileName: image.fileName,
            originalFileName: image.originalFileName,
            editRecipeJSON: encodeEditRecipe(image.editRecipe),
            createdAt: image.createdAt
        )
    }

    private static func decodeEditRecipe(from json: String?) -> SavedImageEditRecipe? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? decoder.decode(SavedImageEditRecipe.self, from: data)
    }

    private static func encodeEditRecipe(_ recipe: SavedImageEditRecipe?) -> String? {
        guard let recipe,
              let data = try? encoder.encode(recipe),
              let json = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return json
    }
}
