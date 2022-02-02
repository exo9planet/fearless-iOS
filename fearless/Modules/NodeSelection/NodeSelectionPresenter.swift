import Foundation
import SoraFoundation

final class NodeSelectionPresenter {
    weak var view: NodeSelectionViewProtocol?
    let wireframe: NodeSelectionWireframeProtocol
    let interactor: NodeSelectionInteractorInputProtocol
    let viewModelFactory: NodeSelectionViewModelFactoryProtocol

    init(
        interactor: NodeSelectionInteractorInputProtocol,
        wireframe: NodeSelectionWireframeProtocol,
        viewModelFactory: NodeSelectionViewModelFactoryProtocol,
        localizationManager: LocalizationManagerProtocol
    ) {
        self.interactor = interactor
        self.wireframe = wireframe
        self.viewModelFactory = viewModelFactory
        self.localizationManager = localizationManager
    }
}

extension NodeSelectionPresenter: NodeSelectionPresenterProtocol {
    func setup() {
        interactor.setup()
    }
}

extension NodeSelectionPresenter: NodeSelectionInteractorOutputProtocol {
    func didReceive(chain: ChainModel) {
        let viewModel = viewModelFactory.buildViewModel(from: chain)
        view?.didReceive(state: .loaded(viewModel: viewModel))
    }
}

extension NodeSelectionPresenter: Localizable {
    func applyLocalization() {
        view?.didReceive(locale: selectedLocale)
    }
}
