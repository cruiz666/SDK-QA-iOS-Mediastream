//
//  VideoSmallContainerRotationViewController.swift
//  SDKQAiOS
//
//  Video Small Container con rotación automática + Google Cast.
//  Landscape al entrar en fullscreen, portrait al salir.
//  El reproductor vuelve al contenedor original tras salir del fullscreen.
//

import UIKit
import MediastreamPlatformSDKiOS
import GoogleCast

class VideoSmallContainerRotationViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?
    private var castButton: UIButton?
    private var isPlayerFullscreen = false
    private var playerContainerConstraints: [NSLayoutConstraint] = []

    // MARK: - Cast state

    private var castingBanner: UIView!
    private var castingLabel: UILabel!
    private var disconnectButton: UIButton!

    private var lastKnownCastPositionSeconds: TimeInterval = 0
    private var positionToRestoreWhenCastEnds: TimeInterval?
    private var lastSyncedPositionSeconds: TimeInterval = -1
    private let syncPositionThresholdSeconds: TimeInterval = 1.5
    private var lastSyncedCastPlayingState: Bool?
    private var isSyncingPlayPauseUIFromCast: Bool = false

    // MARK: - Layout

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: Small Container + Rotation + Cast"
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
        setupCastingBanner()
        setupCastSessionListener()
        setupCastDiscoveryLogs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachToCurrentCastSessionIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GCKCastContext.sharedInstance().discoveryManager.remove(self)
        GCKCastContext.sharedInstance().sessionManager.remove(self)
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession {
            session.remoteMediaClient?.remove(self)
        }
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }

    // MARK: - Player setup

    private func setupPlayer() {
        let castBtn = UIButton(type: .system)
        castBtn.setImage(UIImage(systemName: "tv"), for: .normal)
        castBtn.tintColor = .white
        castBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        castBtn.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        self.castButton = castBtn

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "685be889d76b0da57e68620e"
        playerConfig.type = .VOD
        playerConfig.debug = true
        playerConfig.customUI = true
        playerConfig.showCastButton = true
        playerConfig.useCustomCastButton = castBtn

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

        setupFullscreenListeners(mdstrm)
        setupSDKReadyListener()
        setupSDKPlayPauseListeners()
    }

    // MARK: - Fullscreen + Rotation

    private func setupFullscreenListeners(_ mdstrm: MediastreamPlatformSDK) {
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

    // MARK: - Cast: Banner

    private func setupCastingBanner() {
        castingBanner = UIView()
        castingBanner.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        castingBanner.translatesAutoresizingMaskIntoConstraints = false
        castingBanner.isHidden = true

        castingLabel = UILabel()
        castingLabel.translatesAutoresizingMaskIntoConstraints = false
        castingLabel.textColor = .white
        castingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        castingLabel.text = "Transmitiendo a…"

        disconnectButton = UIButton(type: .system)
        disconnectButton.translatesAutoresizingMaskIntoConstraints = false
        disconnectButton.setTitle("Desconectar", for: .normal)
        disconnectButton.setTitleColor(.systemBlue, for: .normal)
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)

        view.addSubview(castingBanner)
        castingBanner.addSubview(castingLabel)
        castingBanner.addSubview(disconnectButton)

        NSLayoutConstraint.activate([
            castingBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            castingBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            castingBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            castingBanner.heightAnchor.constraint(equalToConstant: 44),

            castingLabel.leadingAnchor.constraint(equalTo: castingBanner.leadingAnchor, constant: 16),
            castingLabel.centerYAnchor.constraint(equalTo: castingBanner.centerYAnchor),

            disconnectButton.trailingAnchor.constraint(equalTo: castingBanner.trailingAnchor, constant: -16),
            disconnectButton.centerYAnchor.constraint(equalTo: castingBanner.centerYAnchor)
        ])
    }

    private func showCastingBanner(deviceName: String) {
        castingLabel.text = "Transmitiendo a \(deviceName)"
        castingBanner.isHidden = false
        castButton?.setImage(UIImage(systemName: "tv.fill"), for: .normal)
        castButton?.tintColor = .systemBlue
    }

    private func hideCastingBanner() {
        castingBanner.isHidden = true
        castButton?.setImage(UIImage(systemName: "tv"), for: .normal)
        castButton?.tintColor = .white
    }

    @objc private func disconnectButtonTapped() {
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        guard let session = sessionManager.currentCastSession else {
            hideCastingBanner()
            return
        }
        if let pos = session.remoteMediaClient?.mediaStatus?.streamPosition, pos.isFinite, pos >= 0 {
            positionToRestoreWhenCastEnds = pos
        } else {
            positionToRestoreWhenCastEnds = lastKnownCastPositionSeconds
        }
        session.remoteMediaClient?.remove(self)
        sessionManager.endSession()
        hideCastingBanner()
    }

    // MARK: - Cast: Sesión

    private func setupCastSessionListener() {
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }

    private func attachToCurrentCastSessionIfNeeded() {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
        let deviceName = session.device.friendlyName.flatMap { $0.isEmpty ? nil : $0 } ?? "Chromecast"
        print("Cast: Sesión ya activa al entrar en pantalla. Dispositivo: \(deviceName)")
        showCastingBanner(deviceName: deviceName)
        session.remoteMediaClient?.add(self)
        if let mediaStatus = session.remoteMediaClient?.mediaStatus {
            if let pos = mediaStatus.streamPosition as TimeInterval?, pos.isFinite, pos >= 0 {
                lastKnownCastPositionSeconds = pos
                syncLocalPlayerUIToCastPosition(force: true)
            }
            syncPlayPauseUIFromCastState(playing: mediaStatus.playerState == .playing)
        }
        sdk?.setCastingModeEnabled(true)
        showExpandedCastControls()
    }

    private func loadMediaOnCastIfPossible(session: GCKCastSession) {
        guard let urlString = sdk?.castUrl, !urlString.isEmpty, let url = URL(string: urlString) else {
            print("Cast: castUrl no disponible aún.")
            return
        }
        let localPositionSeconds = sdk.map { Double($0.getCurrentTime()) / 1000.0 } ?? 0
        loadMediaOnCast(url: url, session: session, startPositionSeconds: localPositionSeconds)
    }

    private func loadMediaOnCast(url: URL, session: GCKCastSession, startPositionSeconds: TimeInterval = 0) {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(sdk?.getMediaTitle() ?? "VOD", forKey: kGCKMetadataKeyTitle)
        let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
        mediaInfoBuilder.streamType = .buffered
        mediaInfoBuilder.metadata = metadata
        let mediaInfo = mediaInfoBuilder.build()
        let options = GCKMediaLoadOptions()
        options.autoplay = true
        options.playPosition = startPositionSeconds
        session.remoteMediaClient?.loadMedia(mediaInfo, with: options)
    }

    private func showExpandedCastControls() {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }

    // MARK: - Cast: Botón

    @objc private func castButtonTapped() {
        let ctx = GCKCastContext.sharedInstance()
        let sessionManager = ctx.sessionManager

        print("Cast: --- Botón Cast pulsado ---")
        print("Cast: castUrl disponible = \(sdk?.castUrl != nil && !(sdk?.castUrl.isEmpty ?? true))")
        print("Cast: Sesión activa = \(sessionManager.currentCastSession != nil)")
        print("Cast: Dispositivos descubiertos = \(ctx.discoveryManager.deviceCount)")

        if sessionManager.currentCastSession != nil {
            showExpandedCastControls()
            return
        }

        guard sdk?.castUrl != nil, !(sdk?.castUrl.isEmpty ?? true) else {
            print("Cast: castUrl aún no disponible.")
            ctx.presentCastDialog()
            return
        }

        ctx.presentCastDialog()
    }

    // MARK: - Cast: Discovery logs

    private func setupCastDiscoveryLogs() {
        let discovery = GCKCastContext.sharedInstance().discoveryManager
        discovery.add(self)
        discovery.startDiscovery()
        print("Cast: Discovery iniciado.")
    }

    // MARK: - Cast: Sync play/pause/seek

    private func setupSDKReadyListener() {
        sdk?.events.listenTo(eventName: "ready") { [weak self] _ in
            guard let self = self else { return }
            let hasCastSession = GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil
            print("Cast: [ready] haySesiónCast=\(hasCastSession)")
            if hasCastSession {
                DispatchQueue.main.async {
                    self.sdk?.setCastingModeEnabled(true)
                    if self.lastKnownCastPositionSeconds > 0 {
                        self.syncLocalPlayerUIToCastPosition(force: true)
                    }
                }
            }
        }
    }

    private func setupSDKPlayPauseListeners() {
        sdk?.events.listenTo(eventName: "play") { [weak self] _ in
            guard let self = self, !self.isSyncingPlayPauseUIFromCast,
                  let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
            session.remoteMediaClient?.play()
            print("Cast: [event play] reenviado a Cast.")
        }
        sdk?.events.listenTo(eventName: "pause") { [weak self] _ in
            guard let self = self, !self.isSyncingPlayPauseUIFromCast,
                  let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
            session.remoteMediaClient?.pause()
            print("Cast: [event pause] reenviado a Cast.")
        }
        sdk?.events.listenTo(eventName: "seek") { [weak self] info in
            guard let self = self,
                  let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
            let dict = info as? [String: Any]
            guard let pos = (dict?["position"] as? NSNumber)?.doubleValue ?? dict?["position"] as? Double, pos >= 0 else { return }
            let options = GCKMediaSeekOptions()
            options.interval = pos
            options.relative = false
            session.remoteMediaClient?.seek(with: options)
            print("Cast: [event seek] posición=\(pos)s.")
        }
        sdk?.events.listenTo(eventName: "forward") { [weak self] info in
            guard let self = self,
                  let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
            let dict = info as? [String: Any]
            let interval = (dict?["interval"] as? NSNumber)?.doubleValue ?? dict?["interval"] as? Double ?? 10
            let targetPos = self.lastKnownCastPositionSeconds + interval
            let options = GCKMediaSeekOptions()
            options.interval = targetPos
            options.relative = false
            session.remoteMediaClient?.seek(with: options)
            print("Cast: [event forward] +\(interval)s → \(targetPos)s.")
        }
        sdk?.events.listenTo(eventName: "backward") { [weak self] info in
            guard let self = self,
                  let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
            let dict = info as? [String: Any]
            let interval = (dict?["interval"] as? NSNumber)?.doubleValue ?? dict?["interval"] as? Double ?? 10
            let targetPos = max(0, self.lastKnownCastPositionSeconds - interval)
            let options = GCKMediaSeekOptions()
            options.interval = targetPos
            options.relative = false
            session.remoteMediaClient?.seek(with: options)
            print("Cast: [event backward] -\(interval)s → \(targetPos)s.")
        }
        sdk?.events.listenTo(eventName: "volume") { [weak self] info in
            guard self != nil,
                  GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil else { return }
            let dict = info as? [String: Any]
            let vol = (dict?["volume"] as? NSNumber)?.intValue ?? dict?["volume"] as? Int ?? 0
            let volNorm = Float(max(0, min(100, vol))) / 100.0
            let volumeController = GCKUIDeviceVolumeController()
            volumeController.setVolume(volNorm)
            print("Cast: [event volume] \(vol)%.")
        }
    }

    private func syncPlayPauseUIFromCastState(playing: Bool) {
        guard lastSyncedCastPlayingState != playing else { return }
        lastSyncedCastPlayingState = playing
        isSyncingPlayPauseUIFromCast = true
        if playing { sdk?.play() } else { sdk?.pause() }
        isSyncingPlayPauseUIFromCast = false
    }

    private func syncLocalPlayerUIToCastPosition(force: Bool = false) {
        guard lastKnownCastPositionSeconds >= 0 else { return }
        if !force {
            let diff = abs(lastKnownCastPositionSeconds - lastSyncedPositionSeconds)
            if lastSyncedPositionSeconds >= 0, diff < syncPositionThresholdSeconds { return }
        }
        lastSyncedPositionSeconds = lastKnownCastPositionSeconds
        sdk?.seekTo(lastKnownCastPositionSeconds)
    }

    // MARK: - Helpers

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

        Este es un caso de prueba para el reproductor en contenedor pequeño con rotación automática y Google Cast.
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
        moreLabel.text = "Al presionar fullscreen la pantalla rotará a landscape y al salir volverá a portrait. El botón Cast (ícono TV) inicia la transmisión a Chromecast."
        moreLabel.font = .systemFont(ofSize: 15)
        moreLabel.textColor = .tertiaryLabel
        moreLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(moreLabel)
    }
}

// MARK: - GCKSessionManagerListener

extension VideoSmallContainerRotationViewController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        guard let castSession = session as? GCKCastSession else { return }
        let deviceName = castSession.device.friendlyName.flatMap { $0.isEmpty ? nil : $0 } ?? "Chromecast"
        print("Cast: Sesión iniciada con dispositivo: \(deviceName)")
        showCastingBanner(deviceName: deviceName)
        sdk?.setCastingModeEnabled(true)
        castSession.remoteMediaClient?.add(self)
        loadMediaOnCastIfPossible(session: castSession)
        showExpandedCastControls()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        print("Cast: Sesión finalizada.")
        (session as? GCKCastSession)?.remoteMediaClient?.remove(self)
        hideCastingBanner()
        sdk?.setCastingModeEnabled(false)
        lastSyncedCastPlayingState = nil
        let positionSeconds = positionToRestoreWhenCastEnds ?? lastKnownCastPositionSeconds
        positionToRestoreWhenCastEnds = nil
        lastKnownCastPositionSeconds = 0
        if positionSeconds > 0 { sdk?.seekTo(positionSeconds) }
        sdk?.play()
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
        print("Cast: Sesión suspendida.")
        (session as? GCKCastSession)?.remoteMediaClient?.remove(self)
        hideCastingBanner()
        sdk?.setCastingModeEnabled(false)
        lastSyncedCastPlayingState = nil
        let positionSeconds = positionToRestoreWhenCastEnds ?? lastKnownCastPositionSeconds
        positionToRestoreWhenCastEnds = nil
        if positionSeconds > 0 { sdk?.seekTo(positionSeconds) }
        sdk?.play()
    }
}

// MARK: - GCKRemoteMediaClientListener

extension VideoSmallContainerRotationViewController: GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let status = mediaStatus else { return }
        let pos = status.streamPosition
        if pos.isFinite, pos >= 0 {
            lastKnownCastPositionSeconds = pos
            syncLocalPlayerUIToCastPosition()
        }
        switch status.playerState {
        case .playing:
            syncPlayPauseUIFromCastState(playing: true)
        case .paused, .idle, .buffering, .loading, .unknown:
            syncPlayPauseUIFromCastState(playing: false)
        @unknown default:
            break
        }
    }
}

// MARK: - GCKDiscoveryManagerListener

extension VideoSmallContainerRotationViewController: GCKDiscoveryManagerListener {
    func didUpdateDeviceList() {
        let count = GCKCastContext.sharedInstance().discoveryManager.deviceCount
        print("Cast: didUpdateDeviceList -> dispositivos = \(count)")
    }
}
