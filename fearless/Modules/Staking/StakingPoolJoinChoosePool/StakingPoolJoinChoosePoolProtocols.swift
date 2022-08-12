import Foundation

typealias StakingPoolJoinChoosePoolModuleCreationResult = (
    view: StakingPoolJoinChoosePoolViewInput,
    input: StakingPoolJoinChoosePoolModuleInput
)

protocol StakingPoolJoinChoosePoolViewInput: ControllerBackedProtocol {
    func didReceive(cellViewModels: [StakingPoolListTableCellModel])
    func didReceive(locale: Locale)
}

protocol StakingPoolJoinChoosePoolViewOutput: AnyObject {
    func didLoad(view: StakingPoolJoinChoosePoolViewInput)
    func didTapBackButton()
}

protocol StakingPoolJoinChoosePoolInteractorInput: AnyObject {
    func setup(with output: StakingPoolJoinChoosePoolInteractorOutput)
}

protocol StakingPoolJoinChoosePoolInteractorOutput: AnyObject {
    func didReceivePools(_ pools: [StakingPool]?)
    func didReceiveError(_ error: Error)
}

protocol StakingPoolJoinChoosePoolRouterInput: AnyObject, PushDismissable {}

protocol StakingPoolJoinChoosePoolModuleInput: AnyObject {}

protocol StakingPoolJoinChoosePoolModuleOutput: AnyObject {}
