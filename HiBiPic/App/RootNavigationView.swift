import Observation
import SwiftUI

// MARK: - NavigationCoordinator

/// Central navigation state for the entire app.
///
/// Manages which modal (sheet / fullScreenCover) is presented and
/// carries the transient data flowing between screens.
@Observable
final class NavigationCoordinator {

    // MARK: - Sheet / Cover Presentations

    var showCreateEvent = false
    var showCamera = false
    var showPhotoPicker = false
    var showEditor = false

    // MARK: - Transient Data

    var editingEvent: Event?
    var selectedEvent: Event?
    var capturedImage: UIImage?
    var selectedImage: UIImage?

    // MARK: - Navigation Methods

    func navigateToCreateEvent() {
        editingEvent = nil
        showCreateEvent = true
    }

    func navigateToEditEvent(_ event: Event) {
        editingEvent = event
        showCreateEvent = true
    }

    func navigateToCamera(event: Event) {
        selectedEvent = event
        showCamera = true
    }

    func navigateToPhotoPicker(event: Event) {
        selectedEvent = event
        showPhotoPicker = true
    }

    func navigateToEditor(image: UIImage, event: Event) {
        capturedImage = image
        selectedEvent = event
        showEditor = true
    }

    func returnToList() {
        showEditor = false
        showCamera = false
        showPhotoPicker = false
        showCreateEvent = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.clearTransientState()
        }
    }

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

/// The events tab content. Displays the event list with action sheets,
/// swipe actions, and toolbar. Modal presentations are handled by MainTabView.
struct RootNavigationView: View {

    // MARK: - State

    @Bindable var coordinator: NavigationCoordinator
    @State private var viewModel = EventListViewModel()

    /// The event shown in the custom action sheet overlay.
    @State private var actionSheetEvent: Event?
    @State private var showActionSheet = false

    /// Navigation to event-filtered library.
    @State private var showEventLibrary = false
    @State private var eventForLibrary: Event?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                DSColors.background
                    .ignoresSafeArea()

                eventListContent
                    .navigationTitle("イベント")
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
            .navigationDestination(isPresented: $showEventLibrary) {
                if let event = eventForLibrary {
                    LibraryScreen(
                        eventId: event.id,
                        onCaptureForEvent: { event in
                            coordinator.navigateToCamera(event: event)
                        },
                        onPickPhotoForEvent: { event in
                            coordinator.navigateToPhotoPicker(event: event)
                        }
                    )
                }
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }
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

            if !viewModel.pinnedEvents.isEmpty {
                Section {
                    ForEach(viewModel.pinnedEvents) { event in
                        eventCard(for: event)
                    }
                } header: {
                    sectionHeader("ピン留め", icon: "pin.fill")
                }
            }

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
            eventForLibrary = event
            showEventLibrary = true
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

#Preview("Events Tab") {
    RootNavigationView(coordinator: NavigationCoordinator())
}
