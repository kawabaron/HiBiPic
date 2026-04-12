import Foundation
import Observation

// MARK: - EventCreateViewModel

@Observable
final class EventCreateViewModel {

    // MARK: - Form State

    var eventName: String = "" {
        didSet {
            isDirty = true
            if eventNameError != nil { eventNameError = nil }
        }
    }

    var baseDate: Date = Date() {
        didSet { isDirty = true }
    }

    var countType: CountType = .elapsed

    var phraseTemplateId: String = ""

    var designTemplateId: DesignTemplateType = .minimal

    var fontPreset: FontPreset = .standard {
        didSet { isDirty = true }
    }

    var layoutMode: LayoutMode = .single

    var customPhraseMode: Bool = false {
        didSet { isDirty = true }
    }

    var customSingleLine: String = "" {
        didSet { isDirty = true }
    }

    var customLine1: String = "" {
        didSet { isDirty = true }
    }

    var customLine2: String = "" {
        didSet { isDirty = true }
    }

    var isPinned: Bool = false {
        didSet { isDirty = true }
    }

    // MARK: - UI State

    var isSaving: Bool = false
    var isDirty: Bool = false
    var showCancelConfirm: Bool = false
    var toast: DSToastItem?

    // MARK: - Validation

    var eventNameError: String?

    // MARK: - Editing Mode

    var editingEvent: Event?

    var isEditing: Bool { editingEvent != nil }

    // MARK: - Computed

    var canSave: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var currentDayCount: Int {
        let dateString = DateCalculator.stringFromDate(baseDate)
        return DateCalculator.calculateDays(baseDate: dateString, countType: countType)
    }

    var previewText: (singleLine: String, line1: String, line2: String) {
        let label = eventName.isEmpty ? L10n.t("fallback.preview.name") : eventName
        let n = currentDayCount

        if customPhraseMode {
            let single = customSingleLine
                .replacingOccurrences(of: "{n}", with: String(n))
                .replacingOccurrences(of: "{label}", with: label)
            let l1 = customLine1
                .replacingOccurrences(of: "{n}", with: String(n))
                .replacingOccurrences(of: "{label}", with: label)
            let l2 = customLine2
                .replacingOccurrences(of: "{n}", with: String(n))
                .replacingOccurrences(of: "{label}", with: label)
            return (singleLine: single, line1: l1, line2: l2)
        }

        guard let template = currentPhraseTemplate else {
            let countText = LocalizedDayCountFormatter.string(days: n, countType: countType, showsTodayForZeroCountdown: false)
            return (
                singleLine: "\(label) \(countText)",
                line1: label,
                line2: countText
            )
        }

        let store = PhraseTemplateStore()
        return store.generateText(template: template, label: label, count: n, layoutMode: layoutMode)
    }

    var availablePhraseTemplates: [PhraseTemplate] {
        PhraseTemplateStore.templates(for: countType)
    }

    // MARK: - Private

    private let repository: EventRepositoryProtocol

    private var currentPhraseTemplate: PhraseTemplate? {
        PhraseTemplateStore.allTemplates.first { $0.id == phraseTemplateId }
    }

    // MARK: - Init

    init(repository: EventRepositoryProtocol = EventRepositoryImpl()) {
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load from an existing event for editing, or set sensible defaults for creation.
    func initialize(event: Event?) {
        if let event {
            editingEvent = event
            eventName = event.name
            baseDate = DateCalculator.baseDateFromString(event.baseDate) ?? Date()
            countType = event.countType
            phraseTemplateId = event.phraseTemplateId
            designTemplateId = event.designTemplateId
            fontPreset = event.fontPreset
            layoutMode = event.layoutMode
            customPhraseMode = event.customPhraseMode
            customSingleLine = event.customSingleLine ?? ""
            customLine1 = event.customLine1 ?? ""
            customLine2 = event.customLine2 ?? ""
            isPinned = event.isPinned
        } else {
            // Defaults for new event
            let design = DesignTemplateStore.template(for: designTemplateId)
            let defaultTemplate = design.defaultPhraseTemplate(for: countType)
            fontPreset = design.defaultFontPreset
            phraseTemplateId = defaultTemplate.id
            layoutMode = defaultTemplate.layoutMode
        }

        isDirty = false
    }

    /// Update count type and reset phrase template to the recommended default for the new type.
    func updateCountType(_ type: CountType) {
        guard type != countType else { return }
        countType = type
        isDirty = true

        if !customPhraseMode {
            let design = DesignTemplateStore.template(for: designTemplateId)
            let defaultTemplate = design.defaultPhraseTemplate(for: type)
            phraseTemplateId = defaultTemplate.id
            layoutMode = defaultTemplate.layoutMode
        }
    }

    /// Update design template and adjust layout mode to the template's default.
    func updateDesignTemplate(_ type: DesignTemplateType) {
        guard type != designTemplateId else { return }
        designTemplateId = type
        isDirty = true

        let design = DesignTemplateStore.template(for: type)
        fontPreset = design.defaultFontPreset

        // Re-select a phrase template matching the new layout mode if not custom
        if !customPhraseMode {
            let template = design.defaultPhraseTemplate(for: countType)
            phraseTemplateId = template.id
            layoutMode = template.layoutMode
        } else {
            layoutMode = design.defaultLayoutMode
        }
    }

    /// Select a specific phrase template.
    func selectPhraseTemplate(_ template: PhraseTemplate) {
        customPhraseMode = false
        phraseTemplateId = template.id
        layoutMode = template.layoutMode
        isDirty = true
    }

    /// Validate form fields. Returns `true` if valid.
    @discardableResult
    func validate() -> Bool {
        let trimmed = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            eventNameError = L10n.t("イベント名を入力してください")
            return false
        }
        eventNameError = nil
        return true
    }

    /// Persist the event. Returns `true` on success.
    func save() async -> Bool {
        guard validate() else { return false }

        isSaving = true
        defer { isSaving = false }

        let dateString = DateCalculator.stringFromDate(baseDate)

        do {
            if let existing = editingEvent {
                // Update
                var updated = existing
                updated.name = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
                updated.baseDate = dateString
                updated.countType = countType
                updated.phraseTemplateId = phraseTemplateId
                updated.designTemplateId = designTemplateId
                updated.fontPreset = fontPreset
                updated.layoutMode = layoutMode
                updated.customPhraseMode = customPhraseMode
                updated.customSingleLine = customPhraseMode ? customSingleLine : nil
                updated.customLine1 = customPhraseMode ? customLine1 : nil
                updated.customLine2 = customPhraseMode ? customLine2 : nil
                updated.isPinned = isPinned
                updated.updatedAt = ISO8601DateFormatter().string(from: Date())
                try repository.update(updated)
            } else {
                // Create
                let event = Event(
                    name: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
                    baseDate: dateString,
                    countType: countType,
                    phraseTemplateId: phraseTemplateId,
                    designTemplateId: designTemplateId,
                    fontPreset: fontPreset,
                    layoutMode: layoutMode,
                    customPhraseMode: customPhraseMode,
                    customSingleLine: customPhraseMode ? customSingleLine : nil,
                    customLine1: customPhraseMode ? customLine1 : nil,
                    customLine2: customPhraseMode ? customLine2 : nil,
                    isPinned: isPinned
                )
                try repository.create(event)
            }

            toast = .success(isEditing ? L10n.t("イベントを更新しました") : L10n.t("イベントを作成しました"))
            isDirty = false
            return true

        } catch {
            toast = .error(L10n.t("保存に失敗しました。もう一度お試しください。"))
            return false
        }
    }

    /// Request cancellation. Shows confirmation dialog if form is dirty.
    func requestCancel() {
        if isDirty {
            showCancelConfirm = true
        }
        // If not dirty, caller should dismiss directly
    }
}
