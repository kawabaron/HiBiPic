import Foundation

struct AppSettings {
    var defaultDesignTemplateId: DesignTemplateType
    var defaultCountType: CountType
    var defaultLayoutMode: LayoutMode
    var showShareAfterSave: Bool
    var languageMode: String
    var updatedAt: String

    static let defaults = AppSettings(
        defaultDesignTemplateId: .minimal,
        defaultCountType: .elapsed,
        defaultLayoutMode: .single,
        showShareAfterSave: true,
        languageMode: "ja",
        updatedAt: ISO8601DateFormatter().string(from: Date())
    )
}
