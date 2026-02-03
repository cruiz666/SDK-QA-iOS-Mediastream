//
//  CaseDetailViewController.swift
//  SDKQAiOS
//
//  Vista vacía de detalle por caso; por ahora solo registra en log el caso seleccionado.
//

import UIKit

class CaseDetailViewController: UIViewController {

    var testCase: TestCase!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = testCase.displayTitle

        // Log del caso seleccionado (TAG "SDK-QA", igual que en Android)
        NSLog("[SDK-QA] Selected test case: %@ (%@)", testCase.displayTitle, String(describing: testCase.type))
    }
}
