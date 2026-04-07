import SwiftUI

// MARK: - DSTextField
/// A styled text field matching the "Warm Minimal" theme.
///
/// Features:
/// - Floating-style label above the field
/// - Placeholder text
/// - Character count indicator (when `maxLength` is set)
/// - Error state with message
/// - Subtle border that highlights on focus
///
/// Usage:
/// ```swift
/// DSTextField(
///     "Event Name",
///     text: $name,
///     placeholder: "e.g. Morning Run",
///     maxLength: 50,
///     error: nameError
/// )
/// ```
struct DSTextField: View {

    // MARK: - Properties

    private let label: String
    private let placeholder: String
    private let maxLength: Int?
    private let error: String?
    private let axis: Axis

    @Binding private var text: String
    @FocusState private var isFocused: Bool

    // MARK: - Init

    /// Creates a new ``DSTextField``.
    /// - Parameters:
    ///   - label: The label displayed above the field.
    ///   - text: Binding to the text value.
    ///   - placeholder: Placeholder shown when text is empty.
    ///   - maxLength: Optional maximum character count.
    ///   - error: Optional error message shown below the field.
    ///   - axis: The expansion axis for multi-line input. Defaults to `.horizontal` (single line).
    init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        maxLength: Int? = nil,
        error: String? = nil,
        axis: Axis = .horizontal
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.error = error
        self.axis = axis
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xs) {
            // Label
            Text(label)
                .font(DSTypography.footnote)
                .foregroundStyle(labelColor)

            // Text field
            TextField(placeholder, text: $text, axis: axis)
                .font(DSTypography.body)
                .foregroundStyle(DSColors.textPrimary)
                .focused($isFocused)
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.md)
                .background(DSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: isFocused ? 1.5 : 1)
                }
                .onChange(of: text) { _, newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                }

            // Footer row: error message + character count
            HStack {
                if let error, !error.isEmpty {
                    Text(error)
                        .font(DSTypography.caption)
                        .foregroundStyle(DSColors.error)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                if let maxLength {
                    Text("\(text.count)/\(maxLength)")
                        .font(DSTypography.caption)
                        .foregroundStyle(characterCountColor(max: maxLength))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: error)
        }
    }

    // MARK: - Computed

    private var labelColor: Color {
        if error != nil { return DSColors.error }
        if isFocused { return DSColors.accent }
        return DSColors.textSecondary
    }

    private var borderColor: Color {
        if error != nil { return DSColors.error }
        if isFocused { return DSColors.accent }
        return DSColors.border
    }

    private func characterCountColor(max: Int) -> Color {
        let ratio = Double(text.count) / Double(max)
        if ratio >= 1.0 { return DSColors.error }
        if ratio >= 0.9 { return DSColors.warning }
        return DSColors.textTertiary
    }
}

// MARK: - Previews

#Preview("Text Fields") {
    VStack(spacing: DSSpacing.xl) {
        DSTextField(
            "Event Name",
            text: .constant("Morning Run"),
            placeholder: "e.g. Morning Run",
            maxLength: 50
        )

        DSTextField(
            "Description",
            text: .constant(""),
            placeholder: "What are you counting?",
            axis: .vertical
        )

        DSTextField(
            "With Error",
            text: .constant(""),
            placeholder: "Required",
            error: "This field is required"
        )

        DSTextField(
            "Near Limit",
            text: .constant(String(repeating: "a", count: 47)),
            placeholder: "Type here",
            maxLength: 50
        )
    }
    .padding(DSSpacing.xl)
    .background(DSColors.background)
}
