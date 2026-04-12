import Foundation

enum PlaceholderTextResolver {
    static func resolve(template: String, label: String, count: Int) -> String {
        let resolvedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.t("fallback.event.name") : label
        return template
            .replacingOccurrences(of: "{label}", with: resolvedLabel)
            .replacingOccurrences(of: "{n}", with: String(count))
    }
}

enum PhraseDisplayAdjuster {
    typealias ResolvedLines = (singleLine: String, line1: String, line2: String, line3: String)

    static func adjust(
        lines: ResolvedLines,
        label: String,
        count: Int,
        countType: CountType,
        designTemplateId: DesignTemplateType,
        phraseTemplateId: String
    ) -> ResolvedLines {
        guard countType == .countdown else { return lines }

        switch designTemplateId {
        case .milestone:
            guard phraseTemplateId == "countdown_triple_1" else { return lines }
            return (
                singleLine: lines.singleLine,
                line1: PlaceholderTextResolver.resolve(
                    template: L10n.t("{label}まであと"),
                    label: label,
                    count: count
                ),
                line2: String(count),
                line3: L10n.t("日")
            )
        case .soft, .diary, .cleanLabel:
            guard phraseTemplateId == "countdown_double_1" else { return lines }
            return (
                singleLine: lines.singleLine,
                line1: PlaceholderTextResolver.resolve(
                    template: L10n.t("{label}まで"),
                    label: label,
                    count: count
                ),
                line2: lines.line2,
                line3: lines.line3
            )
        default:
            return lines
        }
    }
}

// MARK: - PhraseTemplate

struct PhraseTemplate: Identifiable, Equatable {
    enum Source: String, Codable {
        case builtIn
        case userSaved
    }

    let id: String
    let countType: CountType
    let layoutMode: LayoutMode
    let label: String
    let previewSingleLine: String
    let previewLine1: String
    let previewLine2: String
    let previewLine3: String
    let singleLineTemplate: String
    let line1Template: String
    let line2Template: String
    let line3Template: String
    let isRecommended: Bool
    let source: Source

    var isUserSaved: Bool {
        source == .userSaved
    }

    init(
        id: String,
        countType: CountType,
        layoutMode: LayoutMode,
        label: String,
        previewSingleLine: String,
        previewLine1: String,
        previewLine2: String,
        previewLine3: String = "",
        singleLineTemplate: String,
        line1Template: String,
        line2Template: String,
        line3Template: String = "",
        isRecommended: Bool,
        source: Source = .builtIn
    ) {
        self.id = id
        self.countType = countType
        self.layoutMode = layoutMode
        self.label = label
        self.previewSingleLine = previewSingleLine
        self.previewLine1 = previewLine1
        self.previewLine2 = previewLine2
        self.previewLine3 = previewLine3
        self.singleLineTemplate = singleLineTemplate
        self.line1Template = line1Template
        self.line2Template = line2Template
        self.line3Template = line3Template
        self.isRecommended = isRecommended
        self.source = source
    }
}

struct SavedCustomPhraseTemplate: Identifiable, Codable, Equatable {
    let id: String
    let countType: CountType
    let layoutMode: LayoutMode
    let singleLineTemplate: String
    let line1Template: String
    let line2Template: String
    let line3Template: String
    let createdAt: String

    var title: String {
        let segments = [
            singleLineTemplate,
            line1Template,
            line2Template,
            line3Template,
        ]
        .map(\.trimmedTemplateValue)
        .filter { !$0.isEmpty }

        let joined = segments.joined(separator: " / ")
        guard !joined.isEmpty else {
            return L10n.t("保存した文言")
        }

        return joined.count > 22 ? "\(joined.prefix(22))…" : joined
    }

    var phraseTemplate: PhraseTemplate {
        PhraseTemplate(
            id: id,
            countType: countType,
            layoutMode: layoutMode,
            label: title,
            previewSingleLine: singleLineTemplate,
            previewLine1: line1Template,
            previewLine2: line2Template,
            previewLine3: line3Template,
            singleLineTemplate: singleLineTemplate,
            line1Template: line1Template,
            line2Template: line2Template,
            line3Template: line3Template,
            isRecommended: false,
            source: .userSaved
        )
    }

    func matches(
        countType: CountType,
        layoutMode: LayoutMode,
        singleLineTemplate: String,
        line1Template: String,
        line2Template: String,
        line3Template: String
    ) -> Bool {
        self.countType == countType
            && self.layoutMode == layoutMode
            && self.singleLineTemplate.trimmedTemplateValue == singleLineTemplate.trimmedTemplateValue
            && self.line1Template.trimmedTemplateValue == line1Template.trimmedTemplateValue
            && self.line2Template.trimmedTemplateValue == line2Template.trimmedTemplateValue
            && self.line3Template.trimmedTemplateValue == line3Template.trimmedTemplateValue
    }
}

// MARK: - PhraseTemplateStore

final class PhraseTemplateStore {

    // MARK: - All Templates

    static var allTemplates: [PhraseTemplate] {
        var templates: [PhraseTemplate] = []

        // ── Countdown Templates ──

        templates.append(PhraseTemplate(
            id: "countdown_single_1",
            countType: .countdown,
            layoutMode: .single,
            label: L10n.t("カウントダウン（まであと）"),
            previewSingleLine: L10n.t("誕生日まで あと30日"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label}まで あと{n}日"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_double_1",
            countType: .countdown,
            layoutMode: .double,
            label: L10n.t("カウントダウン（まで/あと）"),
            previewSingleLine: "",
            previewLine1: L10n.t("誕生日"),
            previewLine2: L10n.t("あと30日"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("あと{n}日"),
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_2",
            countType: .countdown,
            layoutMode: .single,
            label: L10n.t("カウントダウン（あと〜で）"),
            previewSingleLine: L10n.t("あと30日で 誕生日"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("あと{n}日で {label}"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_3",
            countType: .countdown,
            layoutMode: .single,
            label: L10n.t("カウントダウン（残り）"),
            previewSingleLine: L10n.t("誕生日まで 残り30日"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label}まで 残り{n}日"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_double_2",
            countType: .countdown,
            layoutMode: .double,
            label: L10n.t("カウントダウン（まで/残り）"),
            previewSingleLine: "",
            previewLine1: L10n.t("誕生日まで"),
            previewLine2: L10n.t("残り30日"),
            singleLineTemplate: "",
            line1Template: L10n.t("{label}まで"),
            line2Template: L10n.t("残り{n}日"),
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_triple_1",
            countType: .countdown,
            layoutMode: .double,
            label: L10n.t("カウントダウン（ラベル/あと/日数）"),
            previewSingleLine: "",
            previewLine1: L10n.t("誕生日"),
            previewLine2: L10n.t("あと"),
            previewLine3: L10n.t("30日"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("あと"),
            line3Template: L10n.t("{n}日"),
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_en_1",
            countType: .countdown,
            layoutMode: .single,
            label: L10n.t("Countdown (days to go)"),
            previewSingleLine: L10n.t("30 days to go for Birthday"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{n} days to go for {label}"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "countdown_single_en_2",
            countType: .countdown,
            layoutMode: .single,
            label: L10n.t("Countdown (until)"),
            previewSingleLine: L10n.t("until Birthday · 30 days to go"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("until {label} · {n} days to go"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        // ── Elapsed Templates ──

        templates.append(PhraseTemplate(
            id: "elapsed_single_1",
            countType: .elapsed,
            layoutMode: .single,
            label: L10n.t("経過（から〜経過）"),
            previewSingleLine: L10n.t("入社から 100日経過"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label}から {n}日経過"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_double_1",
            countType: .elapsed,
            layoutMode: .double,
            label: L10n.t("経過（ラベル/日数）"),
            previewSingleLine: "",
            previewLine1: L10n.t("入社"),
            previewLine2: L10n.t("100日"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("{n}日"),
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_2",
            countType: .elapsed,
            layoutMode: .single,
            label: L10n.t("経過（してから）"),
            previewSingleLine: L10n.t("入社してから 100日"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label}してから {n}日"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_3",
            countType: .elapsed,
            layoutMode: .single,
            label: L10n.t("経過（から〜日）"),
            previewSingleLine: L10n.t("入社から 100日"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label}から {n}日"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_double_2",
            countType: .elapsed,
            layoutMode: .double,
            label: L10n.t("経過（から/たちました）"),
            previewSingleLine: "",
            previewLine1: L10n.t("入社から"),
            previewLine2: L10n.t("100日たちました"),
            singleLineTemplate: "",
            line1Template: L10n.t("{label}から"),
            line2Template: L10n.t("{n}日たちました"),
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_triple_1",
            countType: .elapsed,
            layoutMode: .double,
            label: L10n.t("経過（ラベル/日数/経過）"),
            previewSingleLine: "",
            previewLine1: L10n.t("入社"),
            previewLine2: L10n.t("100日"),
            previewLine3: L10n.t("経過"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("{n}日"),
            line3Template: L10n.t("経過"),
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_en_1",
            countType: .elapsed,
            layoutMode: .single,
            label: L10n.t("Elapsed (days since)"),
            previewSingleLine: L10n.t("100 days since Joined"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{n} days since {label}"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "elapsed_single_en_2",
            countType: .elapsed,
            layoutMode: .single,
            label: L10n.t("Elapsed (since · Day)"),
            previewSingleLine: L10n.t("since Joined · Day 100"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("since {label} · Day {n}"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        // ── Daycount Templates ──

        templates.append(PhraseTemplate(
            id: "daycount_single_1",
            countType: .daycount,
            layoutMode: .single,
            label: L10n.t("日数カウント（〜日目）"),
            previewSingleLine: L10n.t("禁煙 30日目"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label} {n}日目"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_double_1",
            countType: .daycount,
            layoutMode: .double,
            label: L10n.t("日数カウント（ラベル/日目）"),
            previewSingleLine: "",
            previewLine1: L10n.t("禁煙"),
            previewLine2: L10n.t("30日目"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("{n}日目"),
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_en_1",
            countType: .daycount,
            layoutMode: .single,
            label: L10n.t("Daycount (Day N)"),
            previewSingleLine: L10n.t("No Smoking Day 30"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{label} Day {n}"),
            line1Template: "",
            line2Template: "",
            isRecommended: true
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_2",
            countType: .daycount,
            layoutMode: .single,
            label: L10n.t("日数カウント（日目の〜）"),
            previewSingleLine: L10n.t("30日目の 禁煙"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("{n}日目の {label}"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "daycount_single_en_2",
            countType: .daycount,
            layoutMode: .single,
            label: L10n.t("Daycount (Day N of)"),
            previewSingleLine: L10n.t("Day 30 of No Smoking"),
            previewLine1: "",
            previewLine2: "",
            singleLineTemplate: L10n.t("Day {n} of {label}"),
            line1Template: "",
            line2Template: "",
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "daycount_double_en_1",
            countType: .daycount,
            layoutMode: .double,
            label: L10n.t("Daycount (label/Day N)"),
            previewSingleLine: "",
            previewLine1: L10n.t("No Smoking"),
            previewLine2: L10n.t("Day 30"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: L10n.t("Day {n}"),
            isRecommended: false
        ))

        templates.append(PhraseTemplate(
            id: "daycount_triple_1",
            countType: .daycount,
            layoutMode: .double,
            label: L10n.t("日数カウント（ラベル/日数/日目）"),
            previewSingleLine: "",
            previewLine1: L10n.t("禁煙"),
            previewLine2: "30",
            previewLine3: L10n.t("日目"),
            singleLineTemplate: "",
            line1Template: "{label}",
            line2Template: "{n}",
            line3Template: L10n.t("日目"),
            isRecommended: false
        ))

        return templates
    }

    // MARK: - Query Methods

    static func templates(for countType: CountType) -> [PhraseTemplate] {
        allTemplates.filter { $0.countType == countType }
    }

    static func templates(
        for countType: CountType,
        userTemplates: [SavedCustomPhraseTemplate]
    ) -> [PhraseTemplate] {
        let builtInTemplates = templates(for: countType)
        let savedTemplates = userTemplates
            .filter { $0.countType == countType }
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.phraseTemplate)
        return builtInTemplates + savedTemplates
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

    func generateLines(
        template: PhraseTemplate,
        label: String,
        count: Int,
        layoutMode: LayoutMode
    ) -> (singleLine: String, line1: String, line2: String, line3: String) {
        let singleLine = PlaceholderTextResolver.resolve(
            template: template.singleLineTemplate,
            label: label,
            count: count
        )

        let line1 = PlaceholderTextResolver.resolve(
            template: template.line1Template,
            label: label,
            count: count
        )

        let line2 = PlaceholderTextResolver.resolve(
            template: template.line2Template,
            label: label,
            count: count
        )

        let line3 = PlaceholderTextResolver.resolve(
            template: template.line3Template,
            label: label,
            count: count
        )

        return (singleLine: singleLine, line1: line1, line2: line2, line3: line3)
    }

    func generateText(
        template: PhraseTemplate,
        label: String,
        count: Int,
        layoutMode: LayoutMode
    ) -> (singleLine: String, line1: String, line2: String) {
        let resolved = generateLines(
            template: template,
            label: label,
            count: count,
            layoutMode: layoutMode
        )
        return (
            singleLine: resolved.singleLine,
            line1: resolved.line1,
            line2: resolved.line2
        )
    }
}

private extension String {
    var trimmedTemplateValue: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
