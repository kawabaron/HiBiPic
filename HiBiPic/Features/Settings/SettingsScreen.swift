import SwiftUI

// MARK: - SettingsScreen

struct SettingsScreen: View {

    @Binding var appearanceMode: AppAppearanceMode
    @Binding var languageMode: AppLanguage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let settingsRepository: SettingsRepositoryProtocol

    init(
        appearanceMode: Binding<AppAppearanceMode>,
        languageMode: Binding<AppLanguage>,
        settingsRepository: SettingsRepositoryProtocol = AppDependencies.shared.settingsRepository
    ) {
        self._appearanceMode = appearanceMode
        self._languageMode = languageMode
        self.settingsRepository = settingsRepository
    }

    var body: some View {
        ZStack {
            DSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.xl) {
                    appearanceSection
                    languageSection
                    supportSection
                }
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.lg)
                .padding(.bottom, DSSpacing.massive)
            }
        }
        .navigationTitle(L10n.t("設定"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.t("閉じる")) {
                    dismiss()
                }
            }
        }
        .onChange(of: appearanceMode) { _, newValue in
            persistAppearanceMode(newValue)
        }
        .onChange(of: languageMode) { _, newValue in
            persistLanguageMode(newValue)
        }
    }

    private var appearanceSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                sectionHeader(
                    title: "外観",
                    description: "端末設定に合わせるか、アプリだけライト・ダークに固定できます。",
                    systemImage: "circle.lefthalf.filled"
                )

                DSSegmentedPicker(
                    items: AppAppearanceMode.allCases,
                    selection: $appearanceMode,
                    label: { $0.displayLabel }
                )
            }
        }
    }

    private var supportSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                sectionHeader(
                    title: "サポート",
                    description: "利用規約やプライバシー情報の確認、お問い合わせはこちらから開けます。",
                    systemImage: "link"
                )

                ForEach(SettingsLinkItem.allCases) { item in
                    supportRow(for: item)
                }
            }
        }
    }

    private var languageSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                sectionHeader(
                    title: "言語",
                    description: "日付などの地域表記と、アプリ内表示に使う言語を選べます。",
                    systemImage: "globe"
                )

                VStack(spacing: DSSpacing.sm) {
                    ForEach(AppLanguage.allCases) { language in
                        languageRow(for: language)
                    }
                }
            }
        }
    }

    private func sectionHeader(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack(spacing: DSSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DSColors.accent)

                Text(L10n.t(title))
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)
            }

            Text(L10n.t(description))
                .font(DSTypography.subheadline)
                .foregroundStyle(DSColors.textSecondary)
        }
    }

    private func supportRow(for item: SettingsLinkItem) -> some View {
        let url = configuredURL(forKey: item.infoPlistKey)

        return Button {
            guard let url else { return }
            openURL(url)
        } label: {
            HStack(spacing: DSSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .fill(DSColors.accentLight.opacity(0.22))
                        .frame(width: 42, height: 42)

                    Image(systemName: item.systemImage)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DSColors.accent)
                }

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(item.title)
                        .font(DSTypography.body)
                        .foregroundStyle(DSColors.textPrimary)

                    Text(url == nil ? L10n.t("リンク先はまだ準備中です") : item.description)
                        .font(DSTypography.footnote)
                        .foregroundStyle(DSColors.textSecondary)
                }

                Spacer(minLength: DSSpacing.sm)

                Image(systemName: url == nil ? "clock" : "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(url == nil ? DSColors.textTertiary : DSColors.accent)
            }
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(DSColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(url == nil)
        .opacity(url == nil ? 0.72 : 1.0)
    }

    private func languageRow(for language: AppLanguage) -> some View {
        let isSelected = languageMode == language

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                languageMode = language
            }
        } label: {
            HStack(spacing: DSSpacing.md) {
                Text(language.badgeLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? DSColors.buttonPrimaryText : DSColors.accent)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? DSColors.accent : DSColors.accentLight.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))

                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                    Text(language.displayLabel)
                        .font(DSTypography.body)
                        .foregroundStyle(DSColors.textPrimary)

                    Text("\(language.nativeLabel) · \(language.rawValue)")
                        .font(DSTypography.footnote)
                        .foregroundStyle(DSColors.textSecondary)
                }

                Spacer(minLength: DSSpacing.sm)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? DSColors.accent : DSColors.textTertiary.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(DSSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(isSelected ? DSColors.accentLight.opacity(0.16) : DSColors.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                    .strokeBorder(isSelected ? DSColors.accent : DSColors.border, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(language.displayLabel)、\(language.nativeLabel)"))
        .accessibilityValue(Text(isSelected ? L10n.t("選択中") : L10n.t("未選択")))
    }

    private func settingsCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(DSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .strokeBorder(DSColors.border, lineWidth: 1)
        }
        .dsShadow(.card)
    }

    private func configuredURL(forKey key: String) -> URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        return URL(string: trimmedValue)
    }

    private func persistAppearanceMode(_ mode: AppAppearanceMode) {
        do {
            var settings = try settingsRepository.load()
            settings.appearanceMode = mode
            try settingsRepository.save(settings)
        } catch {
            // Appearance is already applied locally via binding; persistence failure
            // should not block the user from using the screen.
        }
    }

    private func persistLanguageMode(_ language: AppLanguage) {
        do {
            var settings = try settingsRepository.load()
            settings.languageMode = language
            try settingsRepository.save(settings)
        } catch {
            // The selection is still applied for this app session via binding.
            // If persistence fails, keeping the UI responsive is the safer path.
        }
    }
}

private enum SettingsLinkItem: String, CaseIterable, Identifiable {
    case termsOfService
    case contact
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .termsOfService:
            return L10n.t("利用規約")
        case .contact:
            return L10n.t("お問い合わせ")
        case .privacyPolicy:
            return L10n.t("プライバシーポリシー")
        }
    }

    var description: String {
        switch self {
        case .termsOfService:
            return L10n.t("ご利用条件をブラウザで確認できます")
        case .contact:
            return L10n.t("不具合やご要望の連絡先を開きます")
        case .privacyPolicy:
            return L10n.t("個人情報の取り扱い方針を確認できます")
        }
    }

    var systemImage: String {
        switch self {
        case .termsOfService:
            return "doc.text"
        case .contact:
            return "envelope"
        case .privacyPolicy:
            return "hand.raised"
        }
    }

    var infoPlistKey: String {
        switch self {
        case .termsOfService:
            return "HiBiPicTermsOfServiceURL"
        case .contact:
            return "HiBiPicContactURL"
        case .privacyPolicy:
            return "HiBiPicPrivacyPolicyURL"
        }
    }
}
