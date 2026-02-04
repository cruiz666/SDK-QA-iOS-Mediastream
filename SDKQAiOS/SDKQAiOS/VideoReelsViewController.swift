//
//  VideoReelsViewController.swift
//  SDKQAiOS
//
//  Reels: mismo enfoque que MediastreamSampleApp ReelActivity.
//  Config: id, playerId, type VOD, DEV, trackEnable false, showDismissButton, autoplay.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoReelsViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Reels"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "6772da3c808e6ac7b86edb06"
        playerConfig.playerId = "677ee96edbb8fa932f3433cc"
        playerConfig.type = .VOD
        playerConfig.debug = true
        playerConfig.environment = .DEV
        playerConfig.trackEnable = false
        playerConfig.showDismissButton = true
        playerConfig.autoplay = true
        // pauseOnScreenClick = DISABLE en Android; en iOS no hay equivalente directo en config

        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)

        NSLayoutConstraint.activate([
            mdstrm.view.topAnchor.constraint(equalTo: view.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        mdstrm.setup(playerConfig)
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
