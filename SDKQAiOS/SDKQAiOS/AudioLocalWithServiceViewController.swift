//
//  AudioLocalWithServiceViewController.swift
//  SDKQAiOS
//
//  Audio Local con “servicio” en iOS = mismo archivo local que Audio Local pero con
//  Now Playing (Control Center / pantalla de bloqueo) para reproducir en segundo plano
//  y controlar desde la notificación. Equivalente a Android “Local Audio with Service”.
//

import UIKit
import MediastreamPlatformSDKiOS

class AudioLocalWithServiceViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Audio: Local with Service"
        view.backgroundColor = .black

        guard let audioURL = Bundle.main.url(forResource: "sample_audio", withExtension: "mp3") else {
            let label = UILabel()
            label.text = "Añade sample_audio.mp3 al target\n(Copy Bundle Resources)"
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
            ])
            return
        }

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.src = audioURL as NSURL
        playerConfig.id = "local-audio"
        playerConfig.type = .VOD
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
