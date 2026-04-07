import SwiftUI

// MARK: - DSSegmentedControl
/// A pill-style segmented control with a sliding accent-color highlight.
///
/// Designed for selecting among a small number of items (typically 2-4).
/// Used in HiBiPic for count-type selection (days / weeks / months).
///
/// Usage:
/// ```swift
/// DSSegmentedControl(
///     items: ["Days", "Weeks", "Months"],
///     selection: $selectedIndex
/// )
/// ```
struct DSSegmentedControl: View {

    // MARK: - Properties

    let items: [String]
    @Binding var selection: Int

    @Namespace private var pillNamespace

    // MARK: - Body

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            ForEach(items.indices, id: \.self) { index in
                segmentButton(for: index)
            }
        }
        .padding(DSSpacing.xs)
        .background(DSColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous))
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func segmentButton(for index: Int) -> some View {
        let isSelected = selection == index

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selection = index
            }
        } label: {
            Text(items[index])
                .font(DSTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? DSColors.buttonPrimaryText : DSColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpacing.sm)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous)
                            .fill(DSColors.accent)
                            .matchedGeometryEffect(id: "pill", in: pillNamespace)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Generic Variant
/// A type-safe variant that works with any `Hashable & CaseIterable` enum
/// or an array of `Identifiable` items.
///
/// Usage:
/// ```swift
/// enum CountType: String, CaseIterable, Identifiable {
///     case days, weeks, months
///     var id: Self { self }
///     var displayName: String { rawValue.capitalized }
/// }
///
/// DSSegmentedPicker(
///     items: CountType.allCases,
///     selection: $countType,
///     label: \.displayName
/// )
/// ```
struct DSSegmentedPicker<Item: Hashable>: View {

    // MARK: - Properties

    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    @Namespace private var pillNamespace

    // MARK: - Body

    var body: some View {
        HStack(spacing: DSSpacing.xs) {
            ForEach(items, id: \.self) { item in
                segmentButton(for: item)
            }
        }
        .padding(DSSpacing.xs)
        .background(DSColors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous))
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func segmentButton(for item: Item) -> some View {
        let isSelected = selection == item

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selection = item
            }
        } label: {
            Text(label(item))
                .font(DSTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? DSColors.buttonPrimaryText : DSColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DSSpacing.sm)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous)
                            .fill(DSColors.accent)
                            .matchedGeometryEffect(id: "genericPill", in: pillNamespace)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: DSSpacing.cornerFull, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Segmented Controls") {
    VStack(spacing: DSSpacing.xxxl) {
        DSSegmentedControl(
            items: ["Days", "Weeks", "Months"],
            selection: .constant(0)
        )

        DSSegmentedControl(
            items: ["Days", "Weeks", "Months"],
            selection: .constant(1)
        )

        DSSegmentedControl(
            items: ["Days", "Weeks", "Months"],
            selection: .constant(2)
        )
    }
    .padding(DSSpacing.xl)
    .background(DSColors.background)
}
