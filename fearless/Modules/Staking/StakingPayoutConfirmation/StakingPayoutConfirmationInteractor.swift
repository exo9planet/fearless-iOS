import Foundation
import SoraKeystore
import CommonWallet
import RobinHood
import IrohaCrypto

final class StakingPayoutConfirmationInteractor {
    private let providerFactory: SingleValueProviderFactoryProtocol
    private let substrateProviderFactory: SubstrateDataProviderFactoryProtocol
    private let extrinsicService: ExtrinsicServiceProtocol
    private let runtimeService: RuntimeCodingServiceProtocol
    private let signer: SigningWrapperProtocol
    private let balanceProvider: AnyDataProvider<DecodedAccountInfo>
    private let priceProvider: AnySingleValueProvider<PriceData>
    private let settings: SettingsManagerProtocol
    private let logger: LoggerProtocol?
    private let payouts: [PayoutInfo]

    var stashControllerProvider: StreamableProvider<StashItem>?
    var payeeProvider: AnyDataProvider<DecodedPayee>?

    weak var presenter: StakingPayoutConfirmationInteractorOutputProtocol!

    init(
        providerFactory: SingleValueProviderFactoryProtocol,
        substrateProviderFactory: SubstrateDataProviderFactoryProtocol,
        extrinsicService: ExtrinsicServiceProtocol,
        runtimeService: RuntimeCodingServiceProtocol,
        signer: SigningWrapperProtocol,
        balanceProvider: AnyDataProvider<DecodedAccountInfo>,
        priceProvider: AnySingleValueProvider<PriceData>,
        settings: SettingsManagerProtocol,
        logger: LoggerProtocol? = nil,
        payouts: [PayoutInfo]
    ) {
        self.providerFactory = providerFactory
        self.substrateProviderFactory = substrateProviderFactory
        self.extrinsicService = extrinsicService
        self.runtimeService = runtimeService
        self.signer = signer
        self.balanceProvider = balanceProvider
        self.priceProvider = priceProvider
        self.settings = settings
        self.logger = logger
        self.payouts = payouts
    }

    // MARK: - Private functions

    private func handle(stashItem: StashItem?) {
        if let stashItem = stashItem {
            clearPayeeProvider()
            subscribeToPayee(address: stashItem.stash)
        }

        presenter?.didReceive(stashItem: stashItem)
    }

    private func createExtrinsicBuilderClosure() -> ExtrinsicBuilderClosure? {
        let callFactory = SubstrateCallFactory()

        let closure: ExtrinsicBuilderClosure = { builder in
            try self.payouts.forEach { payout in
                let payoutCall = try callFactory.payout(
                    validatorId: payout.validator,
                    era: payout.era
                )

                _ = try builder.adding(call: payoutCall)
            }

            return builder
        }

        return closure
    }

    private func subscribeToAccountChanges() {
        let updateClosure = { [weak self] (changes: [DataProviderChange<DecodedAccountInfo>]) in
            let balanceItem = changes.reduceToLastChange()?.item?.data
            self?.presenter.didReceive(balance: balanceItem)
        }

        let failureClosure = { [weak self] (error: Error) in
            self?.presenter.didReceive(balanceError: error)
            return
        }

        let options = DataProviderObserverOptions(
            alwaysNotifyOnRefresh: false,
            waitsInProgressSyncOnAdd: false
        )
        balanceProvider.addObserver(
            self,
            deliverOn: .main,
            executing: updateClosure,
            failing: failureClosure,
            options: options
        )
    }

    private func subscribeToPriceChanges() {
        let updateClosure = { [weak self] (changes: [DataProviderChange<PriceData>]) in
            if changes.isEmpty {
                self?.presenter.didReceive(price: nil)
            } else {
                for change in changes {
                    switch change {
                    case let .insert(item), let .update(item):
                        self?.presenter.didReceive(price: item)
                    case .delete:
                        self?.presenter.didReceive(price: nil)
                    }
                }
            }
        }

        let failureClosure = { [weak self] (error: Error) in
            self?.presenter.didReceive(priceError: error)
            return
        }

        let options = DataProviderObserverOptions(
            alwaysNotifyOnRefresh: false,
            waitsInProgressSyncOnAdd: false
        )

        priceProvider.addObserver(
            self,
            deliverOn: .main,
            executing: updateClosure,
            failing: failureClosure,
            options: options
        )
    }

    private func subscribeToStashControllerProvider() {
        guard stashControllerProvider == nil, let selectedAccount = settings.selectedAccount else {
            return
        }

        let provider = substrateProviderFactory.createStashItemProvider(for: selectedAccount.address)

        let changesClosure: ([DataProviderChange<StashItem>]) -> Void = { [weak self] changes in
            let stashItem = changes.reduceToLastChange()
            self?.handle(stashItem: stashItem)
        }

        let failureClosure: (Error) -> Void = { [weak self] error in
            self?.presenter.didReceive(stashItemError: error)
            return
        }

        provider.addObserver(
            self,
            deliverOn: .main,
            executing: changesClosure,
            failing: failureClosure,
            options: StreamableProviderObserverOptions.substrateSource()
        )

        stashControllerProvider = provider
    }

    func subscribeToPayee(address: String) {
        guard payeeProvider == nil else {
            return
        }

        guard let payeeProvider = try? providerFactory
            .getPayee(for: address, runtimeService: runtimeService)
        else {
            logger?.error("Can't create payee provider")
            return
        }

        self.payeeProvider = payeeProvider

        let updateClosure = { [weak self] (changes: [DataProviderChange<DecodedPayee>]) in
            if let payee = changes.reduceToLastChange() {
                self?.presenter.didReceive(rawRewardDest: payee.item)
            }
        }

        let failureClosure = { [weak self] (error: Error) in
            self?.presenter.didReceive(payeeError: error)
            return
        }

        let options = DataProviderObserverOptions(
            alwaysNotifyOnRefresh: false,
            waitsInProgressSyncOnAdd: false
        )

        payeeProvider.addObserver(
            self,
            deliverOn: .main,
            executing: updateClosure,
            failing: failureClosure,
            options: options
        )
    }

    private func clearPayeeProvider() {
        payeeProvider?.removeObserver(self)
        payeeProvider = nil
    }

    private func getRewardData() {
        guard let account = settings.selectedAccount else { return }

        let rewardAmount = payouts.map(\.reward).reduce(0, +)

        presenter.didRecieve(
            account: account,
            rewardAmount: rewardAmount
        )
    }
}

extension StakingPayoutConfirmationInteractor: StakingPayoutConfirmationInteractorInputProtocol {
    func setup() {
        subscribeToStashControllerProvider()
        subscribeToAccountChanges()
        subscribeToPriceChanges()
        getRewardData()
    }

    func submitPayout() {
        guard let closure = createExtrinsicBuilderClosure() else {
            return
        }

        presenter.didStartPayout()

        extrinsicService.submit(
            closure,
            signer: signer,
            runningIn: .main
        ) { [weak self] result in
            switch result {
            case let .success(txHash):
                self?.presenter.didCompletePayout(txHash: txHash)
            case let .failure(error):
                self?.presenter.didFailPayout(error: error)
            }
        }
    }

    func estimateFee() {
        guard let closure = createExtrinsicBuilderClosure() else {
            return
        }

        extrinsicService.estimateFee(closure, runningIn: .main) { [weak self] result in
            switch result {
            case let .success(info):
                self?.presenter.didReceive(paymentInfo: info)
            case let .failure(error):
                self?.presenter.didReceive(feeError: error)
            }
        }
    }
}
