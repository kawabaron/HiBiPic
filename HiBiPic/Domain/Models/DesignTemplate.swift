import Foundation

// MARK: - TextAlignment

enum TextAlignment: String, CaseIterable {
    case left
    case center
    case right
}

// MARK: - DesignTemplate

struct DesignTemplate: Identifiable, Equatable {
    let id: DesignTemplateType
    let name: String
    let description: String
    let defaultLayoutMode: LayoutMode
    let textColor: String       // hex e.g. "#FFFFFF"
    let backgroundColor: String // hex e.g. "#000000"
    let fontWeight: FontWeight
    let fontSizeScale: CGFloat  // 1.0 = standard
    let alignment: TextAlignment
    let showBackground: Bool    // band behind text
    let numberEmphasis: Bool

    enum FontWeight: String {
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
    }
}

// MARK: - DesignTemplateStore

final class DesignTemplateStore {

    static let allTemplates: [DesignTemplate] = [
        // ── Minimal ──
        DesignTemplate(
            id: .minimal,
            name: "Minimal",
            description: "シンプルで洗練されたデザイン。白文字、背景バンドなし。",
            defaultLayoutMode: .single,
            textColor: "#FFFFFF",
            backgroundColor: "#00000000",  // transparent
            fontWeight: .thin,
            fontSizeScale: 1.0,
            alignment: .center,
            showBackground: false,
            numberEmphasis: false
        ),

        // ── Soft ──
        DesignTemplate(
            id: .soft,
            name: "Soft",
            description: "暖かみのある柔らかなデザイン。クリーム系テキスト、半透明バンド付き。",
            defaultLayoutMode: .double,
            textColor: "#FFF8F0",
            backgroundColor: "#FFFFFF33",  // semi-transparent white
            fontWeight: .regular,
            fontSizeScale: 1.0,
            alignment: .center,
            showBackground: true,
            numberEmphasis: true
        ),

        // ── Film ──
        DesignTemplate(
            id: .film,
            name: "Film",
            description: "フィルム写真のようなレトロなデザイン。オフホワイトテキスト、左寄せ。",
            defaultLayoutMode: .single,
            textColor: "#F5F0E8",
            backgroundColor: "#00000000",  // transparent
            fontWeight: .light,
            fontSizeScale: 1.0,
            alignment: .left,
            showBackground: false,
            numberEmphasis: false
        ),

        // ── Poster ──
        DesignTemplate(
            id: .poster,
            name: "Poster",
            description: "大胆でインパクトのあるポスター風デザイン。太字、大きな数字強調。",
            defaultLayoutMode: .double,
            textColor: "#FFFFFF",
            backgroundColor: "#000000AA",  // strong contrast band
            fontWeight: .bold,
            fontSizeScale: 1.4,
            alignment: .center,
            showBackground: true,
            numberEmphasis: true
        ),
    ]

    // MARK: - Query Methods

    static func template(for type: DesignTemplateType) -> DesignTemplate {
        allTemplates.first { $0.id == type } ?? allTemplates[0]
    }

    static func defaultTemplate() -> DesignTemplate {
        template(for: .minimal)
    }
}
