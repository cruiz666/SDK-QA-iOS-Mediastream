//
//  AudioLiveViewController.swift
//  SDKQAiOS
//
//  Audio Live: mismos IDs y config que Android AudioLiveActivity.
//  Streaming de audio en vivo.
//

import UIKit
import MediastreamPlatformSDKiOS

class AudioLiveViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio: Live"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "632c9b23d1dcd7027f32f7fe"
        playerConfig.type = .LIVE
        playerConfig.debug = true
        //playerConfig.customUI = true
        playerConfig.showControls = false
        playerConfig.dvr = true
        playerConfig.dvrStart = "2026-02-26T16:00:00.000Z"
        //playerConfig.adURL = "no-ads"
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
