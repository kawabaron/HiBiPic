import Observation
import SwiftUI

// MARK: - NavigationCoordinator

/// Central navigation state for the entire app.
///
/// Manages which modal (sheet / fullScreenCover) is presented and
/// carries the transient data flowing between screens:
///
///     List -> Create/Edit (sheet)
///     List -> Camera (fullScreenCover)
///     List -> PhotoPicker (sheet)
///     Camera/PhotoPicker -> Editor (fullScreenCover)
///     Editor -> Save Success -> back to List
///
@Observable
final class NavigationCoordinator {

    // MARK: - Sheet / Cover Presentations

    /// Controls the EventCreate sheet.
    var showCreateEvent = false

    /// Controls the Camera full-screen cover.
    var showCamera = false

    /// Controls the PhotoPicker sheet.
    var showPhotoPicker = false

    /// Controls the Editor full-screen cover.
    var showEditor = false

    // MARK: - Transient Data

    /// The event currently being edited (EventCreate in edit mode).
    var editingEvent: Event?

    /// The event selected for the camera / photo-picker flow.
    var selectedEvent: Event?

    /// Image captured by the camera, waiting to move into the editor.
    var capturedImage: UIImage?

    /// Image selected from the photo library, waiting to move into the editor.
    var selectedImage: UIImage?

    // MARK: - Navigation Methods

    /// Present the EventCreate sheet in creation mode.
    func navigateToCreateEvent() {
        editingEvent = nil
        showCreateEvent = true
    }

    /// Present the EventCreate sheet pre-populated for editing.
    func navigateToEditEvent(_ event: Event) {
        editingEvent = event
        showCreateEvent = true
    }

    /// Present the Camera full-screen cover for the given event.
    func navigateToCamera(event: Event) {
        selectedEvent = event
        showCamera = true
    }

    /// Present the PhotoPicker sheet for the given event.
    func navigateToPhotoPicker(event: Event) {
        selectedEvent = event
        showPhotoPicker = true
    }

    /// Present the Editor full-screen cover with the given image and event.
    func navigateToEditor(image: UIImage, event: Event) {
        capturedImage = image
        selectedEvent = event
        showEditor = true
    }

    /// Dismiss everything and return to the event list.
    func returnToList() {
        showEditor = false
        showCamera = false
        showPhotoPicker = false
        showCreateEvent = false

        // Clear transient state after a short delay so dismiss
        // animations complete before the data is nilled out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.clearTransientState()
        }
    }

    /// Full reset -- dismisses all modals and clears all state.
    func reset() {
        showCreateEvent = false
        showCamera = false
        showPhotoPicker = false
        showEditor = false
        clearTransientState()
    }

    // MARK: - Private

    private func clearTransientState() {
        editingEvent = nil
        selectedEvent = nil
        capturedImage = nil
        selectedImage = nil
    }
}

// MARK: - RootNavigationView

/// The app's root view. Hosts the `EventListScreen` and coordinates all
/// modal presentations (sheets and full-screen covers) through a single
/// `NavigationCoordinator` instance.
struct RootNavigationView: View {

    // MARK: - State

    @State private var coordinator = NavigationCoordinator()
    @State private var viewModel = EventListViewModel()

    /// The event shown in the custom action sheet overlay.
    @State private var actionSheetEvent: Event?
    @State private var showActionSheet = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                DSColors.background
                    .ignoresSafeArea()

                eventListContent
                    .navigationTitle("HiBiPic")
                    .toolbar { toolbarItems }
                    .alert(
                        "イベントを削除",
                        isPresented: $viewModel.showDeleteConfirm,
                        presenting: viewModel.eventToDelete
                    ) { _ in
                        Button("削除", role: .destructive) {
                            viewModel.confirmDelete()
                        }
                        Button("キャンセル", role: .cancel) {}
                    } message: { event in
                        Text("「\(event.name)」を削除しますか？この操作は取り消せません。")
                    }

                // Custom action sheet overlay
                if showActionSheet, let event = actionSheetEvent {
                    actionSheetOverlay(for: event)
                }
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }

        // MARK: - Sheet: Event Create / Edit

        .sheet(isPresented: $coordinator.showCreateEvent, onDismiss: {
            coordinator.editingEvent = nil
            viewModel.loadEvents()
        }) {
            NavigationStack {
                EventCreateScreen(event: coordinator.editingEvent)
            }
            .interactiveDismissDisabled(false)
        }

        // MARK: - Sheet: Photo Picker

        .sheet(isPresented: $coordinator.showPhotoPicker, onDismiss: {
            // If an image was selected the coordinator already opened the editor.
        }) {
            if let event = coordinator.selectedEvent {
                PhotoPickerScreen(
                    event: event,
                    selectedImage: Binding(
                        get: { coordinator.selectedImage },
                        set: { coordinator.selectedImage = $0 }
                    ),
                    isPresented: $coordinator.showPhotoPicker,
                    onImageSelected: { image in
                        // Dismiss the picker, then present the editor.
                        coordinator.showPhotoPicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            coordinator.navigateToEditor(image: image, event: event)
                        }
                    }
                )
            }
        }

        // MARK: - FullScreenCover: Camera

        .fullScreenCover(isPresented: $coordinator.showCamera) {
            if let event = coordinator.selectedEvent {
                CameraScreen(
                    event: event,
                    onImageCaptured: { image in
                        // Dismiss the camera, then present the editor.
                        coordinator.showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            coordinator.navigateToEditor(image: image, event: event)
                        }
                    },
                    onPickerRequested: {
                        // From the camera the user wants the photo library instead.
                        coordinator.showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            coordinator.navigateToPhotoPicker(event: event)
                        }
                    },
                    onDismiss: {
                        coordinator.showCamera = false
                    }
                )
            }
        }

        // MARK: - FullScreenCover: Editor

        .fullScreenCover(isPresented: $coordinator.showEditor, onDismiss: {
            coordinator.capturedImage = nil
            coordinator.selectedImage = nil
            viewModel.loadEvents()
        }) {
            if let image = coordinator.capturedImage,
               let event = coordinator.selectedEvent {
                editorView(image: image, event: event)
            }
        }
    }

    // MARK: - Editor View Builder

    /// Builds an `EditorScreen` with its `EditorViewModel`.
    ///
    /// The editor's "Back to list" and "Edit another" buttons both call
    /// `dismiss()`, which dismisses the full-screen cover and triggers
    /// the `onDismiss` closure above -- reloading events and clearing
    /// transient state. No additional wiring is needed.
    @ViewBuilder
    private func editorView(image: UIImage, event: Event) -> some View {
        EditorScreen(
            viewModel: EditorViewModel(image: image, event: event)
        )
    }

    // MARK: - Event List Content

    @ViewBuilder
    private var eventListContent: some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            VStack {
                Spacer()
                ProgressView()
                    .tint(DSColors.accent)
                Spacer()
            }
        } else if viewModel.isEmpty {
            EmptyStateView {
                coordinator.navigateToCreateEvent()
            }
        } else {
            eventList
        }
    }

    // MARK: - Event List

    private var eventList: some View {
        List {
            // Error banner
            if let error = viewModel.errorMessage {
                errorBanner(error)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(
                        top: DSSpacing.xs,
                        leading: DSSpacing.lg,
                        bottom: DSSpacing.xs,
                        trailing: DSSpacing.lg
                    ))
            }

            // Pinned section
            if !viewModel.pinnedEvents.isEmpty {
                Section {
                    ForEach(viewModel.pinnedEvents) { event in
                        eventCard(for: event)
                    }
                } header: {
                    sectionHeader("ピン留め", icon: "pin.fill")
                }
            }

            // Regular events section
            if !viewModel.unpinnedEvents.isEmpty {
                Section {
                    ForEach(viewModel.unpinnedEvents) { event in
                        eventCard(for: event)
                    }
                } header: {
                    sectionHeader("イベント", icon: "calendar")
                }
            }
        }
        .listStyle(.plain)
        .listRowSpacing(DSSpacing.sm)
        .scrollContentBackground(.hidden)
        .refreshable {
            viewModel.loadEvents()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DSColors.textTertiary)

            Text(title)
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textTertiary)
                .textCase(.none)

            Spacer()
        }
        .padding(.top, DSSpacing.sm)
        .padding(.horizontal, DSSpacing.xs)
    }

    // MARK: - Event Card

    private func eventCard(for event: Event) -> some View {
        EventCardView(event: event) {
            actionSheetEvent = event
            withAnimation(.easeInOut(duration: 0.25)) {
                showActionSheet = true
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(
            top: DSSpacing.xs,
            leading: DSSpacing.lg,
            bottom: DSSpacing.xs,
            trailing: DSSpacing.lg
        ))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.deleteEvent(event: event)
            } label: {
                Label("削除", systemImage: "trash")
            }

            Button {
                viewModel.archiveEvent(event: event)
            } label: {
                Label("アーカイブ", systemImage: "archivebox")
            }
            .tint(DSColors.warning)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.togglePin(event: event)
            } label: {
                Label(
                    event.isPinned ? "ピン解除" : "ピン留め",
                    systemImage: event.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(DSColors.accent)
        }
        .contextMenu {
            Button {
                viewModel.togglePin(event: event)
            } label: {
                Label(
                    event.isPinned ? "ピン解除" : "ピン留め",
                    systemImage: event.isPinned ? "pin.slash.fill" : "pin.fill"
                )
            }

            Button {
                viewModel.archiveEvent(event: event)
            } label: {
                Label("アーカイブ", systemImage: "archivebox.fill")
            }

            Divider()

            Button(role: .destructive) {
                viewModel.deleteEvent(event: event)
            } label: {
                Label("削除", systemImage: "trash.fill")
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DSColors.warning)

            Text(message)
                .font(DSTypography.footnote)
                .foregroundStyle(DSColors.textSecondary)

            Spacer()

            Button {
                viewModel.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DSColors.textTertiary)
            }
        }
        .padding(DSSpacing.md)
        .background(DSColors.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerSm, style: .continuous))
    }

    // MARK: - Action Sheet Overlay

    private func actionSheetOverlay(for event: Event) -> some View {
        ZStack(alignment: .bottom) {
            DSColors.overlayDark
                .ignoresSafeArea()
                .onTapGesture {
                    dismissActionSheet()
                }

            EventActionSheet(
                event: event,
                onAction: { action in
                    handleAction(action, for: event)
                },
                onDismiss: {
                    dismissActionSheet()
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.25), value: showActionSheet)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                coordinator.navigateToCreateEvent()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DSColors.accent)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            sortMenu
        }
    }

    // MARK: - Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(EventSortType.allCases, id: \.displayName) { type in
                Button {
                    viewModel.changeSortType(type)
                } label: {
                    Label {
                        Text(type.displayName)
                    } icon: {
                        if viewModel.sortType == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DSColors.accent)
        }
    }

    // MARK: - Actions

    private func handleAction(_ action: EventAction, for event: Event) {
        dismissActionSheet()
        viewModel.markUsed(event: event)

        switch action {
        case .camera:
            coordinator.navigateToCamera(event: event)
        case .photoPicker:
            coordinator.navigateToPhotoPicker(event: event)
        case .edit:
            coordinator.navigateToEditEvent(event)
        }
    }

    private func dismissActionSheet() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showActionSheet = false
        }
        actionSheetEvent = nil
    }
}

// MARK: - Preview

#Preview("Root Navigation") {
    RootNavigationView()
}
