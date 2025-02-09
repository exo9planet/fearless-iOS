import UIKit
import SoraFoundation
import SoraUI

final class AccountManagementViewController: UIViewController {
    private enum Constants {
        static let cellHeight: CGFloat = 48.0
        static let addActionVerticalInset: CGFloat = 16
    }

    var presenter: AccountManagementPresenterProtocol!

    @IBOutlet private var tableView: UITableView!

    @IBOutlet private var addActionControl: TriangularedButton!
    @IBOutlet private var addActionHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var addActionBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupNavigationItem()
        setupLocalization()

        presenter.setup()
    }

    private func setupNavigationItem() {
        let rightBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: self,
            action: #selector(actionEdit)
        )

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: R.color.colorWhite()!,
            .font: UIFont.h5Title
        ]

        rightBarButtonItem.setTitleTextAttributes(attributes, for: .normal)
        rightBarButtonItem.setTitleTextAttributes(attributes, for: .highlighted)

        navigationItem.rightBarButtonItem = rightBarButtonItem

        if navigationController?.presentingViewController != nil {
            let leftBarButton = UIBarButtonItem(image: R.image.iconClose(), style: .plain, target: self, action: #selector(closeButtonClicked))
            leftBarButton.tintColor = R.color.colorWhite()
            navigationItem.leftBarButtonItem = leftBarButton
        }
    }

    @objc private func closeButtonClicked() {
        presenter.didTapCloseButton()
    }

    private func setupLocalization() {
        let locale = localizationManager?.selectedLocale

        title = R.string.localizable.profileWalletsTitle(preferredLanguages: locale?.rLanguages)

        addActionControl.imageWithTitleView?.title = R.string.localizable
            .settingsAddWallet(preferredLanguages: locale?.rLanguages)

        updateRightItem()
    }

    private func updateRightItem() {
        let locale = localizationManager?.selectedLocale

        if tableView.isEditing {
            navigationItem.rightBarButtonItem?.title = R.string.localizable
                .commonDone(preferredLanguages: locale?.rLanguages)
        } else {
            navigationItem.rightBarButtonItem?.title = R.string.localizable
                .commonEdit(preferredLanguages: locale?.rLanguages)
        }
    }

    private func setupTableView() {
        tableView.tableFooterView = UIView()
        let bottomInset = addActionBottomConstraint.constant
            + addActionHeightConstraint.constant
            + Constants.addActionVerticalInset
        tableView.contentInset = .init(top: 0, left: 0, bottom: bottomInset, right: 0)

        tableView.registerClassForCell(WalletTableViewCell.self)

        tableView.rowHeight = Constants.cellHeight
    }

    @objc func actionEdit() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        updateRightItem()

        for cell in tableView.visibleCells {
            if let accountCell = cell as? WalletTableViewCell {
                accountCell.setReordering(tableView.isEditing, animated: true)
            }
        }
    }

    @IBAction func actionAdd() {
        presenter.activateAddAccount()
    }
}

// swiftlint:disable force_cast
extension AccountManagementViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        presenter.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithType(WalletTableViewCell.self) else {
            return UITableViewCell()
        }

        cell.delegate = self
        cell.setReordering(tableView.isEditing, animated: false)

        let item = presenter.item(at: indexPath.row)
        cell.bind(to: item)

        return cell
    }
}

// swiftlint:enable force_cast

extension AccountManagementViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        presenter.selectItem(at: indexPath.row)
    }

    func tableView(_: UITableView, canMoveRowAt _: IndexPath) -> Bool {
        true
    }

    func tableView(
        _: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        presenter.moveItem(
            at: sourceIndexPath.row,
            to: destinationIndexPath.row
        )
    }

    func tableView(
        _ tableView: UITableView,
        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
        toProposedIndexPath proposedDestinationIndexPath: IndexPath
    ) -> IndexPath {
        if proposedDestinationIndexPath.section < sourceIndexPath.section {
            return IndexPath(row: 0, section: sourceIndexPath.section)
        } else if proposedDestinationIndexPath.section > sourceIndexPath.section {
            let count = tableView.numberOfRows(inSection: sourceIndexPath.section)
            return IndexPath(row: count - 1, section: sourceIndexPath.section)
        } else {
            return proposedDestinationIndexPath
        }
    }

    func tableView(
        _: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        !presenter.item(at: indexPath.row).isSelected ? .delete : .none
    }

    func tableView(
        _: UITableView,
        commit _: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        presenter.removeItem(at: indexPath.row)
    }

    func tableView(_: UITableView, titleForDeleteConfirmationButtonForRowAt _: IndexPath) -> String? {
        R.string.localizable.connectionDeleteConfirm(
            preferredLanguages: localizationManager?.selectedLocale.rLanguages
        )
    }
}

extension AccountManagementViewController: AccountManagementViewProtocol {
    func reload() {
        tableView.reloadData()
    }

    func didRemoveItem(at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        tableView.deleteRows(at: [indexPath], with: .left)
    }
}

extension AccountManagementViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}

extension AccountManagementViewController: WalletTableViewCellDelegate {
    func didSelectInfo(_ cell: WalletTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        presenter.activateWalletDetails(at: indexPath.row)
    }
}
