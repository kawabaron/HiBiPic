import SwiftUI

// MARK: - EventCreateScreen

/// Full-screen creation / editing form for events.
/// Scrollable single-page layout with a sticky save bar at the bottom.
struct EventCreateScreen: View {

    // MARK: - Properties

    @State private var viewModel: EventCreateViewModel
    @Environment(\.dismiss) private var dismiss

    /// Optional event to edit. Pass `nil` for creation mode.
    private let editingEvent: Event?

    // MARK: - Init

    init(event: Event? = nil, repository: EventRepositoryProtocol = EventRepositoryImpl()) {
        self.editingEvent = event
        self._viewModel = State(initialValue: EventCreateViewModel(repository: repository))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable form
            ScrollView {
                VStack(spacing: DSSpacing.xxl) {
                    eventNameSection
                    baseDateSection
                    countTypeSection
                    phraseTemplateSection
                    designTemplateSection
                    previewSection
                    pinToggleSection

                    // Bottom padding for sticky bar clearance
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.horizontal, DSSpacing.xl)
                .padding(.top, DSSpacing.lg)
            }

            // Sticky save bar
            saveBar
        }
        .background(DSColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                cancelButton
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.isEditing ? "イベントを編集" : "イベントを作成")
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.initialize(event: editingEvent)
        }
        .confirmationDialog(
            "変更を破棄しますか？",
            isPresented: $viewModel.showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("破棄", role: .destructive) {
                dismiss()
            }
            Button("編集を続ける", role: .cancel) {}
        }
        .dsToast($viewModel.toast)
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button {
            if viewModel.isDirty {
                viewModel.requestCancel()
            } else {
                dismiss()
            }
        } label: {
            Text("キャンセル")
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textSecondary)
        }
    }

    // MARK: - Event Name Section

    private var eventNameSection: some View {
        DSTextField(
            "イベント名",
            text: $viewModel.eventName,
            placeholder: "結婚式、出産予定日、禁煙開始...",
            maxLength: 50,
            error: viewModel.eventNameError
        )
    }

    // MARK: - Base Date Section

    private var baseDateSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("基準日")
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)

            DatePicker(
                "",
                selection: $viewModel.baseDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(DSColors.accent)
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(DSColors.border, lineWidth: 1)
            }
        }
    }

    // MARK: - Count Type Section

    private var countTypeSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("カウント方法")
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)

            DSSegmentedPicker(
                items: CountType.allCases,
                selection: Binding(
                    get: { viewModel.countType },
                    set: { viewModel.updateCountType($0) }
                ),
                label: { type in
                    switch type {
                    case .countdown: return "あと何日"
                    case .elapsed:   return "何日経過"
                    case .daycount:  return "何日目"
                    }
                }
            )
        }
    }

    // MARK: - Phrase Template Section

    private var phraseTemplateSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            PhraseTemplatePicker(
                templates: viewModel.availablePhraseTemplates,
                selectedTemplateId: viewModel.phraseTemplateId,
                isCustomMode: viewModel.customPhraseMode,
                eventName: viewModel.eventName,
                dayCount: viewModel.currentDayCount,
                onSelect: { template in
                    viewModel.selectPhraseTemplate(template)
                },
                onCustomTap: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.customPhraseMode = true
                    }
                }
            )

            // Custom phrase editor (shown when custom mode is active)
            if viewModel.customPhraseMode {
                CustomPhraseEditor(
                    layoutMode: $viewModel.layoutMode,
                    customSingleLine: $viewModel.customSingleLine,
                    customLine1: $viewModel.customLine1,
                    customLine2: $viewModel.customLine2,
                    eventName: viewModel.eventName,
                    dayCount: viewModel.currentDayCount
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Design Template Section

    private var designTemplateSection: some View {
        DesignTemplatePicker(
            selectedType: viewModel.designTemplateId,
            onSelect: { type in
                viewModel.updateDesignTemplate(type)
            }
        )
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        EventPreviewSection(
            previewText: viewModel.previewText,
            designTemplateType: viewModel.designTemplateId,
            layoutMode: viewModel.layoutMode
        )
    }

    // MARK: - Pin Toggle Section

    private var pinToggleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("ピン留め")
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)

                Text("ホーム画面の上部に固定されます")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $viewModel.isPinned)
                .tint(DSColors.accent)
                .labelsHidden()
        }
        .padding(DSSpacing.lg)
        .background(DSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .strokeBorder(DSColors.border, lineWidth: 1)
        }
    }

    // MARK: - Save Bar

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(DSColors.divider)

            DSButton(
                viewModel.isEditing ? "保存する" : "保存して使う",
                style: .primary,
                isLoading: $viewModel.isSaving
            ) {
                Task {
                    let success = await viewModel.save()
                    if success {
                        try? await Task.sleep(for: .seconds(0.5))
                        dismiss()
                    }
                }
            }
            .disabled(!viewModel.canSave)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.top, DSSpacing.md)
            .padding(.bottom, DSSpacing.xxl)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview("Create") {
    NavigationStack {
        EventCreateScreen()
    }
}

#Preview("Edit") {
    NavigationStack {
        EventCreateScreen(
            event: Event(
                name: "禁煙チャレンジ",
                baseDate: "2025-01-01",
                countType: .daycount,
                phraseTemplateId: "daycount_single_1",
                designTemplateId: .minimal,
                layoutMode: .single
            )
        )
    }
}
