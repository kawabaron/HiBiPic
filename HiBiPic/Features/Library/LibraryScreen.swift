import SwiftUI

// MARK: - Notification

extension Notification.Name {
    static let libraryDidChange = Notification.Name("libraryDidChange")
}

// MARK: - LibraryScreen

/// Main library screen showing saved images in grid or calendar view.
/// Can be filtered by event when navigated from the event list.
struct LibraryScreen: View {

    // MARK: - Properties

    @State var viewModel: LibraryViewModel
    @State private var viewModeIndex = 0
    @State private var selectedImage: SavedImage?
    @State private var showImageDetail = false

    /// Callback for "カメラで撮る" (filtered mode only).
    var onCaptureForEvent: ((Event) -> Void)?
    /// Callback for "写真から選ぶ" (filtered mode only).
    var onPickPhotoForEvent: ((Event) -> Void)?

    // MARK: - Init

    init(
        eventId: String? = nil,
        onCaptureForEvent: ((Event) -> Void)? = nil,
        onPickPhotoForEvent: ((Event) -> Void)? = nil
    ) {
        self._viewModel = State(initialValue: LibraryViewModel(eventId: eventId))
        self.onCaptureForEvent = onCaptureForEvent
        self.onPickPhotoForEvent = onPickPhotoForEvent
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
            if let event = viewModel.filteredEvent, let onCapture = onCaptureForEvent {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            onCapture(event)
                        } label: {
                            Label("カメラで撮る", systemImage: "camera.fill")
                        }
                        Button {
                            onPickPhotoForEvent?(event)
                        } label: {
                            Label("写真から選ぶ", systemImage: "photo.on.rectangle")
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
            viewModel.loadImages()
        }
        .onReceive(NotificationCenter.default.publisher(for: .libraryDidChange)) { _ in
            viewModel.loadImages()
        }
        .fullScreenCover(isPresented: $showImageDetail) {
            if let image = selectedImage {
                ImageDetailView(image: image) {
                    viewModel.deleteImage(image)
                    selectedImage = nil
                }
            }
        }
    }

    // MARK: - Segment Control

    private var segmentControl: some View {
        DSSegmentedControl(
            items: [LibraryViewMode.grid.displayLabel, LibraryViewMode.calendar.displayLabel],
            selection: $viewModeIndex
        )
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.sm)
        .onChange(of: viewModeIndex) { _, newValue in
            viewModel.viewMode = newValue == 0 ? .grid : .calendar
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewMode {
        case .grid:
            LibraryGridView(images: viewModel.images) { image in
                selectedImage = image
                showImageDetail = true
            }
        case .calendar:
            LibraryCalendarView(viewModel: viewModel) { image in
                selectedImage = image
                showImageDetail = true
            }
        }
    }

    // MARK: - Helpers

    private var navigationTitle: String {
        if let event = viewModel.filteredEvent {
            return event.name
        }
        return "ライブラリ"
    }
}
