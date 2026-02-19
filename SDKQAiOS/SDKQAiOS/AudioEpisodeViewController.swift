//
//  AudioEpisodeViewController.swift
//  SDKQAiOS
//
//  Audio Episode: mismos IDs y config que Android AudioEpisodeActivity.
//  Reproducción de episodios con carga automática del siguiente.
//

import UIKit
import MediastreamPlatformSDKiOS

class AudioEpisodeViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio: Episode"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "6193f836de7392082f8377dc"
        playerConfig.type = .EPISODE
        playerConfig.videoFormat = .MP3
        playerConfig.showControls = true
        playerConfig.loadNextAutomatically = true
        playerConfig.debug = true
        playerConfig.customUI = true
        playerConfig.updatesNowPlayingInfoCenter = true
        // Descomentar para entorno de desarrollo:
        // playerConfig.environment = .DEV

        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.didMove(toParent: self)

        mdstrm.setup(playerConfig)
        SDKEventListeners.attachAll(to: mdstrm)
        mdstrm.play()
        sdk = mdstrm
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sdk?.view.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
