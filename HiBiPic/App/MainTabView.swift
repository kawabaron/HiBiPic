import SwiftUI

// MARK: - AppTab

enum AppTab: Hashable {
    case library
    case capture
    case events
}

// MARK: - MainTabView

/// The app's root view with a bottom tab bar.
///
/// Three tabs:
///   1. ライブラリ (home) – saved images in grid / calendar
///   2. 撮る (centre)    – triggers event selection → camera / photo picker
///   3. イベント          – event management list
///
/// All modal presentations (Camera, PhotoPicker, Editor, EventCreate) are
/// attached here so they work regardless of the active tab.
struct MainTabView: View {

    private enum CaptureFlowTiming {
        static let eventSelectionDismissDelay: TimeInterval = 0.28
        static let actionSheetDismissDelay: TimeInterval = 0.3
    }

    @Binding var appearanceMode: AppAppearanceMode
    @Binding var languageMode: AppLanguage

    private struct CaptureEventSelectionSession: Identifiable {
        let id = UUID()
        let events: [Event]
    }

    // MARK: - State

    @State private var selectedTab: AppTab = .library
    @State private var previousTab: AppTab = .library
    @State private var coordinator = NavigationCoordinator()

    // Capture flow state
    @State private var captureSelectedEvent: Event?
    @State private var eventSelectionSession: CaptureEventSelectionSession?
    @State private var showNoEventsAlert = false
    @State private var showSettings = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: ライブラリ
            NavigationStack {
                LibraryScreen(
                    onSettingsTap: {
                        showSettings = true
                    }
                )
            }
            .tabItem {
                Label(L10n.t("ライブラリ"), systemImage: "photo.on.rectangle")
            }
            .tag(AppTab.library)

            // Tab 2: 撮る (virtual – no real content)
            Color.clear
                .tabItem {
                    Label(L10n.t("撮る"), systemImage: "camera.fill")
                }
                .tag(AppTab.capture)

            // Tab 3: イベント
            RootNavigationView(
                coordinator: coordinator,
                onSettingsTap: {
                    showSettings = true
                }
            )
                .tabItem {
                    Label(L10n.t("イベント"), systemImage: "calendar")
                }
                .tag(AppTab.events)
        }
        .tint(DSColors.accent)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .capture {
                previousTab = oldValue
                selectedTab = previousTab // Immediately revert tab
                handleCaptureTabTapped()
            } else {
                previousTab = newValue
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsScreen(
                    appearanceMode: $appearanceMode,
                    languageMode: $languageMode
                )
            }
        }

        .sheet(item: $eventSelectionSession) { session in
            EventSelectSheet(
                events: session.events,
                onEventSelected: { event in
                    eventSelectionSession = nil
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + CaptureFlowTiming.eventSelectionDismissDelay
                    ) {
                        presentCaptureActionSheet(for: event)
                    }
                },
                onDismiss: {
                    eventSelectionSession = nil
                }
            )
            .presentationDetents([.medium, .large])
        }

        // MARK: - Capture Action Sheet

        .sheet(item: $captureSelectedEvent) { event in
            captureActionSheetContent(for: event)
                .presentationDetents([.height(280)])
        }

        // MARK: - Modal Presentations (shared across tabs)

        .sheet(isPresented: $coordinator.showCreateEvent, onDismiss: {
            coordinator.handleCreateEventDismiss()
        }) {
            NavigationStack {
                EventCreateScreen(event: coordinator.editingEvent)
            }
            .interactiveDismissDisabled(false)
        }

        .sheet(isPresented: $coordinator.showPhotoPicker, onDismiss: {
            coordinator.presentDeferredRouteIfNeeded()
        }) {
            if let event = coordinator.selectedEvent {
                PhotoPickerScreen(
                    isPresented: $coordinator.showPhotoPicker,
                    onImageSelected: { image in
                        coordinator.queueEditorPresentation(image: image, event: event)
                        coordinator.showPhotoPicker = false
                    }
                )
            }
        }

        .fullScreenCover(isPresented: $coordinator.showCamera, onDismiss: {
            coordinator.presentDeferredRouteIfNeeded()
        }) {
            if let event = coordinator.selectedEvent {
                CameraScreen(
                    event: event,
                    onImageCaptured: { image in
                        coordinator.queueEditorPresentation(image: image, event: event)
                        coordinator.showCamera = false
                    },
                    onPickerRequested: {
                        coordinator.queuePhotoPickerPresentation(event: event)
                        coordinator.showCamera = false
                    },
                    onDismiss: {
                        coordinator.showCamera = false
                    }
                )
            }
        }

        .fullScreenCover(isPresented: $coordinator.showEditor, onDismiss: {
            coordinator.handleEditorDismiss()
        }) {
            if let viewModel = coordinator.editorViewModel {
                EditorScreen(
                    viewModel: viewModel
                )
            }
        }

        // MARK: - No Events Alert

        .alert(L10n.t("イベントがありません"), isPresented: $showNoEventsAlert) {
            Button(L10n.t("イベントを作成")) {
                selectedTab = .events
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.navigateToCreateEvent()
                }
            }
            Button(L10n.t("キャンセル"), role: .cancel) {}
        } message: {
            Text(L10n.t("写真を撮るにはイベントを作成してください"))
        }
    }

    // MARK: - Capture Tab Logic

    private func handleCaptureTabTapped() {
        do {
            let events = try AppDependencies.shared.eventRepository.fetchAll(
                isArchived: false,
                sort: "last_used_at"
            )

            switch events.count {
            case 0:
                showNoEventsAlert = true

            case 1:
                presentCaptureActionSheet(for: events[0])

            default:
                DispatchQueue.main.async {
                    eventSelectionSession = CaptureEventSelectionSession(events: events)
                }
            }
        } catch {
            showNoEventsAlert = true
        }
    }

    // MARK: - Capture Action Sheet Content

    private func captureActionSheetContent(for event: Event) -> some View {
        VStack(spacing: DSSpacing.lg) {
            // Handle bar
            Capsule()
                .fill(DSColors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, DSSpacing.sm)

            Text(event.name)
                .font(DSTypography.headline)
                .foregroundStyle(DSColors.textPrimary)

            VStack(spacing: DSSpacing.md) {
                Button {
                    dismissCaptureActionSheet(after: CaptureFlowTiming.actionSheetDismissDelay) {
                        coordinator.navigateToCamera(event: event)
                    }
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DSColors.accent)
                            .frame(width: 32)
                        Text(L10n.t("カメラで撮る"))
                            .font(DSTypography.body)
                            .foregroundStyle(DSColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DSColors.textTertiary)
                    }
                    .padding(DSSpacing.lg)
                    .background(DSColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    dismissCaptureActionSheet(after: CaptureFlowTiming.actionSheetDismissDelay) {
                        coordinator.navigateToPhotoPicker(event: event)
                    }
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundStyle(DSColors.warning)
                            .frame(width: 32)
                        Text(L10n.t("写真から選ぶ"))
                            .font(DSTypography.body)
                            .foregroundStyle(DSColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DSColors.textTertiary)
                    }
                    .padding(DSSpacing.lg)
                    .background(DSColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cornerMd, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DSSpacing.lg)

            Spacer()
        }
        .background(DSColors.background)
    }

    private func presentCaptureActionSheet(for event: Event) {
        captureSelectedEvent = event
    }

    private func dismissCaptureActionSheet(
        after delay: TimeInterval,
        perform action: @escaping () -> Void
    ) {
        captureSelectedEvent = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
}

// MARK: - TabBar Appearance

extension MainTabView {
    static func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DSColors.background)
        appearance.shadowColor = UIColor(DSColors.divider)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
