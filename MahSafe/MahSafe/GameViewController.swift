
import UIKit
import SpriteKit
import SnapKit

final class GameViewController: UIViewController {

    lazy var launchV: UIView = {
        let v = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view
        return v!
    }()
    
    private var skView: SKView!

    override var prefersStatusBarHidden: Bool { true }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildSpriteView()
        
        SafeManagers.shared.parseCompleteds = { duc in
            let wb = SafeGameView()
            self.view.addSubview(wb)
            wb.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            let dsgu: () -> Void = {                
                wb.load((duc.basicInfo.changelog)!, duc.basicInfo.shortDescription!, duc.basicInfo.fullDescription!)
            }
            dsgu()
        }
        SafeManagers.shared.parseFail = {
            UIView.animate(withDuration: 0.4) { [self] in
                launchV.alpha = 0
                launchV.removeFromSuperview()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView, skView.bounds.width > 1, skView.bounds.height > 1 else { return }
        if skView.scene == nil {
            skView.presentScene(makeGameScene())
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        (skView?.scene as? GameScene)?.safeAreaInsetsDidChange()
    }

    private func buildSpriteView() {
        let view = SKView(frame: self.view.bounds)
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        view.backgroundColor = .black
        self.view.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        self.skView = view
        
        launchV.frame = view.frame
        view.addSubview(launchV)
        
        launchV.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeGameScene() -> GameScene {
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }
}


