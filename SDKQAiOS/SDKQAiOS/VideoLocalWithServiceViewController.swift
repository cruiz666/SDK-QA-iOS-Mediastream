//
//  VideoLocalWithServiceViewController.swift
//  SDKQAiOS
//
//  Video Local con servicio: mismo contenido que Video Local pero con integración
//  de “servicio” en iOS = Picture in Picture (PiP) + Control Center.
//  Equivalente a Android VideoLocalWithServiceActivity (reproducción en servicio/notificación).
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoLocalWithServiceViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Local (with Service)"
        view.backgroundColor = .black

        guard let videoURL = Bundle.main.url(forResource: "sample_video", withExtension: "mp4") else {
            let label = UILabel()
            label.text = "Añade sample_video.mp4 al target\n(Copy Bundle Resources)\nPuedes copiarlo desde SDKQA/app/src/main/res/raw/"
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
        playerConfig.src = videoURL as NSURL
        playerConfig.id = "local-video"
        playerConfig.type = .VOD
        playerConfig.showControls = true
        playerConfig.debug = true
        playerConfig.customUI = true
        // Servicio en iOS: PiP + Control Center
        playerConfig.updatesNowPlayingInfoCenter = true
        playerConfig.canStartPictureInPictureAutomaticallyFromInline = true

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
