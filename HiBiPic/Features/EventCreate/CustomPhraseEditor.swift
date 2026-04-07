import SwiftUI

// MARK: - CustomPhraseEditor

/// Editor for custom phrase input. Supports single-line and double-line modes.
/// The day count is shown as a non-editable preview so the user understands
/// how `{n}` and `{label}` will resolve.
struct CustomPhraseEditor: View {

    // MARK: - Properties

    @Binding var layoutMode: LayoutMode
    @Binding var customSingleLine: String
    @Binding var customLine1: String
    @Binding var customLine2: String

    let eventName: String
    let dayCount: Int

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            // Layout mode toggle
            layoutToggle

            // Input fields
            if layoutMode == .single {
                singleLineInput
            } else {
                doubleLineInput
            }

            // Hint text
            hintView
        }
        .padding(DSSpacing.lg)
        .background(DSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                .strokeBorder(DSColors.border, lineWidth: 1)
        }
    }

    // MARK: - Layout Toggle

    private var layoutToggle: some View {
        DSSegmentedPicker(
            items: LayoutMode.allCases,
            selection: $layoutMode,
            label: { mode in
                switch mode {
                case .single: return "1行"
                case .double: return "2行"
                }
            }
        )
    }

    // MARK: - Single Line Input

    private var singleLineInput: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            TextField("例: {label}から {n}日目", text: $customSingleLine)
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textPrimary)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.md)
                .background(DSColors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))

            // Live preview of resolved text
            if !customSingleLine.isEmpty {
                resolvedPreview(customSingleLine)
            }
        }
    }

    // MARK: - Double Line Input

    private var doubleLineInput: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("1行目")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)

                TextField("例: {label}", text: $customLine1)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.md)
                    .background(DSColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("2行目")
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textSecondary)

                TextField("例: {n}日目", text: $customLine2)
                    .font(DSTypography.body)
                    .foregroundStyle(DSColors.textPrimary)
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.vertical, DSSpacing.md)
                    .background(DSColors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
            }

            // Live preview of resolved text
            if !customLine1.isEmpty || !customLine2.isEmpty {
                VStack(spacing: DSSpacing.xxs) {
                    resolvedPreview(customLine1)
                    resolvedPreview(customLine2)
                }
            }
        }
    }

    // MARK: - Resolved Preview

    @ViewBuilder
    private func resolvedPreview(_ template: String) -> some View {
        let resolved = template
            .replacingOccurrences(of: "{n}", with: String(dayCount))
            .replacingOccurrences(of: "{label}", with: eventName.isEmpty ? "イベント" : eventName)

        if !resolved.isEmpty {
            HStack(spacing: DSSpacing.xs) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DSColors.textTertiary)

                Text(resolved)
                    .font(DSTypography.footnote)
                    .foregroundStyle(DSColors.accent)
            }
        }
    }

    // MARK: - Hint

    private var hintView: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            Text("使えるプレースホルダー:")
                .font(DSTypography.caption)
                .foregroundStyle(DSColors.textTertiary)

            HStack(spacing: DSSpacing.lg) {
                hintChip("{label}", description: "イベント名")
                hintChip("{n}", description: "日数")
            }
        }
    }

    private func hintChip(_ code: String, description: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Text(code)
                .font(DSTypography.caption.monospaced())
                .foregroundStyle(DSColors.accent)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.xxs)
                .background(DSColors.accentLight.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))

            Text(description)
                .font(DSTypography.caption)
                .foregroundStyle(DSColors.textTertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DSSpacing.xl) {
        CustomPhraseEditor(
            layoutMode: .constant(.single),
            customSingleLine: .constant("{label}から {n}日目"),
            customLine1: .constant(""),
            customLine2: .constant(""),
            eventName: "禁煙",
            dayCount: 30
        )

        CustomPhraseEditor(
            layoutMode: .constant(.double),
            customSingleLine: .constant(""),
            customLine1: .constant("{label}"),
            customLine2: .constant("{n}日目"),
            eventName: "禁煙",
            dayCount: 30
        )
    }
    .padding(DSSpacing.xl)
    .background(DSColors.background)
}
