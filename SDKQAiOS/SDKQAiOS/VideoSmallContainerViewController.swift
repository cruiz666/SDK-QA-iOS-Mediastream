//
//  VideoSmallContainerViewController.swift
//  SDKQAiOS
//
//  Video Small Container: player en la parte superior (1/4 de pantalla) y contenido dummy abajo.
//  Config igual a Video VOD Simple.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoSmallContainerViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?
    /// Cuando el reproductor está en fullscreen, permitimos landscape y forzamos esa orientación.
    private var isPlayerFullscreen = false

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
        title = "Video: Small Container"
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

        NSLayoutConstraint.activate([
            mdstrm.view.topAnchor.constraint(equalTo: playerContainerView.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: playerContainerView.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: playerContainerView.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: playerContainerView.bottomAnchor)
        ])

        mdstrm.setup(playerConfig)
        mdstrm.play()
        sdk = mdstrm

        NSLog("[SDK-QA] VideoSmallContainer: registrando listeners onFullscreen / offFullscreen")
        mdstrm.events.listenTo(eventName: "onFullscreen", action: { [weak self] in
            NSLog("[SDK-QA] VideoSmallContainer: evento onFullscreen recibido")
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.applyFullscreenLayout()
            }
        })
        mdstrm.events.listenTo(eventName: "offFullscreen", action: { [weak self] in
            NSLog("[SDK-QA] VideoSmallContainer: evento offFullscreen recibido")
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.exitFullscreenLayout()
            }
        })
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if isPlayerFullscreen {
            return .landscape
        }
        return .portrait
    }

    /// Hace que la vista del reproductor ocupe toda la ventana y fuerza orientación landscape.
    private func applyFullscreenLayout() {
        isPlayerFullscreen = true
        guard let playerView = sdk?.view else { return }
        let window = playerView.window ?? keyWindow
        if let w = window {
            playerView.translatesAutoresizingMaskIntoConstraints = true
            playerView.frame = w.bounds
            playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            NSLog("[SDK-QA] VideoSmallContainer: frame player = \(w.bounds)")
        }
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        NSLog("[SDK-QA] VideoSmallContainer: isPlayerFullscreen=true, orientación forzada landscape")
    }

    private func exitFullscreenLayout() {
        isPlayerFullscreen = false
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
        NSLog("[SDK-QA] VideoSmallContainer: isPlayerFullscreen=false, orientación forzada portrait")
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

        Este es un caso de prueba para el reproductor en contenedor pequeño (1/4 de pantalla). El resto del espacio simula una pantalla de detalle con texto u otro contenido.
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

        let moreText = "Contenido dummy para rellenar el área inferior. Puedes reemplazar esto por listas, cards o cualquier otro layout."
        let moreLabel = UILabel()
        moreLabel.text = moreText
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
