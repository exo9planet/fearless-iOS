import UIKit
import IrohaCrypto
import SoraFoundation

final class AccountCreatePresenter {
    weak var view: AccountCreateViewProtocol?
    var wireframe: AccountCreateWireframeProtocol!
    var interactor: AccountCreateInteractorInputProtocol!

    let usernameSetup: UsernameSetupModel

    private var metadata: MetaAccountCreationMetadata?

    private var selectedCryptoType: MultiassetCryptoType?

    private var derivationPathViewModel: InputViewModelProtocol?

    init(usernameSetup: UsernameSetupModel) {
        self.usernameSetup = usernameSetup
    }

    private func applyCryptoTypeViewModel() {
        guard let cryptoType = selectedCryptoType else {
            return
        }

        let locale = localizationManager?.selectedLocale ?? Locale.current

        let viewModel = TitleWithSubtitleViewModel(
            title: cryptoType.titleForLocale(locale),
            subtitle: cryptoType.subtitleForLocale(locale)
        )

        view?.setSelectedCrypto(model: viewModel)
    }

    private func applyDerivationPathViewModel() {
        guard let cryptoType = selectedCryptoType else {
            return
        }

        let predicate: NSPredicate
        let placeholder: String

        switch cryptoType {
        case .sr25519:
            predicate = NSPredicate.deriviationPathHardSoftPassword
            placeholder = DerivationPathConstants.hardSoftPasswordPlaceholder
        case .ed25519:
            predicate = NSPredicate.deriviationPathHardPassword
            placeholder = DerivationPathConstants.hardPasswordPlaceholder
        case .substrateEcdsa:
            predicate = NSPredicate.deriviationPathHardPassword
            placeholder = DerivationPathConstants.hardPasswordPlaceholder
        case .ethereumEcdsa:
            predicate = NSPredicate.ethereumAddress
            placeholder = DerivationPathConstants.defaultEthereum
        }

        let inputHandling = InputHandler(predicate: predicate)
        let viewModel = InputViewModel(inputHandler: inputHandling, placeholder: placeholder)

        derivationPathViewModel = viewModel

        view?.setDerivationPath(viewModel: viewModel)
        view?.didValidateDerivationPath(.none)
    }

    private func presentDerivationPathError(_ cryptoType: MultiassetCryptoType) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        // TODO: Check correctness
        switch cryptoType.utilsType {
        case .sr25519:
            _ = wireframe.present(
                error: AccountCreationError.invalidDerivationHardSoftPassword,
                from: view,
                locale: locale
            )
        case .ed25519, .ecdsa:
            _ = wireframe.present(
                error: AccountCreationError.invalidDerivationHardPassword,
                from: view,
                locale: locale
            )
        }
    }
}

extension AccountCreatePresenter: AccountCreatePresenterProtocol {
    func setup() {
        interactor.setup()
    }

    func activateInfo() {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        let message = R.string.localizable.accountCreationInfo(preferredLanguages: locale.rLanguages)
        let title = R.string.localizable.commonInfo(preferredLanguages: locale.rLanguages)
        wireframe.present(
            message: message,
            title: title,
            closeAction: R.string.localizable.commonClose(preferredLanguages: locale.rLanguages),
            from: view
        )
    }

    func validate() {
        guard let viewModel = derivationPathViewModel, let cryptoType = selectedCryptoType else {
            return
        }

        if viewModel.inputHandler.completed {
            view?.didValidateDerivationPath(.valid)
        } else {
            view?.didValidateDerivationPath(.invalid)
            presentDerivationPathError(cryptoType)
        }
    }

    func selectCryptoType() {
        if let metadata = metadata {
            let selectedType = selectedCryptoType ?? metadata.defaultCryptoType
            wireframe.presentCryptoTypeSelection(
                from: view,
                availableTypes: metadata.availableCryptoTypes,
                selectedType: selectedType,
                delegate: self,
                context: nil
            )
        }
    }

    func proceed() {
        guard
            let cryptoType = selectedCryptoType,
            let viewModel = derivationPathViewModel,
            let metadata = metadata
        else {
            return
        }

        guard viewModel.inputHandler.completed else {
            view?.didValidateDerivationPath(.invalid)
            presentDerivationPathError(cryptoType)
            return
        }

        let request = MetaAccountCreationRequest(
            username: usernameSetup.username,
            derivationPath: viewModel.inputHandler.value,
            cryptoType: cryptoType
        )

        wireframe.confirm(
            from: view,
            request: request,
            metadata: metadata
        )
    }
}

extension AccountCreatePresenter: AccountCreateInteractorOutputProtocol {
    func didReceive(metadata: MetaAccountCreationMetadata) {
        self.metadata = metadata

        selectedCryptoType = metadata.defaultCryptoType

        view?.set(mnemonic: metadata.mnemonic)

        applyCryptoTypeViewModel()
        applyDerivationPathViewModel()
    }

    func didReceiveMnemonicGeneration(error: Error) {
        let locale = localizationManager?.selectedLocale ?? Locale.current

        guard !wireframe.present(error: error, from: view, locale: locale) else {
            return
        }

        _ = wireframe.present(
            error: CommonError.undefined,
            from: view,
            locale: locale
        )
    }
}

extension AccountCreatePresenter: ModalPickerViewControllerDelegate {
    func modalPickerDidSelectModelAtIndex(_ index: Int, context _: AnyObject?) {
        selectedCryptoType = metadata?.availableCryptoTypes[index]

        applyCryptoTypeViewModel()
        applyDerivationPathViewModel()

        view?.didCompleteCryptoTypeSelection()
    }

    func modalPickerDidCancel(context _: AnyObject?) {
        view?.didCompleteCryptoTypeSelection()
    }
}

extension AccountCreatePresenter: Localizable {
    func applyLocalization() {
        if let view = view, view.isSetup {
            applyCryptoTypeViewModel()
        }
    }
}
