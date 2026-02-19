//
//  VideoEpisodeViewController.swift
//  SDKQAiOS
//
//  Video Episode: mismos IDs y config que Android VideoEpisodeActivity.
//  Reproducción de episodios de video con carga automática del siguiente.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoEpisodeViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Episode"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "6985311bd04b84ebf6400f24"
        playerConfig.type = .EPISODE
        playerConfig.showControls = true
        playerConfig.loadNextAutomatically = true
        playerConfig.debug = true
        playerConfig.customUI = true
        // Descomentar para entorno de desarrollo:
        // playerConfig.environment = .DEV

        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)

        NSLayoutConstraint.activate([
            mdstrm.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        mdstrm.setup(playerConfig)
        SDKEventListeners.attachAll(to: mdstrm)
        mdstrm.play()
        sdk = mdstrm
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
