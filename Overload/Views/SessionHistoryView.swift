import SwiftData
import SwiftUI

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SessionHistoryViewModel?
    @State private var selectedSession: WorkoutSession?
    @State private var deletingSession: WorkoutSession?

    var body: some View {
        Group {
            if let viewModel {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if viewModel.sessions.isEmpty {
                            ContentUnavailableView(
                                "No sessions yet",
                                systemImage: "clock.arrow.circlepath",
                                description: Text("Completed workouts will appear here.")
                            )
                            .foregroundStyle(OverloadTheme.secondaryText)
                            .padding(.top, 80)
                        }

                        ForEach(viewModel.sessions) { session in
                            SessionHistoryCard(
                                session: session,
                                onOpen: { selectedSession = session },
                                onDelete: { deletingSession = session }
                            )
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    viewModel.reload()
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Session History")
        .overloadScreenBackground()
        .task {
            if viewModel == nil {
                viewModel = SessionHistoryViewModel(context: modelContext)
            } else {
                viewModel?.reload()
            }
        }
        .sheet(item: $selectedSession, onDismiss: {
            viewModel?.reload()
        }) { session in
            WorkoutLoggerView(existingSession: session)
        }
        .confirmationDialog(
            "Delete session?",
            isPresented: Binding(
                get: { deletingSession != nil },
                set: { if !$0 { deletingSession = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Session", role: .destructive) {
                if let deletingSession {
                    viewModel?.deleteSession(deletingSession)
                }
                deletingSession = nil
            }
            Button("Cancel", role: .cancel) {
                deletingSession = nil
            }
        }
    }
}

private struct SessionHistoryCard: View {
    var session: WorkoutSession
    var onOpen: () -> Void
    var onDelete: () -> Void

    var body: some View {
        DarkCard {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.workoutTemplate?.name ?? "Custom Workout")
                        .font(.headline)
                        .foregroundStyle(OverloadTheme.primaryText)
                    Text(DateFormatters.isoDay.string(from: session.date))
                        .font(.subheadline)
                        .foregroundStyle(OverloadTheme.secondaryText)

                    HStack(spacing: 8) {
                        SessionBadge(text: "\(Int(session.totalVolume)) lbs volume")
                        SessionBadge(text: "\(session.sessionExercises.count) exercises")
                        SessionBadge(text: session.isCompleted ? "Completed" : "Draft")
                    }
                }

                Spacer()

                Menu {
                    Button("Open", action: onOpen)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 36, height: 36)
                        .background(OverloadTheme.elevated)
                        .clipShape(Circle())
                }
            }
        }
        .onTapGesture(perform: onOpen)
    }
}

private struct SessionBadge: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(OverloadTheme.secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(OverloadTheme.elevated)
            .clipShape(Capsule())
    }
}
