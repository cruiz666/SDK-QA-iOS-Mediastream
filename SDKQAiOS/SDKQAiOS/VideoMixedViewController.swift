//
//  VideoMixedViewController.swift
//  SDKQAiOS
//
//  Video Mixed (simple, sin servicio/PiP): mismo enfoque que Android VideoMixedActivity.
//  Selector dinámico entre Local, VOD, Live y Episode (sin PiP ni Control Center).
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoMixedViewController: UIViewController {

    private static let vodId = "685be889d76b0da57e68620e"
    private static let liveId = "6824d425c3ae719205f54245"
    private static let episodeId = "696808734a117b1460e8e4f8"

    private let modes = ["Local", "VOD", "Live", "Episode"]
    private var sdk: MediastreamPlatformSDK?
    private var currentModeIndex = 0
    private var hasLocalFile: Bool = false

    private lazy var modeLabel: UILabel = {
        let label = UILabel()
        label.text = "CONTENT"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var modeSegmented: UISegmentedControl = {
        let control = UISegmentedControl(items: modes)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = UIColor.systemTeal
        }
        return control
    }()

    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor(white: 0.12, alpha: 1)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Mixed"
        view.backgroundColor = .black

        hasLocalFile = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") != nil
        if !hasLocalFile, let idx = modes.firstIndex(of: "Local") {
            var items = modes
            items.remove(at: idx)
            modeSegmented.removeAllSegments()
            for (i, title) in items.enumerated() {
                modeSegmented.insertSegment(withTitle: title, at: i, animated: false)
            }
            modeSegmented.selectedSegmentIndex = 0
            currentModeIndex = 0
        }

        let config = configForMode(modeSegmented.selectedSegmentIndex)
        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)
        sdk = mdstrm

        view.addSubview(bottomBar)
        bottomBar.addSubview(modeLabel)
        bottomBar.addSubview(modeSegmented)

        NSLayoutConstraint.activate([
            mdstrm.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 88),

            modeLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            modeLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            modeLabel.trailingAnchor.constraint(lessThanOrEqualTo: bottomBar.trailingAnchor, constant: -16),

            modeSegmented.topAnchor.constraint(equalTo: modeLabel.bottomAnchor, constant: 8),
            modeSegmented.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            modeSegmented.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            modeSegmented.heightAnchor.constraint(equalToConstant: 32)
        ])

        mdstrm.setup(config)
        mdstrm.play()
    }

    @objc private func modeChanged() {
        let newIndex = modeSegmented.selectedSegmentIndex
        guard newIndex != currentModeIndex else { return }
        currentModeIndex = newIndex
        let config = configForMode(newIndex)
        sdk?.reloadPlayer(config)
    }

    private func configForMode(_ index: Int) -> MediastreamPlayerConfig {
        let config = MediastreamPlayerConfig()
        config.showControls = true
        config.debug = true
        config.customUI = true
        // Sin servicio/PiP: no updatesNowPlayingInfoCenter, no canStartPictureInPictureAutomaticallyFromInline
        // config.environment = .DEV

        let modeName: String
        if hasLocalFile {
            modeName = modes[index]
        } else {
            let reduced = modes.filter { $0 != "Local" }
            modeName = index < reduced.count ? reduced[index] : "VOD"
        }

        switch modeName {
        case "Local":
            if let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") {
                config.src = videoURL as NSURL
                config.id = "local-video"
                config.type = .VOD
            }
        case "VOD":
            config.id = Self.vodId
            config.type = .VOD
        case "Episode":
            config.id = Self.episodeId
            config.type = .EPISODE
            config.loadNextAutomatically = true
        case "Live":
            config.id = Self.liveId
            config.type = .LIVE
        default:
            config.id = Self.vodId
            config.type = .VOD
        }
        return config
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
