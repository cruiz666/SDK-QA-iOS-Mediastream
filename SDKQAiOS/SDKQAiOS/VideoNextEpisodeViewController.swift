//
//  VideoNextEpisodeViewController.swift
//  SDKQAiOS
//
//  Video Next Episode: mismo enfoque que Android VideoNextEpisodeActivity.
//  Modos: Next Episode (episodio con siguiente desde API) y Next Episode Custom (VOD con cadena de IDs).
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoNextEpisodeViewController: UIViewController {

    private static let nextEpisodeId = "6839b2d6a4149963bfe295e0"
    private static let nextEpisodeCustomId = "68891e8d1856d6378f5d81fa"
    private let nextEpisodeIds = ["6892591911582875cc48b239", "689f6396ef81e4c28ba9644b"]

    private var sdk: MediastreamPlatformSDK?
    private var currentMode = "NEXT_EPISODE"
    private var currentEpisodeIndex = 0

    private lazy var modeLabel: UILabel = {
        let label = UILabel()
        label.text = "MODE"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var nextEpisodeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next Episode", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(switchToNextEpisode), for: .touchUpInside)
        return btn
    }()

    private lazy var nextEpisodeCustomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Next Episode Custom", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(switchToNextEpisodeCustom), for: .touchUpInside)
        return btn
    }()

    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor(white: 0.1, alpha: 1)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    private lazy var buttonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nextEpisodeButton, nextEpisodeCustomButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Next Episode"
        view.backgroundColor = .black

        let config = configForMode("NEXT_EPISODE")
        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)
        sdk = mdstrm

        view.addSubview(bottomBar)
        bottomBar.addSubview(modeLabel)
        bottomBar.addSubview(buttonsStack)

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

            buttonsStack.topAnchor.constraint(equalTo: modeLabel.bottomAnchor, constant: 8),
            buttonsStack.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            buttonsStack.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            buttonsStack.heightAnchor.constraint(equalToConstant: 36)
        ])

        mdstrm.setup(config)
        mdstrm.play()
        setupNextEpisodeIncomingListener(for: "NEXT_EPISODE")
        updateButtonStates()
    }

    @objc private func switchToNextEpisode() {
        guard currentMode != "NEXT_EPISODE" else { return }
        currentMode = "NEXT_EPISODE"
        let config = configForMode("NEXT_EPISODE")
        sdk?.reloadPlayer(config)
        setupNextEpisodeIncomingListener(for: "NEXT_EPISODE")
        updateButtonStates()
    }

    @objc private func switchToNextEpisodeCustom() {
        guard currentMode != "NEXT_EPISODE_CUSTOM" else { return }
        currentMode = "NEXT_EPISODE_CUSTOM"
        currentEpisodeIndex = 0
        let config = configForMode("NEXT_EPISODE_CUSTOM")
        sdk?.reloadPlayer(config)
        setupNextEpisodeIncomingListener(for: "NEXT_EPISODE_CUSTOM")
        updateButtonStates()
    }

    private func configForMode(_ mode: String) -> MediastreamPlayerConfig {
        let config = MediastreamPlayerConfig()
        config.debug = true
        config.customUI = true

        if mode == "NEXT_EPISODE" {
            config.id = Self.nextEpisodeId
            config.type = .EPISODE
            config.environment = .DEV
        } else {
            config.id = Self.nextEpisodeCustomId
            config.type = .VOD
            config.environment = .PRODUCTION
            config.nextEpisodeId = nextEpisodeIds.first
        }
        return config
    }

    private func setupNextEpisodeIncomingListener(for mode: String) {
        sdk?.events.removeListeners(eventNameToRemoveOrNil: "nextEpisodeIncoming")
        let isCustomMode = (mode == "NEXT_EPISODE_CUSTOM")
        sdk?.events.listenTo(eventName: "nextEpisodeIncoming", action: { [weak self] (information: Any?) in
            guard let self = self,
                  let info = information as? [String: Any],
                  let nextId = info["nextEpisodeId"] as? String else { return }
            NSLog("[SDK-QA] nextEpisodeIncoming: %@", nextId)
            if isCustomMode {
                guard let indexInList = self.nextEpisodeIds.firstIndex(of: nextId) else { return }
                let nextIndex = indexInList + 1
                let nextConfig = MediastreamPlayerConfig()
                nextConfig.id = nextId
                nextConfig.type = .VOD
                nextConfig.environment = .PRODUCTION
                nextConfig.debug = true
                nextConfig.customUI = true
                if nextIndex < self.nextEpisodeIds.count {
                    nextConfig.nextEpisodeId = self.nextEpisodeIds[nextIndex]
                }
                self.currentEpisodeIndex = nextIndex
                self.sdk?.updateNextEpisode(nextConfig)
            }
        })
    }

    private func updateButtonStates() {
        if currentMode == "NEXT_EPISODE" {
            nextEpisodeButton.backgroundColor = UIColor.systemBlue
            nextEpisodeButton.setTitleColor(.white, for: .normal)
            nextEpisodeCustomButton.backgroundColor = UIColor.systemGray4
            nextEpisodeCustomButton.setTitleColor(.label, for: .normal)
        } else {
            nextEpisodeButton.backgroundColor = UIColor.systemGray4
            nextEpisodeButton.setTitleColor(.label, for: .normal)
            nextEpisodeCustomButton.backgroundColor = UIColor.systemBlue
            nextEpisodeCustomButton.setTitleColor(.white, for: .normal)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
