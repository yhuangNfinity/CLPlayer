//
//  CLPlayerContentView.swift
//  CLPlayer
//
//  Created by Chen JmoVxia on 2021/10/26.
//
import AVFoundation
import MediaPlayer
import SnapKit
import UIKit

// MARK: - JmoVxia---枚举

extension CLPlayerContentView {
    enum CLPlayerScreenState {
        case small
        case animating
        case fullScreen
    }

    enum CLPlayerPlayState {
        case unknow
        case readyToPlay
        case playing
        case buffering
        case failed
        case pause
        case ended
    }

    enum CLPanDirection {
        case unknow
        case horizontal
        case leftVertical
        case rightVertical
    }
}

class CLPlayerContentView: UIImageView {
    init(config: CLPlayerConfigure) {
        self.config = config
        super.init(frame: .zero)
        initUI()
        makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var volumeSlider: UISlider? = {
        let view = MPVolumeView()
        return view.subviews.first(where: { $0 is UISlider }) as? UISlider
    }()

    private lazy var topToolView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.6)
        return view
    }()

    private lazy var bottomToolView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.6)
        return view
    }()

    private lazy var bottomContentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var bottomSafeView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var loadingView: CLRotateAnimationView = {
        let view = CLRotateAnimationView(frame: .init(x: 0, y: 0, width: 40, height: 40))
        view.startAnimation()
        return view
    }()

    private lazy var backButton: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(named: "CLBack"), for: .normal)
        view.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        return view
    }()

    private lazy var moreButton: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(named: "CLMore"), for: .normal)
        view.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        return view
    }()

    private lazy var playButton: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(named: "CLPlay"), for: .normal)
        view.setImage(UIImage(named: "CLPause"), for: .selected)
        view.addTarget(self, action: #selector(playButtonAction(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var fullButton: UIButton = {
        let view = UIButton()
        view.setImage(UIImage(named: "CLFullscreen"), for: .normal)
        view.setImage(UIImage(named: "CLSmallscreen"), for: .selected)
        view.addTarget(self, action: #selector(fullButtonAction(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var currentDurationLabel: UILabel = {
        let view = UILabel()
        view.text = "00:00"
        view.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        view.textColor = .white
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private lazy var totalDurationLabel: UILabel = {
        let view = UILabel()
        view.text = "00:00"
        view.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        view.textColor = .white
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private lazy var progressView: UIProgressView = {
        let view = UIProgressView()
        view.trackTintColor = .white.withAlphaComponent(0.35)
        view.progressTintColor = .white.withAlphaComponent(0.5)
        return view
    }()

    private lazy var sliderView: CLSlider = {
        let view = CLSlider()
        view.isUserInteractionEnabled = false
        view.maximumValue = 1
        view.minimumValue = 0
        view.minimumTrackTintColor = .white
        view.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
        view.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
        view.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchUpInside, .touchCancel, .touchUpOutside])
        return view
    }()

    private lazy var failButton: UIButton = {
        let view = UIButton()
        view.isHidden = true
        view.titleLabel?.font = .systemFont(ofSize: 14)
        view.setTitle("Failed to load. Click try again", for: .normal)
        view.setTitle("Failed to load. Click try again", for: .selected)
        view.setTitle("Failed to load. Click try again", for: .highlighted)
        view.setTitleColor(.white, for: .normal)
        view.setTitleColor(.white, for: .selected)
        view.setTitleColor(.white, for: .highlighted)
        view.addTarget(self, action: #selector(failButtonAction), for: .touchUpInside)
        return view
    }()

    private lazy var morePanelCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = .zero
        layout.minimumInteritemSpacing = .zero
        layout.sectionInset = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(CLPlayerContentPanelHeadView.classForCoder(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CLPlayerContentPanelHeadView")
        view.register(CLPlayerContentPanelCell.classForCoder(), forCellWithReuseIdentifier: "CLPlayerContentPanelCell")
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .black.withAlphaComponent(0.8)
        view.alwaysBounceVertical = true
        view.isExclusiveTouch = true
        return view
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        gesture.delegate = self
        return gesture
    }()

    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panDirection(_:)))
        gesture.maximumNumberOfTouches = 1
        gesture.delaysTouchesBegan = true
        gesture.delaysTouchesEnded = true
        gesture.cancelsTouchesInView = true
        gesture.delegate = self
        return gesture
    }()

    var title: NSMutableAttributedString? {
        didSet {
            guard let title = title else { return }
            titleLabel.attributedText = title
        }
    }

    var currentRate: Float = 1.0 {
        didSet {
            guard currentRate != oldValue else { return }
            morePanelCollectionView.reloadData()
            delegate?.didChangeRate(currentRate, in: self)
        }
    }

    var currentVideoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            guard currentVideoGravity != oldValue else { return }
            morePanelCollectionView.reloadData()
            delegate?.didChangeVideoGravity(currentVideoGravity, in: self)
        }
    }

    var screenState: CLPlayerScreenState = .small {
        didSet {
            guard screenState != oldValue else { return }
            switch screenState {
            case .small:
                topToolView.isHidden = config.topBarHiddenStyle != .never
                hiddenMorePanel()
            case .animating:
                break
            case .fullScreen:
                topToolView.isHidden = config.topBarHiddenStyle == .always
            }
        }
    }

    var playState: CLPlayerPlayState = .unknow {
        didSet {
            guard playState != oldValue else { return }
            print("playState:\(playState)")
            switch playState {
            case .unknow:
                sliderView.isUserInteractionEnabled = false
                failButton.isHidden = true
                playButton.isSelected = false
                loadingView.startAnimation()
            case .readyToPlay:
                sliderView.isUserInteractionEnabled = true
            case .playing:
                sliderView.isUserInteractionEnabled = true
                failButton.isHidden = true
                playButton.isSelected = true
                loadingView.stopAnimation()
                image = nil
            case .buffering:
                sliderView.isUserInteractionEnabled = true
                failButton.isHidden = true
                loadingView.startAnimation()
            case .failed:
                sliderView.isUserInteractionEnabled = false
                failButton.isHidden = false
                loadingView.stopAnimation()
            case .pause:
                sliderView.isUserInteractionEnabled = true
                playButton.isSelected = false
            case .ended:
                sliderView.isUserInteractionEnabled = true
                failButton.isHidden = true
                playButton.isSelected = false
                loadingView.stopAnimation()
                image = config.maskImage
            }
        }
    }

    private var config: CLPlayerConfigure!

    private var isShowMorePanel: Bool = false {
        didSet {
            guard isShowMorePanel != oldValue else { return }
            if isShowMorePanel {
                isShowToolView = false
                morePanelCollectionView.snp.updateConstraints { make in
                    make.right.equalTo(0)
                }
            } else {
                isShowToolView = true
                morePanelCollectionView.snp.updateConstraints { make in
                    make.right.equalTo(morePanelWidth)
                }
            }
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }

    private var isShowToolView: Bool = true {
        didSet {
            guard isShowToolView != oldValue else { return }
            if isShowToolView {
                topToolView.snp.updateConstraints { make in
                    make.top.equalTo(0)
                }
                bottomToolView.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
                autoFadeOutTooView()
            } else {
                topToolView.snp.updateConstraints { make in
                    make.top.equalTo(-50)
                }
                bottomToolView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.snp.bottom)
                }
                cancelAutoFadeOutTooView()
            }
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }

    private let morePanelWidth: CGFloat = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.382

    private var panDirection: CLPanDirection = .unknow

    private var autoFadeOutTimer: CLGCDTimer?

    private var rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    private var videoGravity: [(name: String, mode: AVLayerVideoGravity)] = [("适应", .resizeAspect), ("拉伸", .resizeAspectFill), ("填充", .resize)]

    weak var delegate: CLPlayerContentViewDelegate?
}

// MARK: - JmoVxia---布局

private extension CLPlayerContentView {
    func initUI() {
        updateConfig()

        clipsToBounds = true
        autoresizesSubviews = true
        isUserInteractionEnabled = true

        addSubview(topToolView)
        addSubview(bottomToolView)
        addSubview(loadingView)
        topToolView.addSubview(backButton)
        topToolView.addSubview(titleLabel)
        topToolView.addSubview(moreButton)
        bottomToolView.addSubview(bottomContentView)
        bottomToolView.addSubview(bottomSafeView)
        bottomContentView.addSubview(playButton)
        bottomContentView.addSubview(fullButton)
        bottomContentView.addSubview(currentDurationLabel)
        bottomContentView.addSubview(totalDurationLabel)
        bottomContentView.addSubview(progressView)
        bottomContentView.addSubview(sliderView)
        addSubview(failButton)
        addSubview(morePanelCollectionView)

        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)

        autoFadeOutTooView()
    }

    func makeConstraints() {
        topToolView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        bottomToolView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
        bottomSafeView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
        bottomContentView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(50)
            make.bottom.equalTo(bottomSafeView.snp.top)
        }
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        backButton.snp.makeConstraints { make in
            make.left.equalTo(-40)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(15)
            make.right.equalTo(moreButton.snp.left).offset(-15)
            make.centerY.height.equalToSuperview()
        }
        moreButton.snp.makeConstraints { make in
            make.right.equalTo(40)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        playButton.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        fullButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
        }
        currentDurationLabel.snp.makeConstraints { make in
            make.left.equalTo(playButton.snp.right).offset(10)
            make.centerY.equalToSuperview()
        }
        totalDurationLabel.snp.makeConstraints { make in
            make.right.equalTo(fullButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.left.equalTo(currentDurationLabel.snp.right).offset(15)
            make.centerY.equalToSuperview()
            make.height.equalTo(2)
            make.right.equalTo(totalDurationLabel.snp.left).offset(-15)
        }
        sliderView.snp.makeConstraints { make in
            make.edges.equalTo(progressView)
        }
        failButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        morePanelCollectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalTo(morePanelWidth)
            make.width.equalTo(morePanelWidth)
        }
    }

    func updateConfig() {
        currentVideoGravity = config.videoGravity
        topToolView.isHidden = screenState == .small ? config.topBarHiddenStyle != .never : config.topBarHiddenStyle == .always
        moreButton.isHidden = !config.isShowMorePanel
        topToolView.backgroundColor = config.topToobarBackgroundColor
        bottomToolView.backgroundColor = config.bottomToolbarBackgroundColor
        progressView.trackTintColor = config.progressBackgroundColor
        progressView.progressTintColor = config.progressBufferColor
        sliderView.minimumTrackTintColor = config.progressFinishedColor
        loadingView.updateWithConfigure { $0.backgroundColor = self.config.loadingBackgroundColor }

        let backImage: UIImage? = {
            guard let image = config.backImage else { return UIImage(named: "CLBack") }
            return image
        }()
        backButton.setImage(backImage, for: .normal)

        let moreImage: UIImage? = {
            guard let image = config.moreImage else { return UIImage(named: "CLMore") }
            return image
        }()
        moreButton.setImage(moreImage, for: .normal)

        let playImage: UIImage? = {
            guard let image = config.playImage else { return UIImage(named: "CLPlay") }
            return image
        }()
        playButton.setImage(playImage, for: .normal)

        let pauseImage: UIImage? = {
            guard let image = config.pauseImage else { return UIImage(named: "CLPause") }
            return image
        }()
        playButton.setImage(pauseImage, for: .selected)

        let maxImage: UIImage? = {
            guard let image = config.maxImage else { return UIImage(named: "CLFullscreen") }
            return image
        }()
        fullButton.setImage(maxImage, for: .normal)

        let minImage: UIImage? = {
            guard let image = config.minImage else { return UIImage(named: "CLSmallscreen") }
            return image
        }()
        fullButton.setImage(minImage, for: .selected)

        let sliderImage: UIImage? = {
            guard let image = config.sliderImage else { return UIImage(named: "CLSlider") }
            return image
        }()
        sliderView.setThumbImage(sliderImage, for: .normal)

        image = config.maskImage
    }
}

// MARK: - JmoVxia---objc

@objc private extension CLPlayerContentView {
    func tapAction() {
        if isShowMorePanel {
            isShowMorePanel = false
        } else {
            isShowToolView.toggle()
        }
    }

    func panDirection(_ pan: UIPanGestureRecognizer) {
        let locationPoint = pan.location(in: self)
        let veloctyPoint = pan.velocity(in: self)
        switch pan.state {
        case .began:
            if abs(veloctyPoint.x) > abs(veloctyPoint.y) {
                panDirection = .horizontal
            } else {
                panDirection = locationPoint.x < bounds.width * 0.5 ? .leftVertical : .rightVertical
            }
        case .changed:
            switch panDirection {
            case .horizontal:
                break
            case .leftVertical:
                UIScreen.main.brightness -= veloctyPoint.y / 10000
            case .rightVertical:
                volumeSlider?.value -= Float(veloctyPoint.y / 10000)
            default:
                break
            }
        case .ended, .cancelled:
            panDirection = .unknow
        default:
            break
        }
    }

    func backButtonAction() {
        delegate?.didClickBackButton(in: self)
    }

    func moreButtonAction() {
        showMorePanel()
    }

    func playButtonAction(_ button: UIButton) {
        delegate?.didClickPlayButton(isPlay: button.isSelected, in: self)
    }

    func fullButtonAction(_ button: UIButton) {
        delegate?.didClickFullButton(isFull: button.isSelected, in: self)
    }

    func failButtonAction() {
        delegate?.didClickFailButton(in: self)
    }

    func progressSliderTouchBegan(_ slider: CLSlider) {
        cancelAutoFadeOutTooView()
        delegate?.sliderTouchBegan(slider, in: self)
    }

    func progressSliderValueChanged(_ slider: CLSlider) {
        delegate?.sliderValueChanged(slider, in: self)
    }

    func progressSliderTouchEnded(_ slider: CLSlider) {
        autoFadeOutTooView()
        delegate?.sliderTouchEnded(slider, in: self)
    }
}

// MARK: - JmoVxia---私有方法

private extension CLPlayerContentView {
    func showMorePanel() {
        isShowMorePanel = true
    }

    func hiddenMorePanel() {
        isShowMorePanel = false
    }

    func showToolView() {
        isShowToolView = true
    }

    func hiddenToolView() {
        isShowToolView = false
    }

    func autoFadeOutTooView() {
        autoFadeOutTimer = CLGCDTimer(interval: 0, delaySecs: 0.25 + config.autoFadeOut, repeats: false, action: { [weak self] _ in
            self?.isShowToolView = false
        })
        autoFadeOutTimer?.start()
    }

    func cancelAutoFadeOutTooView() {
        autoFadeOutTimer?.cancel()
    }
}

// MARK: - JmoVxia---公共方法

extension CLPlayerContentView {
    func animationLayout(safeAreaInsets: UIEdgeInsets, to screenState: CLPlayerScreenState) {
        bottomSafeView.snp.updateConstraints { make in
            make.height.equalTo(safeAreaInsets.bottom)
        }
        backButton.snp.updateConstraints { make in
            make.left.equalTo(screenState == .small ? -40 : safeAreaInsets.left + 10)
        }
        titleLabel.snp.updateConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(screenState == .small ? 15 : 10)
            make.right.equalTo(moreButton.snp.left).offset(screenState == .small ? -15 : -10)
        }
        moreButton.snp.updateConstraints { make in
            make.right.equalTo(screenState == .small ? 40 : -safeAreaInsets.left - 10)
        }
        playButton.snp.updateConstraints { make in
            make.left.equalTo(safeAreaInsets.left + 10)
        }
        fullButton.snp.updateConstraints { make in
            make.right.equalTo(-safeAreaInsets.right - 10)
        }

        fullButton.isSelected = screenState == .fullScreen

        topToolView.isHidden = screenState == .small ? config.topBarHiddenStyle != .never : config.topBarHiddenStyle == .always
    }

    func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(min(max(0, progress), 1), animated: animated)
    }

    func setSliderProgress(_ progress: Float, animated: Bool) {
        sliderView.setValue(min(max(0, progress), 1), animated: animated)
    }

    func setTotalDuration(_ totalDuration: TimeInterval) {
        let time = Int(ceil(totalDuration))
        let hours = time / 3600
        let minutes = time / 60
        let seconds = time % 60
        totalDurationLabel.text = hours == .zero ? String(format: "%02ld:%02ld", minutes, seconds) : String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
    }

    func setCurrentDuration(_ currentDuration: TimeInterval) {
        let time = Int(ceil(currentDuration))
        let hours = time / 3600
        let minutes = time / 60
        let seconds = time % 60
        currentDurationLabel.text = hours == .zero ? String(format: "%02ld:%02ld", minutes, seconds) : String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
    }
}

extension CLPlayerContentView: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        indexPath.section == 0 ? (currentRate = rates[indexPath.row]) : (currentVideoGravity = videoGravity[indexPath.row].mode)
    }
}

extension CLPlayerContentView: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: floor(morePanelWidth / (indexPath.section == 0 ? 5 : 3)), height: 40)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        return CGSize(width: morePanelWidth, height: 40)
    }
}

extension CLPlayerContentView: UICollectionViewDataSource {
    func numberOfSections(in _: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? rates.count : videoGravity.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CLPlayerContentPanelHeadView", for: indexPath)
            (headView as? CLPlayerContentPanelHeadView)?.title = indexPath.section == 0 ? "播放速度" : "填充模式"
            return headView
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CLPlayerContentPanelCell", for: indexPath)
        if let cell = cell as? CLPlayerContentPanelCell {
            cell.isCurrent = indexPath.section == 0 ? (rates[indexPath.row] == currentRate) : (videoGravity[indexPath.row].mode == currentVideoGravity)
            cell.title = indexPath.section == 0 ? "\(rates[indexPath.row])" : "\(videoGravity[indexPath.row].name)"
        }
        return cell
    }
}

extension CLPlayerContentView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if morePanelCollectionView.bounds.contains(touch.location(in: morePanelCollectionView)) {
            return false
        } else if topToolView.bounds.contains(touch.location(in: topToolView)) {
            return false
        } else if bottomToolView.bounds.contains(touch.location(in: bottomToolView)) {
            return false
        } else if gestureRecognizer == panGesture {
            return screenState == .fullScreen && config.isGestureInteractionEnabled
        }
        return true
    }
}
