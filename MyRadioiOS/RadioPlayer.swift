import AVFoundation
import MediaPlayer
import Combine

/// Observable singleton that owns the AVPlayer and manages background audio.
/// Equivalent to RadioService on Android.
@MainActor
final class RadioPlayer: ObservableObject {

    static let shared = RadioPlayer()

    @Published private(set) var currentStation: RadioStation?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false

    private var player: AVPlayer?
    private var timeControlObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?

    private init() {
        configureAudioSession()
        configureRemoteCommands()
    }

    // MARK: - Public API

    func play(_ station: RadioStation) {
        guard let url = URL(string: station.streamUrl) else { return }

        // If same station is already loaded, just resume
        if currentStation == station, let player {
            player.play()
            return
        }

        stopObservers()
        player?.pause()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        currentStation = station
        isBuffering = true

        observePlayer(newPlayer)
        newPlayer.play()
        updateNowPlayingInfo()
    }

    func stop() {
        player?.pause()
        isPlaying = false
        isBuffering = false
        currentStation = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Lock Screen / Remote Commands

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            guard let self, let station = self.currentStation else { return .noActionableNowPlayingItem }
            self.play(station)
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        center.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }

        // Disable commands that don't apply to radio
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
    }

    private func updateNowPlayingInfo() {
        guard let station = currentStation else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: station.name,
            MPMediaItemPropertyArtist: station.description,
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]
    }

    // MARK: - KVO

    private func observePlayer(_ p: AVPlayer) {
        timeControlObserver = p.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.isPlaying = true
                    self.isBuffering = false
                case .waitingToPlayAtSpecifiedRate:
                    self.isPlaying = false
                    self.isBuffering = true
                case .paused:
                    self.isPlaying = false
                    self.isBuffering = false
                @unknown default:
                    break
                }
                self.updateNowPlayingInfo()
            }
        }

        statusObserver = p.currentItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed {
                Task { @MainActor [weak self] in
                    self?.isPlaying = false
                    self?.isBuffering = false
                }
            }
        }
    }

    private func stopObservers() {
        timeControlObserver?.invalidate()
        timeControlObserver = nil
        statusObserver?.invalidate()
        statusObserver = nil
    }
}
