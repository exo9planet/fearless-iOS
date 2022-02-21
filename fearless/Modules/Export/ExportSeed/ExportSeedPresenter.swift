import Foundation
import SoraFoundation

final class ExportSeedPresenter {
    weak var view: ExportGenericViewProtocol?
    var wireframe: ExportSeedWireframeProtocol!
    var interactor: ExportSeedInteractorInputProtocol!

    let address: String
    let chain: ChainModel
    let localizationManager: LocalizationManager

    private(set) var exportViewModel: ExportStringViewModel?

    init(address: String, chain: ChainModel, localizationManager: LocalizationManager) {
        self.address = address
        self.chain = chain
        self.localizationManager = localizationManager
    }

    private func share() {
        guard let viewModel = exportViewModel else {
            return
        }

        let text: String

        let locale = localizationManager.selectedLocale

        if let derivationPath = viewModel.derivationPath {
            text = R.string.localizable
                .exportSeedWithDpTemplate(
                    viewModel.chain.name,
                    viewModel.data,
                    derivationPath,
                    preferredLanguages: locale.rLanguages
                )
        } else {
            text = R.string.localizable
                .exportSeedWithoutDpTemplate(
                    viewModel.chain.name,
                    viewModel.data,
                    preferredLanguages: locale.rLanguages
                )
        }

        wireframe.share(source: TextSharingSource(message: text), from: view) { [weak self] completed in
            if completed {
                self?.wireframe.close(view: self?.view)
            }
        }
    }
}

extension ExportSeedPresenter: ExportGenericPresenterProtocol {
    func setup() {
        interactor.fetchExportDataForAddress(address, chain: chain)
    }

    func activateExport() {
        let locale = localizationManager.selectedLocale

        let title = R.string.localizable.accountExportWarningTitle(preferredLanguages: locale.rLanguages)
        let message = R.string.localizable.accountExportWarningMessage(preferredLanguages: locale.rLanguages)

        let exportTitle = R.string.localizable.accountExportAction(preferredLanguages: locale.rLanguages)
        let exportAction = AlertPresentableAction(title: exportTitle) { [weak self] in
            self?.share()
        }

        let cancelTitle = R.string.localizable.commonCancel(preferredLanguages: locale.rLanguages)
        let viewModel = AlertPresentableViewModel(
            title: title,
            message: message,
            actions: [exportAction],
            closeAction: cancelTitle
        )

        wireframe.present(viewModel: viewModel, style: .alert, from: view)
    }
}

extension ExportSeedPresenter: ExportSeedInteractorOutputProtocol {
    func didReceive(exportData: ExportSeedData) {
        let viewModel = ExportStringViewModel(
            option: .seed,
            chain: exportData.chain,
            cryptoType: exportData.cryptoType,
            derivationPath: exportData.derivationPath,
            data: exportData.seed.toHex(includePrefix: true)
        )

        exportViewModel = viewModel

        view?.set(viewModel: viewModel)
    }

    func didReceive(error: Error) {
        if !wireframe.present(error: error, from: view, locale: localizationManager.selectedLocale) {
            _ = wireframe.present(
                error: CommonError.undefined,
                from: view,
                locale: localizationManager.selectedLocale
            )
        }
    }
}
