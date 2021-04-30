import UIKit
import SoraFoundation
import CommonWallet

final class StakingUnbondSetupViewController: UIViewController, ViewHolder {
    typealias RootViewType = StakingUnbondSetupLayout

    let presenter: StakingUnbondSetupPresenterProtocol

    var selectedLocale: Locale {
        localizationManager?.selectedLocale ?? .autoupdatingCurrent
    }

    init(
        presenter: StakingUnbondSetupPresenterProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.presenter = presenter

        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    var uiFactory: UIFactoryProtocol = UIFactory()

    private var amountInputViewModel: AmountInputViewModelProtocol?
    private var assetViewModel: LocalizableResource<AssetBalanceViewModelProtocol>?
    private var feeViewModel: LocalizableResource<BalanceViewModelProtocol>?
    private var bondingDurationViewModel: LocalizableResource<String>?

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = StakingUnbondSetupLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()
        setupAmountInputView()
        setupLocalization()
        updateActionButton()

        presenter.setup()
    }

    private func setupLocalization() {
        // TODO: Fix localization
        title = "Unbond"

        rootView.locale = selectedLocale
        rootView.networkFeeView.bind(tokenAmount: "0.001 KSM", fiatAmount: "$0.2")

        setupBalanceAccessoryView()

        applyAssetViewModel()
        applyFeeViewModel()
        applyBondingDuration()
    }

    private func setupAmountInputView() {
        rootView.amountInputView.textField.delegate = self
    }

    private func setupBalanceAccessoryView() {
        let locale = localizationManager?.selectedLocale ?? Locale.current
        let accessoryView = uiFactory.createAmountAccessoryView(for: self, locale: locale)
        rootView.amountInputView.textField.inputAccessoryView = accessoryView
    }

    private func setupNavigationItem() {
        let closeBarItem = UIBarButtonItem(
            image: R.image.iconClose(),
            style: .plain,
            target: self,
            action: #selector(actionClose)
        )

        navigationItem.leftBarButtonItem = closeBarItem
    }

    private func applyAssetViewModel() {
        guard let viewModel = assetViewModel?.value(for: selectedLocale) else {
            return
        }

        let amountView = rootView.amountInputView
        amountView.priceText = viewModel.price

        if let balance = viewModel.balance {
            // TODO: Fix local
            amountView.balanceText = "Bonded: \(balance)"
        } else {
            amountView.balanceText = nil
        }

        amountView.assetIcon = viewModel.icon
        amountView.symbol = viewModel.symbol.uppercased()
    }

    private func applyFeeViewModel() {
        guard let viewModel = feeViewModel?.value(for: selectedLocale) else {
            return
        }

        rootView.networkFeeView.bind(tokenAmount: viewModel.amount, fiatAmount: viewModel.price)
    }

    private func applyBondingDuration() {
        guard let details = bondingDurationViewModel?.value(for: selectedLocale) else {
            return
        }

        rootView.durationView.valueLabel.text = details
    }

    @objc private func actionClose() {
        presenter.close()
    }

    private func updateActionButton() {
        let isEnabled = (amountInputViewModel?.isValid == true)
        rootView.actionButton.isEnabled = isEnabled
    }
}

extension StakingUnbondSetupViewController: StakingUnbondSetupViewProtocol {
    func didReceiveAsset(viewModel: LocalizableResource<AssetBalanceViewModelProtocol>) {
        assetViewModel = viewModel
        applyAssetViewModel()
    }

    func didReceiveFee(viewModel: LocalizableResource<BalanceViewModelProtocol>?) {
        feeViewModel = viewModel
        applyFeeViewModel()
    }

    func didReceiveInput(viewModel: LocalizableResource<AmountInputViewModelProtocol>) {
        amountInputViewModel?.observable.remove(observer: self)

        amountInputViewModel = viewModel.value(for: selectedLocale)
        amountInputViewModel?.observable.add(observer: self)

        rootView.amountInputView.fieldText = amountInputViewModel?.displayAmount
    }

    func didReceiveBonding(duration: LocalizableResource<String>) {
        bondingDurationViewModel = duration
        applyBondingDuration()
    }
}

extension StakingUnbondSetupViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}

extension StakingUnbondSetupViewController: AmountInputAccessoryViewDelegate {
    func didSelect(on _: AmountInputAccessoryView, percentage: Float) {
        rootView.amountInputView.textField.resignFirstResponder()

        presenter.selectAmountPercentage(percentage)
    }

    func didSelectDone(on _: AmountInputAccessoryView) {
        rootView.amountInputView.textField.resignFirstResponder()
    }
}

extension StakingUnbondSetupViewController: AmountInputViewModelObserver {
    func amountInputDidChange() {
        rootView.amountInputView.fieldText = amountInputViewModel?.displayAmount

        updateActionButton()

        let amount = amountInputViewModel?.decimalAmount ?? 0.0
        presenter.updateAmount(amount)
    }
}

extension StakingUnbondSetupViewController: UITextFieldDelegate {
    func textField(
        _: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        amountInputViewModel?.didReceiveReplacement(string, for: range) ?? false
    }
}
