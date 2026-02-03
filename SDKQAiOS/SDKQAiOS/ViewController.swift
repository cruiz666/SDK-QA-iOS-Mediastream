//
//  ViewController.swift
//  SDKQAiOS
//
//  Pantalla principal con la lista de casos de prueba (equivalente a MainActivity en Android).
//

import UIKit

class ViewController: UIViewController {

    private let cellReuseId = "TestCaseCell"
    private var testCases: [TestCase] = []
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseId)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SDK QA"
        view.backgroundColor = .systemGroupedBackground
        testCases = TestCase.getAllTestCases()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        testCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        let testCase = testCases[indexPath.row]
        cell.textLabel?.text = testCase.displayTitle
        cell.detailTextLabel?.text = testCase.category.displayName
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let testCase = testCases[indexPath.row]

        switch testCase.type {
        case .audioAodSimple:
            navigationController?.pushViewController(AudioAodSimpleViewController(), animated: true)
        case .audioAodWithService:
            navigationController?.pushViewController(AudioAodWithServiceViewController(), animated: true)
        case .audioEpisode:
            navigationController?.pushViewController(AudioEpisodeViewController(), animated: true)
        case .audioLocal:
            navigationController?.pushViewController(AudioLocalViewController(), animated: true)
        case .audioLocalWithService:
            navigationController?.pushViewController(AudioLocalWithServiceViewController(), animated: true)
        case .audioLive:
            navigationController?.pushViewController(AudioLiveViewController(), animated: true)
        case .audioLiveWithService:
            navigationController?.pushViewController(AudioLiveWithServiceViewController(), animated: true)
        case .audioLiveDvr:
            navigationController?.pushViewController(AudioLiveDvrViewController(), animated: true)
        case .audioMixed:
            navigationController?.pushViewController(AudioMixedViewController(), animated: true)
        case .audioMixedWithService:
            navigationController?.pushViewController(AudioMixedWithServiceViewController(), animated: true)
        case .videoVodSimple:
            navigationController?.pushViewController(VideoVodSimpleViewController(), animated: true)
        case .videoNextEpisode:
            navigationController?.pushViewController(VideoNextEpisodeViewController(), animated: true)
        case .videoLocal:
            navigationController?.pushViewController(VideoLocalViewController(), animated: true)
        case .videoLocalWithService:
            navigationController?.pushViewController(VideoLocalWithServiceViewController(), animated: true)
        case .videoEpisode:
            navigationController?.pushViewController(VideoEpisodeViewController(), animated: true)
        case .videoLive:
            navigationController?.pushViewController(VideoLiveViewController(), animated: true)
        case .videoLiveDvr:
            navigationController?.pushViewController(VideoLiveDvrViewController(), animated: true)
        case .videoMixed:
            navigationController?.pushViewController(VideoMixedViewController(), animated: true)
        case .videoMixedWithService:
            navigationController?.pushViewController(VideoMixedWithServiceViewController(), animated: true)
        default:
            let detail = CaseDetailViewController()
            detail.testCase = testCase
            navigationController?.pushViewController(detail, animated: true)
        }
    }
}
