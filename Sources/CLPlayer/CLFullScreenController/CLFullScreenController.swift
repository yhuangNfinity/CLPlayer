//
//  CLFullScreenController.swift
//  CLPlayer
//
//  Created by Chen JmoVxia on 2021/10/27.
//

import UIKit

// MARK: - JmoVxia---类-属性

class CLFullScreenController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {}
}

// MARK: - JmoVxia---生命周期

extension CLFullScreenController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - JmoVxia---布局

private extension CLFullScreenController {
    func initUI() {
        view.backgroundColor = .black
    }
}

// MARK: - JmoVxia---override

extension CLFullScreenController {
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
