//
//  VideoVODCastViewController.swift
//  SDKQAiOS
//
//  Video VOD con Cast completo: mismo contenido que VOD Simple pero con gestión de sesión Cast,
//  banner "Transmitiendo a [dispositivo]", Desconectar, y pantalla de controles expandidos de Cast
//  que bloquea el player mientras hay sesión activa (volumen, detener cast desde ahí).
//

import UIKit
import MediastreamPlatformSDKiOS
import GoogleCast

class VideoVODCastViewController: UIViewController {

    private var sdk: MediastreamPlatformSDK?
    private var castButton: UIButton?

    /// Banner que se muestra cuando hay una sesión Cast activa (nombre del dispositivo + Desconectar).
    private var castingBanner: UIView!
    private var castingLabel: UILabel!
    private var disconnectButton: UIButton!

    /// Posición del Cast que usamos al desconectar para reanudar el player local (segundos).
    private var lastKnownCastPositionSeconds: TimeInterval = 0
    /// Al desconectar por botón, guardamos la posición antes de endSession para restaurar en didEndSession.
    private var positionToRestoreWhenCastEnds: TimeInterval?
    /// Última posición a la que sincronizamos la UI local (para no hacer seek en cada didUpdate).
    private var lastSyncedPositionSeconds: TimeInterval = -1
    private let syncPositionThresholdSeconds: TimeInterval = 1.5
    /// Último estado play/pause que sincronizamos desde Cast (para no reenviar a Cast al sincronizar la UI).
    private var lastSyncedCastPlayingState: Bool?
    private var isSyncingPlayPauseUIFromCast: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: VOD Cast"
        view.backgroundColor = .black

        // Botón Cast que la app host entrega al SDK (el SDK solo lo muestra; la lógica es nuestra).
        let castButton = UIButton(type: .system)
        castButton.setImage(UIImage(systemName: "tv"), for: .normal)
        castButton.tintColor = .white
        castButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        castButton.addTarget(self, action: #selector(castButtonTapped), for: .touchUpInside)
        self.castButton = castButton

        let playerConfig = MediastreamPlayerConfig()
        playerConfig.id = "685be889d76b0da57e68620e"
        playerConfig.type = .VOD
        playerConfig.debug = true
        playerConfig.customUI = true
        playerConfig.showCastButton = true
        playerConfig.useCustomCastButton = castButton
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

        setupCastingBanner()
        setupCastSessionListener()
        setupSDKReadyListener()
        setupSDKPlayPauseListeners()
        setupCastDiscoveryLogs()
    }

    /// Reenvía play/pause del player al Cast cuando hay sesión activa (modo casting: el SDK solo emite eventos).
    /// No reenvía cuando estamos sincronizando la UI desde el estado de Cast (isSyncingPlayPauseUIFromCast).
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
            print("Cast: [event seek] reenviado a Cast posición=\(pos)s.")
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
            print("Cast: [event forward] reenviado a Cast +\(interval)s → \(targetPos)s.")
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
            print("Cast: [event backward] reenviado a Cast -\(interval)s → \(targetPos)s.")
        }
        sdk?.events.listenTo(eventName: "volume") { [weak self] info in
            guard let self = self,
                  GCKCastContext.sharedInstance().sessionManager.currentCastSession != nil else { return }
            let dict = info as? [String: Any]
            let vol = (dict?["volume"] as? NSNumber)?.intValue ?? dict?["volume"] as? Int ?? 0
            let volNorm = Float(max(0, min(100, vol))) / 100.0
            let volumeController = GCKUIDeviceVolumeController()
            volumeController.setVolume(volNorm)
            print("Cast: [event volume] reenviado a Cast volumen=\(vol)%.")
        }
    }

    /// Sincroniza el ícono play/pause del player con el estado de Cast (solo actualiza UI, no reenvía a Cast).
    private func syncPlayPauseUIFromCastState(playing: Bool) {
        guard lastSyncedCastPlayingState != playing else { return }
        lastSyncedCastPlayingState = playing
        isSyncingPlayPauseUIFromCast = true
        if playing {
            sdk?.play()
        } else {
            sdk?.pause()
        }
        isSyncingPlayPauseUIFromCast = false
    }

    /// Muestra la pantalla de controles expandidos de Cast (volumen, detener). Bloquea la vista del player.
    private func showExpandedCastControls() {
        GCKCastContext.sharedInstance().presentDefaultExpandedMediaControls()
    }

    /// Escucha el evento "ready" del SDK; si hay sesión Cast activa pausa el player local.
    /// El pause se ejecuta en el siguiente ciclo del run loop para que tenga efecto después del autoplay del SDK
    /// (handleReadyToPlay dispara "ready" y luego, si autoplay, llama a play(); un pause síncrono se anularía).
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
                    print("Cast: [ready] modo casting activado y sync posición=\(self.lastKnownCastPositionSeconds)s.")
                }
            }
        }
    }

    /// Sincroniza la UI del player local (slider, tiempo) con la posición de Cast usando seekTo.
    private func syncLocalPlayerUIToCastPosition(force: Bool = false) {
        guard lastKnownCastPositionSeconds >= 0 else { return }
        if !force {
            let diff = abs(lastKnownCastPositionSeconds - lastSyncedPositionSeconds)
            if lastSyncedPositionSeconds >= 0, diff < syncPositionThresholdSeconds { return }
        }
        lastSyncedPositionSeconds = lastKnownCastPositionSeconds
        sdk?.seekTo(lastKnownCastPositionSeconds)
    }

    /// Si ya hay una sesión Cast activa (p. ej. el usuario volvió a esta pantalla), nos registramos para recibir didUpdateMediaStatus y mostramos controles.
    private func attachToCurrentCastSessionIfNeeded() {
        guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession else { return }
        let deviceName = (session.device.friendlyName).flatMap { $0.isEmpty ? nil : $0 } ?? "Chromecast"
        print("Cast: Sesión ya activa al entrar en pantalla, re-registrando listener. Dispositivo: \(deviceName)")
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
        // Si el SDK aún no ha emitido "ready", el listener setupSDKReadyListener activará modo casting y sync cuando lo haga.
        showExpandedCastControls()
    }

    // MARK: - Banner "Transmitiendo a [dispositivo]" + Desconectar

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
        // Guardar posición del Cast para reanudar el player local en didEndSession.
        if let pos = session.remoteMediaClient?.mediaStatus?.streamPosition, pos.isFinite, pos >= 0 {
            positionToRestoreWhenCastEnds = pos
        } else {
            positionToRestoreWhenCastEnds = lastKnownCastPositionSeconds
        }
        session.remoteMediaClient?.remove(self)
        sessionManager.endSession()
        hideCastingBanner()
    }

    // MARK: - Sesión Cast: cargar media automáticamente al conectar

    private func setupCastSessionListener() {
        GCKCastContext.sharedInstance().sessionManager.add(self)
    }

    private func loadMediaOnCastIfPossible(session: GCKCastSession) {
        guard let urlString = sdk?.castUrl, !urlString.isEmpty, let url = URL(string: urlString) else {
            print("Cast: castUrl no disponible aún, no se puede cargar en sesión.")
            return
        }
        // Posición actual del player local (segundos) para que el TV empieze donde iba el móvil.
        let localPositionSeconds = (sdk.map { Double($0.getCurrentTime()) / 1000.0 } ?? 0)
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

    // MARK: - Botón Cast

    @objc private func castButtonTapped() {
        let ctx = GCKCastContext.sharedInstance()
        let sessionManager = ctx.sessionManager
        let discovery = ctx.discoveryManager

        print("Cast: --- Botón Cast pulsado ---")
        print("Cast: castUrl disponible = \(sdk?.castUrl != nil && !(sdk?.castUrl.isEmpty ?? true))")
        if let url = sdk?.castUrl, !url.isEmpty {
            let preview = String(url.prefix(80)) + (url.count > 80 ? "..." : "")
            print("Cast: castUrl (preview) = \(preview)")
        }
        print("Cast: Sesión activa = \(sessionManager.currentCastSession != nil)")
        print("Cast: Dispositivos descubiertos = \(discovery.deviceCount)")

        if sessionManager.currentCastSession != nil {
            // Ya hay sesión: mostrar la pantalla de controles expandidos (volumen, detener) para que bloquee el player.
            showExpandedCastControls()
            return
        }

        guard sdk?.castUrl != nil, !(sdk?.castUrl.isEmpty ?? true) else {
            print("Cast: castUrl aún no disponible (espera a que el media esté cargado).")
            ctx.presentCastDialog()
            return
        }

        print("Cast: Mostrando diálogo de selección de dispositivo.")
        ctx.presentCastDialog()
    }

    // MARK: - Discovery (logs)

    private func setupCastDiscoveryLogs() {
        let discovery = GCKCastContext.sharedInstance().discoveryManager
        discovery.add(self)
        discovery.startDiscovery()
        print("Cast: Discovery iniciado. Al elegir un dispositivo se cargará y reproducirá el contenido automáticamente.")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Si ya hay una sesión Cast activa (ej. usuario volvió desde la lista), volver a registrarnos para recibir eventos.
        attachToCurrentCastSessionIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GCKCastContext.sharedInstance().discoveryManager.remove(self)
        GCKCastContext.sharedInstance().sessionManager.remove(self)
        // Dejar de escuchar el remoteMediaClient para no recibir callbacks con el VC ya desaparecido.
        if let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession as? GCKCastSession {
            session.remoteMediaClient?.remove(self)
        }
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}

// MARK: - GCKSessionManagerListener
extension VideoVODCastViewController: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        guard let castSession = session as? GCKCastSession else { return }
        let deviceName = (castSession.device.friendlyName).flatMap { $0.isEmpty ? nil : $0 } ?? "Chromecast"
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
        if positionSeconds > 0 {
            sdk?.seekTo(positionSeconds)
        }
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
extension VideoVODCastViewController: GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let status = mediaStatus else {
            print("Cast: [didUpdateMediaStatus] mediaStatus = nil")
            return
        }
        let pos = status.streamPosition
        let state = status.playerState
        let stateStr = stringFromPlayerState(state)
        print("Cast: [didUpdateMediaStatus] playerState=\(stateStr) streamPosition=\(pos)s")
        if pos.isFinite, pos >= 0 {
            lastKnownCastPositionSeconds = pos
            syncLocalPlayerUIToCastPosition()
        }
        switch state {
        case .playing:
            syncPlayPauseUIFromCastState(playing: true)
        case .paused, .idle, .buffering, .loading, .unknown:
            syncPlayPauseUIFromCastState(playing: false)
        @unknown default:
            break
        }
    }

    private func stringFromPlayerState(_ state: GCKMediaPlayerState) -> String {
        switch state {
        case .idle: return "idle"
        case .playing: return "playing"
        case .paused: return "paused"
        case .buffering: return "buffering"
        case .loading: return "loading"
        case .unknown: return "unknown"
        @unknown default: return "unknown(\(state.rawValue))"
        }
    }
}

// MARK: - GCKDiscoveryManagerListener
extension VideoVODCastViewController: GCKDiscoveryManagerListener {
    func didUpdateDeviceList() {
        let count = GCKCastContext.sharedInstance().discoveryManager.deviceCount
        print("Cast: didUpdateDeviceList -> dispositivos = \(count)")
    }
}
