//
//  VideoUILocalizationViewController.swift
//  SDKQAiOS
//
//  UI Localization: mismo VOD que VOD Simple, con selector de idioma de UI (Spanish, English, Portuguese).
//  Al cambiar idioma se hace reload del player con config.language correspondiente.
//

import UIKit
import MediastreamPlatformSDKiOS

class VideoUILocalizationViewController: UIViewController {

    private let vodId = "685be889d76b0da57e68620e"
    private let languages: [MediastreamPlayerConfig.Language] = [.SPANISH, .ENGLISH, .PORTUGUESE]
    private let languageTitles = ["Spanish", "English", "Portuguese"]

    private var sdk: MediastreamPlatformSDK?
    private var currentLanguageIndex = 1 // English por defecto (segment 1)

    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.text = "UI LANGUAGE"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var languageSegmented: UISegmentedControl = {
        let control = UISegmentedControl(items: languageTitles)
        control.selectedSegmentIndex = 1 // English por defecto
        control.addTarget(self, action: #selector(languageChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            control.selectedSegmentTintColor = UIColor.systemTeal
        }
        return control
    }()

    private lazy var bottomBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UIColor(white: 0.12, alpha: 1)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Video: UI Localization"
        view.backgroundColor = .black

        let playerConfig = configForLanguage(1) // English
        let mdstrm = MediastreamPlatformSDK()
        addChild(mdstrm)
        view.addSubview(mdstrm.view)
        mdstrm.view.translatesAutoresizingMaskIntoConstraints = false
        mdstrm.didMove(toParent: self)
        sdk = mdstrm

        view.addSubview(bottomBar)
        bottomBar.addSubview(languageLabel)
        bottomBar.addSubview(languageSegmented)

        NSLayoutConstraint.activate([
            mdstrm.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mdstrm.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mdstrm.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mdstrm.view.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 88),

            languageLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            languageLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            languageLabel.trailingAnchor.constraint(lessThanOrEqualTo: bottomBar.trailingAnchor, constant: -16),

            languageSegmented.topAnchor.constraint(equalTo: languageLabel.bottomAnchor, constant: 8),
            languageSegmented.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            languageSegmented.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            languageSegmented.heightAnchor.constraint(equalToConstant: 32)
        ])

        mdstrm.setup(playerConfig)
        SDKEventListeners.attachAll(to: mdstrm)
        mdstrm.play()
    }

    @objc private func languageChanged() {
        let newIndex = languageSegmented.selectedSegmentIndex
        guard newIndex != currentLanguageIndex else { return }
        currentLanguageIndex = newIndex
        let config = configForLanguage(newIndex)
        sdk?.reloadPlayer(config)
    }

    private func configForLanguage(_ index: Int) -> MediastreamPlayerConfig {
        let config = MediastreamPlayerConfig()
        config.id = vodId
        config.type = .VOD
        config.debug = true
        config.customUI = true
        config.language = languages[index]
        return config
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sdk?.releasePlayer()
    }

    deinit {
        sdk?.releasePlayer()
    }
}
