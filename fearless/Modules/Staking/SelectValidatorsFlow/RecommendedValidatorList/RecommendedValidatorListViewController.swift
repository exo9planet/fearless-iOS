import UIKit
import SoraFoundation

final class RecommendedValidatorListViewController: UIViewController {
    var presenter: RecommendedValidatorListPresenterProtocol!

    @IBOutlet private var tableView: UITableView!
    @IBOutlet var continueButton: TriangularedButton!

    private var viewModel: RecommendedValidatorListViewModelProtocol?
    private weak var headerView: RecommendedValidatorListHeaderView?

    var selectedLocale: Locale {
        localizationManager?.selectedLocale ?? .autoupdatingCurrent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupLocalization()
        presenter.setup()
    }

    private func setupTableView() {
        tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 100.0, right: 0.0)
        tableView.tableFooterView = UIView()

        tableView.register(R.nib.recommendedValidatorCell)
        tableView.rowHeight = UIConstants.cellHeight

        if let headerView = R.nib.recommendedValidatorListHeaderView.firstView(owner: nil) {
            headerView.heightAnchor.constraint(equalToConstant: UIConstants.tableHeaderHeight)
                .isActive = true
            tableView.tableHeaderView = headerView

            self.headerView = headerView
        }
    }

    private func updateHeaderView() {
        if let viewModel = viewModel {
            let title = viewModel
                .itemsCountString.value(for: selectedLocale)

            let details = viewModel.rewardColumnTitle

            headerView?.bind(
                title: title.uppercased(),
                details: details.uppercased()
            )
        }
    }

    private func setupLocalization() {
        let languages = selectedLocale.rLanguages
        title = R.string.localizable
            .stakingRecommendedSectionTitle(preferredLanguages: languages)

        updateHeaderView()
    }

    @IBAction private func actionContinue() {
        presenter.proceed()
    }
}

extension RecommendedValidatorListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        viewModel?.itemViewModels.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(
                withIdentifier: R.reuseIdentifier.selectedValidatorCellId,
                for: indexPath
            )!

        let items = viewModel?.itemViewModels ?? []
        cell.bind(viewModel: items[indexPath.row].value(for: selectedLocale))
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.selectedValidatorAt(index: indexPath.row)
    }
}

extension RecommendedValidatorListViewController: RecommendedValidatorListViewProtocol {
    func didReceive(viewModel: RecommendedValidatorListViewModelProtocol) {
        title = viewModel.title

        self.viewModel = viewModel
        updateHeaderView()

        continueButton.imageWithTitleView?.title = viewModel.continueButtonTitle

        if viewModel.continueButtonEnabled {
            continueButton.applyEnabledStyle()
        } else {
            continueButton.applyDisabledStyle()
        }

        tableView.reloadData()
    }
}

extension RecommendedValidatorListViewController {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
            view.setNeedsLayout()
        }
    }
}

extension RecommendedValidatorListViewController: RecommendedValidatorCellDelegate {
    func didTapInfoButton(in cell: RecommendedValidatorCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            presenter.showValidatorInfoAt(index: indexPath.row)
        }
    }
}
