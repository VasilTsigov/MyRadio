import SwiftUI

struct ContentView: View {
    @StateObject private var player = RadioPlayer.shared
    @State private var stations: [RadioStation] = hardcodedStations
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                stationList
                if player.currentStation != nil {
                    nowPlayingBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Моето радио")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await loadNearbyStations()
        }
    }

    // MARK: - Station List

    private var stationList: some View {
        List(stations) { station in
            let isSelected = player.currentStation == station
            let isPlaying  = isSelected && player.isPlaying
            let isBuffering = isSelected && player.isBuffering

            StationRowView(
                station: station,
                isPlaying: isPlaying,
                isBuffering: isBuffering,
                nowPlayingInfo: isPlaying ? player.nowPlayingInfo : nil
            ) {
                player.play(station)
            }
            .listRowBackground(
                isSelected
                    ? Color(.systemGray5).ignoresSafeArea()
                    : Color(.systemBackground).ignoresSafeArea()
            )
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
            if player.currentStation != nil {
                Color.clear.frame(height: 80)
            }
        }
        .overlay(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Now Playing Bar

    private var nowPlayingBar: some View {
        HStack(spacing: 12) {
            SoundWaveView(isPlaying: player.isPlaying, isBuffering: player.isBuffering)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentStation?.name ?? "")
                    .font(.headline)
                    .lineLimit(1)
                if player.isBuffering {
                    Text("Зарежда...")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                } else if let info = player.nowPlayingInfo {
                    Text(info)
                        .font(.caption)
                        .lineLimit(1)
                        .transition(.opacity)
                } else {
                    Text(player.currentStation?.description ?? "")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                player.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .padding(10)
                    .background(Color(.systemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.accentColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.accentColor.opacity(0.4), radius: 10, y: 4)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .colorScheme(.dark)
    }

    // MARK: - Station Discovery

    private func loadNearbyStations() async {
        isLoading = true
        let discovered = await StationRepository.shared.fetchNearbyStations(existing: stations)
        if !discovered.isEmpty {
            stations.append(contentsOf: discovered)
        }
        isLoading = false
    }
}

// MARK: - Sound Wave Visualizer

struct SoundWaveView: View {
    let isPlaying: Bool
    let isBuffering: Bool

    @State private var heights: [CGFloat] = [0.35, 0.6, 0.4]

    private let durations: [Double] = [0.45, 0.35, 0.55]

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 4, height: 28 * heights[i])
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: durations[i]).repeatForever(autoreverses: true)
                            : .easeOut(duration: 0.2),
                        value: heights[i]
                    )
            }
        }
        .onAppear { updateHeights() }
        .onChange(of: isPlaying) { _ in updateHeights() }
    }

    private func updateHeights() {
        if isPlaying {
            for i in 0..<3 {
                let target: CGFloat = i == 0 ? 0.9 : (i == 1 ? 0.5 : 0.75)
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                    heights[i] = target
                }
            }
        } else {
            heights = [0.2, 0.2, 0.2]
        }
    }
}

// MARK: - Station Row

struct StationRowView: View {
    let station: RadioStation
    let isPlaying: Bool
    let isBuffering: Bool
    let nowPlayingInfo: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color.accentColor : Color(.systemFill))
                        .frame(width: 44, height: 44)
                    if isBuffering {
                        ProgressView()
                            .tint(isPlaying ? .white : .accentColor)
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isPlaying ? Color.white : Color.accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(station.name)
                        .font(.body)
                        .fontWeight(isPlaying ? .semibold : .regular)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isPlaying, let info = nowPlayingInfo {
                        Text(info)
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(1)
                            .transition(.opacity)
                    } else if !station.description.isEmpty {
                        Text(station.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
