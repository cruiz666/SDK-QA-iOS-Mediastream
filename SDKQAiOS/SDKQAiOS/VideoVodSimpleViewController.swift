//
//  VideoVodSimpleViewController.swift
//  SDKQAiOS
//
//  Video VOD Simple: mismos IDs y config que Android VideoVodSimpleActivity.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoVodSimpleViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: VOD Simple"
        view.backgroundColor = .black

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "685be889d76b0da57e68620e"
        playerConfig.type = .VOD
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
