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
            StationRowView(station: station, isPlaying: player.currentStation == station && player.isPlaying, isBuffering: player.currentStation == station && player.isBuffering) {
                if player.currentStation == station {
                    player.stop()
                } else {
                    player.play(station)
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
            // Reserve space for the now-playing bar
            if player.currentStation != nil {
                Color.clear.frame(height: 72)
            }
        }
        .overlay(alignment: .center) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Now Playing Bar

    private var nowPlayingBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentStation?.name ?? "")
                    .font(.headline)
                    .lineLimit(1)
                if player.isBuffering {
                    Text("Зарежда...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(player.currentStation?.description ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
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

// MARK: - Station Row

struct StationRowView: View {
    let station: RadioStation
    let isPlaying: Bool
    let isBuffering: Bool
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
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isPlaying ? .white : .accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(station.name)
                        .font(.body)
                        .fontWeight(isPlaying ? .semibold : .regular)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !station.description.isEmpty {
                        Text(station.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
