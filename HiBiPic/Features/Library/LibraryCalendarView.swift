import SwiftUI

// MARK: - LibraryCalendarView

/// Monthly calendar view showing event base dates and image creation dates.
struct LibraryCalendarView: View {

    @Bindable var viewModel: LibraryViewModel
    var onImageTapped: (SavedImage) -> Void

    @State private var selectedDate: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: DSSpacing.lg) {
                monthHeader
                weekdayHeader
                calendarGrid
                selectedDateContent
            }
            .padding(.horizontal, DSSpacing.lg)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.previousMonth()
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColors.accent)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.nextMonth()
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DSColors.accent)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.top, DSSpacing.sm)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .font(DSTypography.caption)
                    .foregroundStyle(DSColors.textTertiary)
                    .frame(height: 24)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = calendarDays()
        let events = viewModel.eventsInMonth(viewModel.selectedMonth)
        let eventDates = Set(events.map { $0.baseDate })

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                if let day {
                    let dateString = DateCalculator.stringFromDate(day)
                    let isToday = calendar.isDateInToday(day)
                    let hasEvent = eventDates.contains(dateString)
                    let imageCount = viewModel.imagesForDate(dateString).count
                    let isSelected = selectedDate == dateString

                    dayCellButton(
                        day: day,
                        dateString: dateString,
                        isToday: isToday,
                        hasEvent: hasEvent,
                        imageCount: imageCount,
                        isSelected: isSelected
                    )
                } else {
                    Color.clear
                        .frame(height: 48)
                }
            }
        }
    }

    private func dayCellButton(
        day: Date,
        dateString: String,
        isToday: Bool,
        hasEvent: Bool,
        imageCount: Int,
        isSelected: Bool
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = isSelected ? nil : dateString
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .font(DSTypography.callout)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? DSColors.accent : DSColors.textPrimary))

                HStack(spacing: 3) {
                    if hasEvent {
                        Circle()
                            .fill(DSColors.accent)
                            .frame(width: 5, height: 5)
                    }
                    if imageCount > 0 {
                        Circle()
                            .fill(DSColors.warning)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .fill(DSColors.accent)
                } else if isToday {
                    RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous)
                        .fill(DSColors.accentLight.opacity(0.2))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selected Date Content

    @ViewBuilder
    private var selectedDateContent: some View {
        if let dateString = selectedDate {
            let dayImages = viewModel.imagesForDate(dateString)
            let events = viewModel.eventsInMonth(viewModel.selectedMonth)
                .filter { $0.baseDate == dateString }

            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text(formattedDate(dateString))
                    .font(DSTypography.headline)
                    .foregroundStyle(DSColors.textPrimary)

                if !events.isEmpty {
                    ForEach(events, id: \.id) { event in
                        HStack(spacing: DSSpacing.sm) {
                            Circle()
                                .fill(DSColors.accent)
                                .frame(width: 8, height: 8)
                            Text(event.name)
                                .font(DSTypography.subheadline)
                                .foregroundStyle(DSColors.textPrimary)
                        }
                    }
                }

                if dayImages.isEmpty && events.isEmpty {
                    Text(L10n.t("この日のデータはありません"))
                        .font(DSTypography.subheadline)
                        .foregroundStyle(DSColors.textTertiary)
                } else if !dayImages.isEmpty {
                    let imageColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
                    LazyVGrid(columns: imageColumns, spacing: 4) {
                        ForEach(dayImages) { image in
                            Button {
                                onImageTapped(image)
                            } label: {
                                if let thumb = ImageFileStorage.shared.loadThumbnail(fileName: image.fileName) {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 80)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(DSSpacing.lg)
            .background(DSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
        }
    }

    // MARK: - Helpers

    private func calendarDays() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay)
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay) - 1 // 0 = Sunday
        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }

        // Pad trailing days
        let remainder = days.count % 7
        if remainder > 0 {
            days.append(contentsOf: Array(repeating: nil as Date?, count: 7 - remainder))
        }

        return days
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = AppLocalizer.currentLanguage.locale
        return calendar
    }

    private var weekdayLabels: [String] {
        let formatter = DateFormatter()
        formatter.locale = AppLocalizer.currentLanguage.locale
        return formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols
    }

    private func formattedDate(_ dateString: String) -> String {
        guard let date = DateCalculator.baseDateFromString(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.locale = AppLocalizer.currentLanguage.locale
        formatter.setLocalizedDateFormatFromTemplate("MMMdEEE")
        return formatter.string(from: date)
    }
}
