//
//  VideoSmallContainerRotationViewController.swift
//  SDKQAiOS
//
//  Video Small Container con rotación automática: landscape al entrar en fullscreen,
//  portrait al salir. El reproductor vuelve al contenedor original tras salir del fullscreen.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoSmallContainerRotationViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?
    private var isPlayerFullscreen = false
    private var playerContainerConstraints: [NSLayoutConstraint] = []

    private let playerContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private let contentScrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.alwaysBounceVertical = true
        return s
    }()

    private let contentStackView: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.spacing = 16
        s.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        s.isLayoutMarginsRelativeArrangement = true
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Small Container + Rotation"
        view.backgroundColor = .systemBackground

        view.addSubview(playerContainerView)
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            playerContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25),

            contentScrollView.topAnchor.constraint(equalTo: playerContainerView.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor)
        ])

        addDummyContent()
        setupPlayer()
    }

    private func setupPlayer() {
        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "685be889d76b0da57e68620e"
        playerConfig.type = .VOD
        playerConfig.debug = true
        playerConfig.customUI = true

        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        playerContainerView.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)

        let constraints = [
            mdstrm.view.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        playerContainerConstraints = constraints

        mdstrm.setup(playerConfig)
        SDKEventListeners.attachAll(to: mdstrm)
        mdstrm.play()
        sdk = mdstrm

        NSLog("[SDK-QA] VideoSmallContainerRotation: registrando listeners onFullscreen / offFullscreen")
        mdstrm.events.listenTo(eventName: "onFullscreen", action: { [weak self] in
            NSLog("[SDK-QA] VideoSmallContainerRotation: evento onFullscreen recibido")
            guard let self = self else { return }
            DispatchQueue.main.async { self.enterFullscreen() }
        })
        mdstrm.events.listenTo(eventName: "offFullscreen", action: { [weak self] in
            NSLog("[SDK-QA] VideoSmallContainerRotation: evento offFullscreen recibido")
            guard let self = self else { return }
            DispatchQueue.main.async { self.exitFullscreen() }
        })
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        isPlayerFullscreen ? .landscape : .portrait
    }

    private func enterFullscreen() {
        isPlayerFullscreen = true
        guard let playerView = sdk?.view, let window = playerView.window ?? keyWindow else { return }

        // Mover la vista del reproductor a la ventana para cubrir toda la pantalla
        playerView.translatesAutoresizingMaskIntoConstraints = true
        window.addSubview(playerView)
        playerView.frame = window.bounds
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        rotateToOrientation(.landscapeLeft)
        NSLog("[SDK-QA] VideoSmallContainerRotation: enterFullscreen, orientación landscape")
    }

    private func exitFullscreen() {
        isPlayerFullscreen = false
        guard let playerView = sdk?.view else { return }

        // Restaurar la vista del reproductor al contenedor original
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerContainerView.addSubview(playerView)
        NSLayoutConstraint.activate(playerContainerConstraints)

        rotateToOrientation(.portrait)
        NSLog("[SDK-QA] VideoSmallContainerRotation: exitFullscreen, orientación portrait")
    }

    private func rotateToOrientation(_ orientation: UIInterfaceOrientation) {
        if #available(iOS 16.0, *) {
            guard let scene = view.window?.windowScene else { return }
            let mask: UIInterfaceOrientationMask = orientation == .portrait ? .portrait : .landscapeLeft
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask)) { error in
                NSLog("[SDK-QA] VideoSmallContainerRotation: requestGeometryUpdate error: \(error.localizedDescription)")
            }
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return UIApplication.shared.keyWindow
    }

    private func addDummyContent() {
        let titleLabel = UILabel()
        titleLabel.text = "Contenido de ejemplo"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(titleLabel)

        let bodyText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.

        Este es un caso de prueba para el reproductor en contenedor pequeño con rotación automática al entrar/salir del fullscreen.
        """
        let bodyLabel = UILabel()
        bodyLabel.text = bodyText
        bodyLabel.font = .systemFont(ofSize: 16)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(bodyLabel)

        let sectionLabel = UILabel()
        sectionLabel.text = "Sección adicional"
        sectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        sectionLabel.textColor = .label
        contentStackView.addArrangedSubview(sectionLabel)

        let moreLabel = UILabel()
        moreLabel.text = "Contenido dummy para rellenar el área inferior. Al presionar fullscreen la pantalla rotará a landscape y al salir volverá a portrait."
        moreLabel.font = .systemFont(ofSize: 15)
        moreLabel.textColor = .tertiaryLabel
        moreLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(moreLabel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
