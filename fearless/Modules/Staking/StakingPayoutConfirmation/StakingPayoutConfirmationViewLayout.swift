import UIKit
import SnapKit
import SoraFoundation

final class StakingPayoutConfirmationViewLayout: UIView {
    private enum Constants {
        static let bottomViewHeight: CGFloat = 164.0
    }

    private var mainColor: UIColor? {
        didSet {
            applyMainColor()
        }
    }

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = R.color.colorBlack19()
        tableView.separatorColor = R.color.colorDarkGray()
        return tableView
    }()

    let navigationBar: BaseNavigationBar = {
        let bar = BaseNavigationBar()
        bar.set(.push)
        bar.backButton.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.08)
        bar.backButton.layer.cornerRadius = bar.backButton.frame.size.height / 2
        bar.backgroundColor = R.color.colorBlack19()
        return bar
    }()

    let contentView: ScrollableContainerView = {
        let view = ScrollableContainerView()
        view.stackView.isLayoutMarginsRelativeArrangement = true
        view.stackView.layoutMargins = UIEdgeInsets(top: 24.0, left: 0.0, bottom: 0.0, right: 0.0)
        view.stackView.spacing = UIConstants.bigOffset
        return view
    }()

    let stakeAmountView = StakeAmountView()

    let hintView: IconDetailsView = {
        let view = IconDetailsView()
        view.iconWidth = UIConstants.iconSize
        view.imageView.contentMode = .top
        view.imageView.image = R.image.iconGeneralReward()
        return view
    }()

    let networkFeeFooterView = UIFactory().createCleanNetworkFeeFooterView()
    let infoBackground: TriangularedView = {
        let view = TriangularedView()
        view.fillColor = R.color.colorSemiBlack()!
        view.highlightedFillColor = R.color.colorSemiBlack()!
        view.strokeColor = R.color.colorWhite16()!
        view.highlightedStrokeColor = R.color.colorWhite16()!
        view.strokeWidth = 0.5
        view.shadowOpacity = 0.0

        return view
    }()

    let collatorView: TitleMultiValueView = {
        let view = TitleMultiValueView()
        view.titleLabel.font = .h5Title
        view.titleLabel.textColor = R.color.colorStrokeGray()
        view.valueTop.font = .h5Title
        view.valueTop.textColor = R.color.colorWhite()
        view.valueBottom.font = .p1Paragraph
        view.valueBottom.textColor = R.color.colorStrokeGray()
        view.borderView.isHidden = true
        view.equalsLabelsWidth = true
        return view
    }()

    let accountView: TitleMultiValueView = {
        let view = TitleMultiValueView()
        view.titleLabel.font = .h5Title
        view.titleLabel.textColor = R.color.colorStrokeGray()
        view.valueTop.font = .h5Title
        view.valueTop.textColor = R.color.colorWhite()
        view.valueBottom.font = .p1Paragraph
        view.valueBottom.textColor = R.color.colorStrokeGray()
        view.borderView.isHidden = true
        view.equalsLabelsWidth = true
        view.valueTop.lineBreakMode = .byTruncatingTail
        view.valueBottom.lineBreakMode = .byTruncatingMiddle
        return view
    }()

    let amountView: TitleMultiValueView = {
        let view = TitleMultiValueView()
        view.titleLabel.font = .h5Title
        view.titleLabel.textColor = R.color.colorStrokeGray()
        view.valueTop.font = .h5Title
        view.valueTop.textColor = R.color.colorWhite()
        view.valueBottom.font = .p1Paragraph
        view.valueBottom.textColor = R.color.colorStrokeGray()
        view.borderView.isHidden = true
        view.equalsLabelsWidth = true
        return view
    }()

    let feeView: TitleMultiValueView = {
        let view = TitleMultiValueView()
        view.titleLabel.font = .h5Title
        view.titleLabel.textColor = R.color.colorStrokeGray()
        view.valueTop.font = .h5Title
        view.valueTop.textColor = R.color.colorWhite()
        view.valueBottom.font = .p1Paragraph
        view.valueBottom.textColor = R.color.colorStrokeGray()
        view.borderView.isHidden = true
        view.equalsLabelsWidth = true
        return view
    }()

    let infoStackView = UIFactory.default.createVerticalStackView(spacing: UIConstants.bigOffset)

    var locale = Locale.current {
        didSet {
            if locale != oldValue {
                applyLocalization()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = R.color.colorBlack19()!
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        navigationBar.backButton.rounded()
    }

    func bind(confirmationViewModel: StakingBondMoreConfirmViewModel) {
        accountView.bind(viewModel: confirmationViewModel.accountViewModel)
        collatorView.bind(viewModel: confirmationViewModel.collatorViewModel)
        amountView.bind(viewModel: confirmationViewModel.amountViewModel)

        collatorView.isHidden = confirmationViewModel.collatorViewModel == nil

        if let stakeViewModel = confirmationViewModel.amount?.value(for: locale) {
            stakeAmountView.bind(viewModel: stakeViewModel)
        }

        setNeedsLayout()
    }

    func bind(feeViewModel: BalanceViewModelProtocol?) {
        networkFeeFooterView.bindBalance(viewModel: feeViewModel)
        feeView.bindBalance(viewModel: feeViewModel)

        setNeedsLayout()
    }

    func bind(assetViewModel: AssetBalanceViewModelProtocol) {
        amountView.valueTop.text = assetViewModel.balance
        amountView.valueBottom.text = assetViewModel.price

        setNeedsLayout()
    }

    func bind(singleViewModel: StakingPayoutConfirmationViewModel?) {
        if singleViewModel != nil {
            mainColor = R.color.colorBlack19()
        }

        tableView.isHidden = singleViewModel != nil
        contentView.isHidden = singleViewModel == nil
        collatorView.isHidden = true
        networkFeeFooterView.networkFeeView?.isHidden = singleViewModel != nil

        if let senderName = singleViewModel?.senderName {
            accountView.valueTop.lineBreakMode = .byTruncatingTail
            accountView.valueTop.text = senderName
        }

        accountView.valueBottom.lineBreakMode = .byTruncatingMiddle
        accountView.valueBottom.text = singleViewModel?.senderAddress

        if let stakeViewModel = singleViewModel?.amount?.value(for: locale) {
            stakeAmountView.bind(viewModel: stakeViewModel)
        }

        amountView.valueTop.text = singleViewModel?.amountString.value(for: locale)

        setNeedsLayout()
    }

    func bind(viewModel _: [LocalizableResource<PayoutConfirmViewModel>]) {
        mainColor = R.color.colorBlack()
    }

    private func applyMainColor() {
        backgroundColor = mainColor
        tableView.backgroundColor = mainColor
        contentView.backgroundColor = mainColor
        navigationBar.backgroundColor = mainColor
    }

    private func setupLayout() {
        addSubview(tableView)
        addSubview(contentView)
        addSubview(navigationBar)
        addSubview(networkFeeFooterView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.bottom.equalTo(networkFeeFooterView.snp.top)
        }

        navigationBar.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
        }

        contentView.stackView.addArrangedSubview(stakeAmountView)
        contentView.stackView.addArrangedSubview(infoBackground)

        infoBackground.addSubview(infoStackView)
        infoStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(UIConstants.accessoryItemsSpacing)
            make.trailing.equalToSuperview().inset(UIConstants.accessoryItemsSpacing)
            make.top.bottom.equalToSuperview().inset(UIConstants.defaultOffset)
        }

        infoStackView.addArrangedSubview(collatorView)
        infoStackView.addArrangedSubview(accountView)
        infoStackView.addArrangedSubview(amountView)
        infoStackView.addArrangedSubview(feeView)

        accountView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIConstants.cellHeight)
        }

        amountView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIConstants.cellHeight)
        }

        feeView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIConstants.cellHeight)
        }

        networkFeeFooterView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(contentView.snp.bottom)
        }
    }

    private func applyLocalization() {
        accountView.titleLabel.text = R.string.localizable.commonAccount(preferredLanguages: locale.rLanguages)
        collatorView.titleLabel.text = R.string.localizable.parachainStakingCollator(preferredLanguages: locale.rLanguages)

        hintView.detailsLabel.text = R.string.localizable.stakingHintRewardBondMore(
            preferredLanguages: locale.rLanguages
        )
        feeView.titleLabel.text = R.string.localizable.commonNetworkFee(
            preferredLanguages: locale.rLanguages
        )
        amountView.titleLabel.text = R.string.localizable.walletSendAmountTitle(
            preferredLanguages: locale.rLanguages
        )

        networkFeeFooterView.locale = locale

        navigationBar.setTitle(R.string.localizable.commonConfirmTitle(preferredLanguages: locale.rLanguages))
        setNeedsLayout()
    }
}
