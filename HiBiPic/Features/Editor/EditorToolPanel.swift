import SwiftUI

// MARK: - EditorToolPanel

/// The expandable bottom panel that shows controls for the currently selected edit tool.
/// Slides up from the bottom with an animation when an edit tool is active.
struct EditorToolPanel: View {

    // MARK: - Properties

    @Bindable var viewModel: EditorViewModel

    // MARK: - Body

    var body: some View {
        if viewModel.activeEditTool != .none {
            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, DSSpacing.sm)
                    .padding(.bottom, DSSpacing.md)

                // Panel content
                panelContent
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerLg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Panel Content Router

    @ViewBuilder
    private var panelContent: some View {
        switch viewModel.activeEditTool {
        case .none:
            EmptyView()
        case .template:
            templatePanel
        case .layout:
            layoutPanel
        case .textSize:
            textSizePanel
        case .textColor:
            textColorPanel
        case .background:
            backgroundPanel
        }
    }

    // MARK: - Template Panel

    private var templatePanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            panelTitle("テンプレート")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.md) {
                    ForEach(DesignTemplateStore.allTemplates) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal, DSSpacing.xs)
            }
        }
    }

    private func templateCard(_ template: DesignTemplate) -> some View {
        let isSelected = viewModel.designTemplateType == template.id

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.changeDesignTemplate(template.id)
            }
        } label: {
            VStack(spacing: DSSpacing.xs) {
                // Preview swatch
                RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                    .fill(
                        Color(hex: template.showBackground
                              ? template.backgroundColor
                              : "333333"
                        )
                    )
                    .frame(width: 64, height: 48)
                    .overlay {
                        Text("Aa")
                            .font(.system(size: 18, weight: fontWeight(template.fontWeight)))
                            .foregroundStyle(Color(hex: template.textColor))
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                                .strokeBorder(DSColors.accent, lineWidth: 2.5)
                        }
                    }

                Text(template.name)
                    .font(DSTypography.caption)
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Layout Panel

    private var layoutPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("レイアウト")

            HStack(spacing: DSSpacing.md) {
                layoutOption(
                    title: "1行",
                    subtitle: "シングルライン",
                    mode: .single,
                    icon: "text.aligncenter"
                )
                layoutOption(
                    title: "2行",
                    subtitle: "ダブルライン",
                    mode: .double,
                    icon: "text.alignleft"
                )
            }
        }
    }

    private func layoutOption(title: String, subtitle: String, mode: LayoutMode, icon: String) -> some View {
        let isSelected = viewModel.layoutMode == mode

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.layoutMode = mode
            }
        } label: {
            VStack(spacing: DSSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DSColors.accent : Color.white.opacity(0.6))

                Text(title)
                    .font(DSTypography.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))

                Text(subtitle)
                    .font(DSTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .strokeBorder(DSColors.accent, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Text Size Panel

    private var textSizePanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テキストサイズ")

            HStack(spacing: DSSpacing.md) {
                Image(systemName: "textformat.size.smaller")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))

                Slider(
                    value: $viewModel.textScale,
                    in: 0.5...2.0,
                    step: 0.05
                )
                .tint(DSColors.accent)

                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            // Display current scale
            Text("\(Int(viewModel.textScale * 100))%")
                .font(DSTypography.caption)
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Text Colour Panel

    private var textColorPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("テキストカラー")

            HStack(spacing: DSSpacing.lg) {
                // Default (template colour)
                colorButton(
                    label: "デフォルト",
                    color: nil,
                    displayColor: Color(hex: viewModel.currentDesignTemplate.textColor)
                )

                colorButton(label: "白", color: .white, displayColor: .white)
                colorButton(label: "黒", color: .black, displayColor: .black)
                colorButton(label: "クリーム", color: Color(hex: "FFF8F0"), displayColor: Color(hex: "FFF8F0"))
                colorButton(label: "セージ", color: DSColors.accent, displayColor: DSColors.accent)
            }
        }
    }

    private func colorButton(label: String, color: Color?, displayColor: Color) -> some View {
        let isSelected = viewModel.textColorOverride == color
            && (color != nil || viewModel.textColorOverride == nil)

        // For the "default" option: selected when override is nil
        let isDefault = color == nil && viewModel.textColorOverride == nil

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.textColorOverride = color
            }
        } label: {
            VStack(spacing: DSSpacing.xs) {
                Circle()
                    .fill(displayColor)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                (isSelected || isDefault) ? DSColors.accent : Color.white.opacity(0.3),
                                lineWidth: (isSelected || isDefault) ? 2.5 : 1
                            )
                    }
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                Text(label)
                    .font(DSTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background Panel

    private var backgroundPanel: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            panelTitle("背景バンド")

            HStack {
                Text("テキスト背景を表示")
                    .font(DSTypography.callout)
                    .foregroundStyle(Color.white.opacity(0.85))

                Spacer()

                Toggle("", isOn: $viewModel.showBackgroundBand)
                    .labelsHidden()
                    .tint(DSColors.accent)
            }
            .padding(.vertical, DSSpacing.xs)
        }
    }

    // MARK: - Helpers

    private func panelTitle(_ text: String) -> some View {
        Text(text)
            .font(DSTypography.headline)
            .foregroundStyle(Color.white.opacity(0.9))
    }

    private func fontWeight(_ weight: DesignTemplate.FontWeight) -> Font.Weight {
        switch weight {
        case .thin:     return .thin
        case .light:    return .light
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            EditorToolPanel(
                viewModel: EditorViewModel(
                    image: UIImage(),
                    event: Event(
                        name: "Preview",
                        baseDate: "2024-12-25"
                    )
                )
            )
        }
    }
}
