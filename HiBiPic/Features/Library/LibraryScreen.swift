import SwiftUI

// MARK: - Notification

extension Notification.Name {
    static let libraryDidChange = Notification.Name("libraryDidChange")
    static let eventListDidChange = Notification.Name("eventListDidChange")
}

// MARK: - LibraryScreen

/// Main library screen showing saved images in grid or calendar view.
/// Can be filtered by event when navigated from the event list.
struct LibraryScreen: View {

    // MARK: - Properties

    @State var viewModel: LibraryViewModel
    @State private var viewModeIndex = 0
    @State private var selectedImage: SavedImage?

    /// Callback for "カメラで撮る" (filtered mode only).
    var onCaptureForEvent: ((Event) -> Void)?
    /// Callback for "写真から選ぶ" (filtered mode only).
    var onPickPhotoForEvent: ((Event) -> Void)?
    /// Opens the app settings (root library only).
    var onSettingsTap: (() -> Void)?

    // MARK: - Init

    init(
        eventId: String? = nil,
        onCaptureForEvent: ((Event) -> Void)? = nil,
        onPickPhotoForEvent: ((Event) -> Void)? = nil,
        onSettingsTap: (() -> Void)? = nil
    ) {
        self._viewModel = State(initialValue: LibraryViewModel(eventId: eventId))
        self.onCaptureForEvent = onCaptureForEvent
        self.onPickPhotoForEvent = onPickPhotoForEvent
        self.onSettingsTap = onSettingsTap
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            segmentControl
            contentView
        }
        .background(DSColors.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.filteredEvent == nil, let onSettingsTap {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onSettingsTap) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DSColors.accent)
                    }
                }
            }

            if let event = viewModel.filteredEvent, let onCapture = onCaptureForEvent {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            onCapture(event)
                        } label: {
                            Label(L10n.t("カメラで撮る"), systemImage: "camera.fill")
                        }
                        Button {
                            onPickPhotoForEvent?(event)
                        } label: {
                            Label(L10n.t("写真から選ぶ"), systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(DSColors.accent)
                    }
                }
            }
        }
        .onAppear {
            syncViewModeIndex()
            viewModel.loadImages()
        }
        .onReceive(NotificationCenter.default.publisher(for: .libraryDidChange)) { _ in
            viewModel.loadImages()
        }
        .fullScreenCover(item: $selectedImage) { image in
            ImageDetailView(
                images: viewModel.images,
                initialImageID: image.id,
                onPrepareReedit: { selectedImage in
                    viewModel.prepareEditor(for: selectedImage)
                }
            ) { deletedImage in
                viewModel.deleteImage(deletedImage)
            }
        }
    }

    // MARK: - Segment Control

    private var segmentControl: some View {
        DSSegmentedControl(
            items: [LibraryViewMode.calendar.displayLabel, LibraryViewMode.grid.displayLabel],
            selection: $viewModeIndex
        )
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.sm)
        .onChange(of: viewModeIndex) { _, newValue in
            viewModel.viewMode = newValue == 0 ? .calendar : .grid
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewMode {
        case .grid:
            LibraryGridView(images: viewModel.images) { image in
                selectedImage = image
            }
        case .calendar:
            LibraryCalendarView(viewModel: viewModel) { image in
                selectedImage = image
            }
        }
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        if let event = viewModel.filteredEvent {
            return event.name
        }
        return L10n.t("ライブラリ")
    }

    private func syncViewModeIndex() {
        viewModeIndex = viewModel.viewMode == .calendar ? 0 : 1
    }
}
