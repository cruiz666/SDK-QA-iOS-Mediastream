//
//  AudioAodSimpleViewController.swift
//  SDKQAiOS
//
//  Audio AOD Simple: mismos IDs y config que Android AudioAodSimpleActivity.
//

import UIKit
import MediastreamPlatformSDKiOS

class AudioAodSimpleViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio: AOD Simple"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "67ae0ec86dcc4a0dca2e9b00"
        playerConfig.type = .VOD
        playerConfig.videoFormat = .MP3
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
