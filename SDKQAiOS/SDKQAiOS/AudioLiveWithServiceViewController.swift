//
//  AudioLiveWithServiceViewController.swift
//  SDKQAiOS
//
//  Audio Live con “servicio” en iOS = mismo stream live que Audio Live pero con
//  Now Playing (Control Center / pantalla de bloqueo) para reproducir en segundo plano
//  y controlar desde la notificación. Equivalente a Android “Live Audio with Service”.
//

import UIKit
import MediastreamPlatformSDKiOS

class AudioLiveWithServiceViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio: Live with Service"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "5c915724519bce27671c4d15"
        playerConfig.type = .LIVE
        playerConfig.debug = true
        playerConfig.customUI = true
        // Now Playing = Control Center / Lock Screen (equivalente a “servicio”/notificación en Android)
        playerConfig.updatesNowPlayingInfoCenter = true
        // Descomentar para entorno de desarrollo:
        // playerConfig.environment = .DEV

        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.didMove(toParent: self)

        mdstrm.setup(playerConfig)
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
