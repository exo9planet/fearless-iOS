import UIKit
import FearlessUtils
import RobinHood

final class CrowdloanListInteractor: RuntimeConstantFetching {
    weak var presenter: CrowdloanListInteractorOutputProtocol!

    let runtimeService: RuntimeCodingServiceProtocol
    let crowdloanOperationFactory: CrowdloanOperationFactoryProtocol
    let connection: JSONRPCEngine
    let operationManager: OperationManagerProtocol
    let displayInfoProvider: AnySingleValueProvider<CrowdloanDisplayInfoList>
    let singleValueProviderFactory: SingleValueProviderFactoryProtocol
    let chain: Chain
    let logger: LoggerProtocol?

    private var blockNumberProvider: AnyDataProvider<DecodedBlockNumber>?

    init(
        runtimeService: RuntimeCodingServiceProtocol,
        crowdloanOperationFactory: CrowdloanOperationFactoryProtocol,
        connection: JSONRPCEngine,
        singleValueProviderFactory: SingleValueProviderFactoryProtocol,
        chain: Chain,
        operationManager: OperationManagerProtocol,
        logger: LoggerProtocol? = nil
    ) {
        self.runtimeService = runtimeService
        self.crowdloanOperationFactory = crowdloanOperationFactory

        displayInfoProvider = singleValueProviderFactory.getJson(
            for: chain.crowdloanDisplayInfoURL()
        )

        self.singleValueProviderFactory = singleValueProviderFactory
        self.connection = connection
        self.operationManager = operationManager
        self.chain = chain
        self.logger = logger
    }

    private func provideCrowdloans() {
        let crowdloanWrapper = crowdloanOperationFactory.fetchCrowdloansOperation(
            connection: connection,
            runtimeService: runtimeService,
            chain: chain
        )

        crowdloanWrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let crowdloans = try crowdloanWrapper.targetOperation.extractNoCancellableResultData()
                    self?.presenter.didReceiveCrowdloans(result: .success(crowdloans))
                } catch {
                    if
                        let encodingError = error as? StorageKeyEncodingOperationError,
                        encodingError == .invalidStoragePath {
                        self?.presenter.didReceiveCrowdloans(result: .success([]))
                    } else {
                        self?.presenter.didReceiveCrowdloans(result: .failure(error))
                    }
                }
            }
        }

        operationManager.enqueue(operations: crowdloanWrapper.allOperations, in: .transient)
    }

    private func subscribeToDisplayInfo() {
        let updateClosure: ([DataProviderChange<CrowdloanDisplayInfoList>]) -> Void = { [weak self] changes in
            if let result = changes.reduceToLastChange() {
                self?.presenter.didReceiveDisplayInfo(result: .success(result.toMap()))
            }
        }

        let failureClosure: (Error) -> Void = { [weak self] error in
            self?.presenter.didReceiveDisplayInfo(result: .failure(error))
        }

        let options = DataProviderObserverOptions(alwaysNotifyOnRefresh: true, waitsInProgressSyncOnAdd: false)

        displayInfoProvider.addObserver(
            self,
            deliverOn: .main,
            executing: updateClosure,
            failing: failureClosure,
            options: options
        )
    }

    private func provideConstants() {
        fetchConstant(
            for: .babeBlockTime,
            runtimeCodingService: runtimeService,
            operationManager: operationManager
        ) { [weak self] (result: Result<BlockTime, Error>) in
            self?.presenter.didReceiveBlockDuration(result: result)
        }

        fetchConstant(
            for: .paraLeasingPeriod,
            runtimeCodingService: runtimeService,
            operationManager: operationManager
        ) { [weak self] (result: Result<LeasingPeriod, Error>) in
            self?.presenter.didReceiveLeasingPeriod(result: result)
        }
    }
}

extension CrowdloanListInteractor: CrowdloanListInteractorInputProtocol {
    func setup() {
        provideCrowdloans()

        subscribeToDisplayInfo()

        blockNumberProvider = subscribeToBlockNumber(for: chain, runtimeService: runtimeService)

        provideConstants()
    }

    func refresh() {
        displayInfoProvider.refresh()

        provideCrowdloans()

        provideConstants()
    }
}

extension CrowdloanListInteractor: SingleValueProviderSubscriber, SingleValueSubscriptionHandler {
    func handleBlockNumber(result: Result<BlockNumber?, Error>, chain _: Chain) {
        presenter.didReceiveBlockNumber(result: result)
    }
}