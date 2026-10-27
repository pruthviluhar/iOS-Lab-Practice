
import SwiftUI
import Combine

struct StopwatchLap: Identifiable {
    let id = UUID()
    let number: Int
    let time: TimeInterval
}

struct StopwatchView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var isRunning = false
    @State private var accumulatedTime: TimeInterval = 0
    @State private var startDate: Date?
    @State private var displayTime: TimeInterval = 0
    @State private var laps: [StopwatchLap] = []
    @State private var lastLapTime: TimeInterval = 0

    private let timer = Timer.publish(
        every: 0.01,
        on: .main,
        in: .common
    ).autoconnect()

    private var elapsedTime: TimeInterval {
        guard isRunning, let startDate else {
            return accumulatedTime
        }
        return accumulatedTime + Date().timeIntervalSince(startDate)
    }

    private var fastestLapID: UUID? {
        guard laps.count >= 2 else { return nil }
        return laps.min { $0.time < $1.time }?.id
    }

    private var slowestLapID: UUID? {
        guard laps.count >= 2 else { return nil }
        return laps.max { $0.time < $1.time }?.id
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Stopwatch display
                Text(formatTime(displayTime))
                    .font(.system(size: 58, weight: .light, design: .monospaced))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                // Stopwatch buttons
                HStack(spacing: 18) {
                    Button(action: resetStopwatch) {
                        Text("Reset")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                    .disabled(isRunning || (accumulatedTime == 0 && laps.isEmpty))

                    Button(action: toggleStopwatch) {
                        Text(isRunning ? "Pause" : "Start")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(isRunning ? Color.orange : Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    Button(action: recordLap) {
                        Text("Lap")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.gray.opacity(0.15))
                            .foregroundStyle(isRunning ? .primary : .secondary)
                            .clipShape(Capsule())
                    }
                    .disabled(!isRunning)
                }
                .buttonStyle(.plain)

                Spacer()

                // Lap list
                HStack {
                    Text("Laps")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Text("Time")
                        .font(.title3.weight(.semibold))
                }
                .padding(.horizontal, 4)

                Divider()

                if laps.isEmpty {
                    Spacer()
                    Text("No laps recorded")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(laps) { lap in
                            HStack {
                                Text("Lap \(lap.number)")

                                Spacer()

                                if lap.id == fastestLapID {
                                    Text("Fastest")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if lap.id == slowestLapID {
                                    Text("Slowest")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }

                                Text(formatTime(lap.time))
                                    .font(.system(.body, design: .monospaced))
                                    .monospacedDigit()
                                    .frame(minWidth: 100, alignment: .trailing)
                                    .foregroundStyle(lapColor(lap))
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Stopwatch")
            .onReceive(timer) { _ in
                if isRunning {
                    displayTime = elapsedTime
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    displayTime = elapsedTime
                }
            }
        }
    }

    private func toggleStopwatch() {
        if isRunning {
            accumulatedTime = elapsedTime
            displayTime = accumulatedTime
            startDate = nil
            isRunning = false
        } else {
            startDate = Date()
            isRunning = true
        }
    }

    private func resetStopwatch() {
        isRunning = false
        accumulatedTime = 0
        displayTime = 0
        startDate = nil
        lastLapTime = 0
        laps.removeAll()
    }

    private func recordLap() {
        guard isRunning else { return }

        let total = elapsedTime
        let lapDuration = total - lastLapTime

        let lap = StopwatchLap(
            number: laps.count + 1,
            time: lapDuration
        )

        laps.insert(lap, at: 0)
        lastLapTime = total
    }

    private func lapColor(_ lap: StopwatchLap) -> Color {
        guard laps.count >= 2 else { return .primary }

        if lap.id == fastestLapID { return .green }
        if lap.id == slowestLapID { return .red }

        return .primary
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let value = max(0, Int((time * 100).rounded(.down)))
        let minutes = value / 6000
        let seconds = (value / 100) % 60
        let milliseconds = value % 100

        return String(
            format: "%02d:%02d.%02d",
            minutes,
            seconds,
            milliseconds
        )
    }
}

#Preview {
    StopwatchView()
}
