import Foundation

// MARK: - PhraseTemplate

struct PhraseTemplate: Identifiable, Equatable {
    let id: String
    let countType: CountType
    let layoutMode: LayoutMode
    let label: String
    let previewSingleLine: String
    let previewLine1: String
    let previewLine2: String
    let singleLineTemplate: String
    let line1Template: String
    let line2Template: String
    let isRecommended: Bool
}

// MARK: - PhraseTemplateStore

final class PhraseTemplateStore {

    // MARK: - All Templates

    static let allTemplates: [PhraseTemplate] = {
        var templates: [PhraseTemplate] = []

        // ── Countdown Templates ──

        templates.append(PhraseTemplate(
            id: "countdown_single_1",
            countType: .countdown,
            layoutMode: .single,
            label: "カウントダウン（まであと）",
            previewSingleLine: "誕生日まで あと30日",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label}まで あと{n}日",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_double_1",
            countType: .countdown,
            layoutMode: .double,
            label: "カウントダウン（まで/あと）",
            previewSingleLine: "",
            previewLine1: "誕生日",
            previewLine2: "あと30日",
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: "あと{n}日",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_2",
            countType: .countdown,
            layoutMode: .single,
            label: "カウントダウン（あと〜で）",
            previewSingleLine: "あと30日で 誕生日",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "あと{n}日で {label}",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_3",
            countType: .countdown,
            layoutMode: .single,
            label: "カウントダウン（残り）",
            previewSingleLine: "誕生日まで 残り30日",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label}まで 残り{n}日",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_double_2",
            countType: .countdown,
            layoutMode: .double,
            label: "カウントダウン（まで/残り）",
            previewSingleLine: "",
            previewLine1: "誕生日まで",
            previewLine2: "残り30日",
            singleLineTemplate: "",
            line1Template: "{label}まで",
            line2Template: "残り{n}日",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_en_1",
            countType: .countdown,
            layoutMode: .single,
            label: "Countdown (days to go)",
            previewSingleLine: "30 days to go for Birthday",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{n} days to go for {label}",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_en_2",
            countType: .countdown,
            layoutMode: .single,
            label: "Countdown (until)",
            previewSingleLine: "until Birthday · 30 days to go",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "until {label} · {n} days to go",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        // ── Elapsed Templates ──

        templates.append(PhraseTemplate(
            id: "elapsed_single_1",
            countType: .elapsed,
            layoutMode: .single,
            label: "経過（から〜経過）",
            previewSingleLine: "入社から 100日経過",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label}から {n}日経過",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_double_1",
            countType: .elapsed,
            layoutMode: .double,
            label: "経過（ラベル/日数）",
            previewSingleLine: "",
            previewLine1: "入社",
            previewLine2: "100日",
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: "{n}日",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_2",
            countType: .elapsed,
            layoutMode: .single,
            label: "経過（してから）",
            previewSingleLine: "入社してから 100日",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label}してから {n}日",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_3",
            countType: .elapsed,
            layoutMode: .single,
            label: "経過（から〜日）",
            previewSingleLine: "入社から 100日",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label}から {n}日",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_double_2",
            countType: .elapsed,
            layoutMode: .double,
            label: "経過（から/たちました）",
            previewSingleLine: "",
            previewLine1: "入社から",
            previewLine2: "100日たちました",
            singleLineTemplate: "",
            line1Template: "{label}から",
            line2Template: "{n}日たちました",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_en_1",
            countType: .elapsed,
            layoutMode: .single,
            label: "Elapsed (days since)",
            previewSingleLine: "100 days since Joined",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{n} days since {label}",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_en_2",
            countType: .elapsed,
            layoutMode: .single,
            label: "Elapsed (since · Day)",
            previewSingleLine: "since Joined · Day 100",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "since {label} · Day {n}",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        // ── Daycount Templates ──

        templates.append(PhraseTemplate(
            id: "daycount_single_1",
            countType: .daycount,
            layoutMode: .single,
            label: "日数カウント（〜日目）",
            previewSingleLine: "禁煙 30日目",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label} {n}日目",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_double_1",
            countType: .daycount,
            layoutMode: .double,
            label: "日数カウント（ラベル/日目）",
            previewSingleLine: "",
            previewLine1: "禁煙",
            previewLine2: "30日目",
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: "{n}日目",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_en_1",
            countType: .daycount,
            layoutMode: .single,
            label: "Daycount (Day N)",
            previewSingleLine: "No Smoking Day 30",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{label} Day {n}",
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_2",
            countType: .daycount,
            layoutMode: .single,
            label: "日数カウント（日目の〜）",
            previewSingleLine: "30日目の 禁煙",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "{n}日目の {label}",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_en_2",
            countType: .daycount,
            layoutMode: .single,
            label: "Daycount (Day N of)",
            previewSingleLine: "Day 30 of No Smoking",
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: "Day {n} of {label}",
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "daycount_double_en_1",
            countType: .daycount,
            layoutMode: .double,
            label: "Daycount (label/Day N)",
            previewSingleLine: "",
            previewLine1: "No Smoking",
            previewLine2: "Day 30",
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: "Day {n}",
            isRecommended: false
        ))

        return templates
    }()

    // MARK: - Query Methods

    static func templates(for countType: CountType) -> [PhraseTemplate] {
        allTemplates.filter { $0.countType == countType }
    }

    static func recommendedTemplates(for countType: CountType) -> [PhraseTemplate] {
        allTemplates.filter { $0.countType == countType && $0.isRecommended }
    }

    static func defaultTemplate(for countType: CountType) -> PhraseTemplate {
        guard let template = recommendedTemplates(for: countType).first else {
            // Fallback: return the first template for this count type
            return templates(for: countType).first!
        }
        return template
    }

    // MARK: - Text Generation

    func generateText(
        template: PhraseTemplate,
        label: String,
        count: Int,
        layoutMode: LayoutMode
    ) -> (singleLine: String, line1: String, line2: String) {
        let n = String(count)

        let singleLine = template.singleLineTemplate
            .replacingOccurrences(of: "{label}", with: label)
            .replacingOccurrences(of: "{n}", with: n)

        let line1 = template.line1Template
            .replacingOccurrences(of: "{label}", with: label)
            .replacingOccurrences(of: "{n}", with: n)

        let line2 = template.line2Template
            .replacingOccurrences(of: "{label}", with: label)
            .replacingOccurrences(of: "{n}", with: n)

        return (singleLine: singleLine, line1: line1, line2: line2)
    }
}
