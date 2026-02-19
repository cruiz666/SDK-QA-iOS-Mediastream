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
        playerConfig.id = "5c915724519bce27671c4d15"
        playerConfig.type = .LIVE
        playerConfig.debug = true
        playerConfig.customUI = true
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
