import SwiftUI

// MARK: - EventListScreen

/// The main event list screen -- the app's home.
///
/// Shows a warm, minimal list of event cards organised into
/// "pinned" and "all events" sections. Supports pull-to-refresh,
/// swipe actions, sort selection, and an action sheet on tap.
struct EventListScreen: View {

    // MARK: - State

    @State private var viewModel = EventListViewModel()

    /// The event currently presented in the action sheet.
    @State private var selectedEvent: Event?

    /// Controls the action-sheet overlay.
    @State private var showActionSheet = false

    /// Controls navigation to the create screen.
    @State private var showCreateEvent = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                DSColors.background
                    .ignoresSafeArea()

                content
                    .navigationTitle("HiBiPic")
                    .toolbar { toolbarItems }
                    .alert(
                        "イベントを削除",
                        isPresented: $viewModel.showDeleteConfirm,
                        presenting: viewModel.eventToDelete
                    ) { event in
                        Button("削除", role: .destructive) {
                            viewModel.confirmDelete()
                        }
                        Button("キャンセル", role: .cancel) {}
                    } message: { event in
                        Text("「\(event.name)」を削除しますか？この操作は取り消せません。")
                    }

                // Action-sheet overlay
                if showActionSheet, let event = selectedEvent {
                    actionSheetOverlay(for: event)
                }
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }
    }

    // MARK: - Content Switcher

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.events.isEmpty {
            loadingView
        } else if viewModel.isEmpty {
            EmptyStateView {
                showCreateEvent = true
            }
        } else {
            eventList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(DSColors.accent)
            Spacer()
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

    // MARK: - Event Card with Swipe

    private func eventCard(for event: Event) -> some View {
        EventCardView(event: event) {
            selectedEvent = event
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
            // Scrim
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
                showCreateEvent = true
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
            // TODO: Navigate to camera screen with event
            break
        case .photoPicker:
            // TODO: Present photo picker with event
            break
        case .edit:
            // TODO: Navigate to event edit screen
            break
        }
    }

    private func dismissActionSheet() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showActionSheet = false
        }
        selectedEvent = nil
    }
}

// MARK: - Preview

#Preview("Event List - With Events") {
    EventListScreen()
}
