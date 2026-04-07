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

    // MARK: - State

    @State private var selectedTab: AppTab = .library
    @State private var previousTab: AppTab = .library
    @State private var coordinator = NavigationCoordinator()

    // Capture flow state
    @State private var showEventSelectSheet = false
    @State private var showCaptureActionSheet = false
    @State private var captureSelectedEvent: Event?
    @State private var captureEvents: [Event] = []
    @State private var showNoEventsAlert = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: ライブラリ
            NavigationStack {
                LibraryScreen()
            }
            .tabItem {
                Label("ライブラリ", systemImage: "photo.on.rectangle")
            }
            .tag(AppTab.library)

            // Tab 2: 撮る (virtual – no real content)
            Color.clear
                .tabItem {
                    Label("撮る", systemImage: "camera.fill")
                }
                .tag(AppTab.capture)

            // Tab 3: イベント
            RootNavigationView(coordinator: coordinator)
                .tabItem {
                    Label("イベント", systemImage: "calendar")
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

        // MARK: - Event Select Sheet

        .sheet(isPresented: $showEventSelectSheet) {
            EventSelectSheet(
                events: captureEvents,
                onEventSelected: { event in
                    showEventSelectSheet = false
                    captureSelectedEvent = event
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCaptureActionSheet = true
                    }
                },
                onDismiss: {
                    showEventSelectSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }

        // MARK: - Capture Action Sheet

        .sheet(isPresented: $showCaptureActionSheet) {
            if let event = captureSelectedEvent {
                captureActionSheetContent(for: event)
                    .presentationDetents([.height(280)])
            }
        }

        // MARK: - Modal Presentations (shared across tabs)

        .sheet(isPresented: $coordinator.showCreateEvent, onDismiss: {
            coordinator.editingEvent = nil
        }) {
            NavigationStack {
                EventCreateScreen(event: coordinator.editingEvent)
            }
            .interactiveDismissDisabled(false)
        }

        .sheet(isPresented: $coordinator.showPhotoPicker) {
            if let event = coordinator.selectedEvent {
                PhotoPickerScreen(
                    event: event,
                    selectedImage: Binding(
                        get: { coordinator.selectedImage },
                        set: { coordinator.selectedImage = $0 }
                    ),
                    isPresented: $coordinator.showPhotoPicker,
                    onImageSelected: { image in
                        coordinator.showPhotoPicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            coordinator.navigateToEditor(image: image, event: event)
                        }
                    }
                )
            }
        }

        .fullScreenCover(isPresented: $coordinator.showCamera) {
            if let event = coordinator.selectedEvent {
                CameraScreen(
                    event: event,
                    onImageCaptured: { image in
                        coordinator.showCamera = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            coordinator.navigateToEditor(image: image, event: event)
                        }
                    },
                    onPickerRequested: {
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

        .fullScreenCover(isPresented: $coordinator.showEditor, onDismiss: {
            coordinator.capturedImage = nil
            coordinator.selectedImage = nil
            NotificationCenter.default.post(name: .libraryDidChange, object: nil)
        }) {
            if let image = coordinator.capturedImage,
               let event = coordinator.selectedEvent {
                EditorScreen(
                    viewModel: EditorViewModel(image: image, event: event)
                )
            }
        }

        // MARK: - No Events Alert

        .alert("イベントがありません", isPresented: $showNoEventsAlert) {
            Button("イベントを作成") {
                selectedTab = .events
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    coordinator.navigateToCreateEvent()
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を撮るにはイベントを作成してください")
        }
    }

    // MARK: - Capture Tab Logic

    private func handleCaptureTabTapped() {
        do {
            let events = try AppDependencies.shared.eventRepository.fetchAll(
                isArchived: false,
                sort: "last_used_at"
            )
            captureEvents = events

            switch events.count {
            case 0:
                showNoEventsAlert = true

            case 1:
                // Skip event selection – go directly to action sheet
                captureSelectedEvent = events[0]
                showCaptureActionSheet = true

            default:
                showEventSelectSheet = true
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
                    showCaptureActionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.navigateToCamera(event: event)
                    }
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DSColors.accent)
                            .frame(width: 32)
                        Text("カメラで撮る")
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
                    showCaptureActionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        coordinator.navigateToPhotoPicker(event: event)
                    }
                } label: {
                    HStack(spacing: DSSpacing.md) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20))
                            .foregroundStyle(DSColors.warning)
                            .frame(width: 32)
                        Text("写真から選ぶ")
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
