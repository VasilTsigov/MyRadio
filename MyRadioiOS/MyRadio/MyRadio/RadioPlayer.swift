import AVFoundation
import MediaPlayer
import Combine

/// Observable singleton that owns the AVPlayer and manages background audio.
@MainActor
final class RadioPlayer: ObservableObject {

    static let shared = RadioPlayer()

    @Published private(set) var currentStation: RadioStation?
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published private(set) var nowPlayingInfo: String?   // "Изпълнител – Песен"

    private var player: AVPlayer?
    private var timeControlObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var metadataOutput: AVPlayerItemMetadataOutput?
    private var metadataDelegate: MetadataOutputDelegate?

    private init() {
        configureAudioSession()
        configureRemoteCommands()
    }

    // MARK: - Public API

    func play(_ station: RadioStation) {
        guard let url = URL(string: station.streamUrl) else { return }

        if currentStation == station, let player {
            player.play()
            return
        }

        stopObservers()
        player?.pause()
        nowPlayingInfo = nil

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        currentStation = station
        isBuffering = true

        observePlayer(newPlayer)
        setupMetadataOutput(for: item)
        newPlayer.play()
        updateLockScreen()
    }

    func stop() {
        player?.pause()
        isPlaying = false
        isBuffering = false
        currentStation = nil
        nowPlayingInfo = nil
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

    // MARK: - Metadata (ICY / HLS timed metadata)

    private func setupMetadataOutput(for item: AVPlayerItem) {
        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        let delegate = MetadataOutputDelegate { [weak self] title in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.nowPlayingInfo = title
                self.updateLockScreen()
            }
        }
        output.setDelegate(delegate, queue: .main)
        item.add(output)
        metadataOutput = output
        metadataDelegate = delegate
    }

    // MARK: - Lock Screen

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
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
    }

    private func updateLockScreen() {
        guard let station = currentStation else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlayingInfo ?? station.name,
            MPMediaItemPropertyArtist: station.name,
            MPNowPlayingInfoPropertyIsLiveStream: true,
        ]
        if nowPlayingInfo != nil {
            info[MPMediaItemPropertyAlbumTitle] = station.description
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
                self.updateLockScreen()
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
        metadataOutput = nil
        metadataDelegate = nil
    }
}

// MARK: - Metadata delegate (non-actor, bridges to MainActor via callback)

private final class MetadataOutputDelegate: NSObject, AVPlayerItemMetadataOutputPushDelegate {
    let onMetadata: (String?) -> Void

    init(_ onMetadata: @escaping (String?) -> Void) {
        self.onMetadata = onMetadata
    }

    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        // Search for StreamTitle (ICY) or common title (HLS)
        for group in groups {
            for item in group.items {
                if let value = item.stringValue, !value.isEmpty {
                    onMetadata(value)
                    return
                }
            }
        }
    }
}
