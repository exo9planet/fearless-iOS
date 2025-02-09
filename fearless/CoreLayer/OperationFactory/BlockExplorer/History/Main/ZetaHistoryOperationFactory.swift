import Foundation
import RobinHood
import CommonWallet
import IrohaCrypto
import SSFUtils
import SSFModels
import FearlessKeys
import BigInt

final class ZetaHistoryOperationFactory {
    private func createOperation(
        address: String,
        url: URL,
        chainAsset: ChainAsset
    ) -> BaseOperation<ZetaHistoryResponse> {
        let requestFactory = BlockNetworkRequestFactory {
            var url = url.appendingPathComponent(address)

            if case .erc20 = chainAsset.asset.ethereumType {
                let contract = chainAsset.asset.id
                url = url.appendingPathComponent("token-transfers")

                var urlComponents = URLComponents(string: url.absoluteString)
                let queryItems = [URLQueryItem(name: "token", value: contract)]
                urlComponents?.queryItems = queryItems

                guard let urlWithParameters = urlComponents?.url else {
                    return URLRequest(url: url)
                }

                url = urlWithParameters
            } else {
                url = url.appendingPathComponent("transactions")
            }

            var request = URLRequest(url: url)
            request.httpMethod = HttpMethod.get.rawValue

            return request
        }

        let resultFactory = AnyNetworkResultFactory<ZetaHistoryResponse> { data, response, error in

            do {
                if let data = data {
                    let response = try JSONDecoder().decode(
                        ZetaHistoryResponse.self,
                        from: data
                    )

                    return .success(response)
                } else if let error = error {
                    return .failure(error)
                } else {
                    return .failure(SubqueryHistoryOperationFactoryError.incorrectInputData)
                }
            } catch {
                return .failure(error)
            }
        }

        let operation = NetworkOperation(
            requestFactory: requestFactory,
            resultFactory: resultFactory
        )

        return operation
    }

    private func createMapOperation(
        dependingOn remoteOperation: BaseOperation<ZetaHistoryResponse>,
        address: String,
        asset: AssetModel,
        chain: ChainModel
    ) -> BaseOperation<AssetTransactionPageData?> {
        ClosureOperation {
            let remoteTransactions = try remoteOperation.extractNoCancellableResultData().items

            let transactions = remoteTransactions
                .compactMap {
                    AssetTransactionData.createTransaction(from: $0, address: address, chain: chain, asset: asset)
                }.filter { $0.amount.decimalValue > 0 }
                .sorted(by: { $0.timestamp > $1.timestamp })

            return AssetTransactionPageData(transactions: transactions)
        }
    }
}

extension ZetaHistoryOperationFactory: HistoryOperationFactoryProtocol {
    func fetchTransactionHistoryOperation(
        asset: AssetModel,
        chain: ChainModel,
        address: String,
        filters _: [WalletTransactionHistoryFilter],
        pagination _: Pagination
    ) -> CompoundOperationWrapper<AssetTransactionPageData?> {
        guard let baseUrl = chain.externalApi?.history?.url else {
            return CompoundOperationWrapper.createWithError(SubqueryHistoryOperationFactoryError.urlMissing)
        }

        let remoteOperation = createOperation(
            address: address,
            url: baseUrl,
            chainAsset: ChainAsset(chain: chain, asset: asset)
        )

        let mapOperation = createMapOperation(
            dependingOn: remoteOperation,
            address: address,
            asset: asset,
            chain: chain
        )

        mapOperation.addDependency(remoteOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [remoteOperation])
    }
}

// MARK: - Zeta response

struct ZetaHistoryResponse: Codable {
    let items: [ZetaItem]
    let nextPageParams: NextPageParams?

    enum CodingKeys: String, CodingKey {
        case items
        case nextPageParams = "next_page_params"
    }
}

struct ZetaItem: Codable {
    let timestamp: String
    let from: ZetaAddress
    let to: ZetaAddress
    let fee: ZetaFee?

    @OptionStringCodable var value: BigUInt?
    let total: ZetaTotal?

    let hash: String?
    let txHash: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        timestamp = try container.decode(String.self, forKey: .timestamp)
        from = try container.decode(ZetaAddress.self, forKey: .from)
        to = try container.decode(ZetaAddress.self, forKey: .to)
        fee = try container.decodeIfPresent(ZetaFee.self, forKey: .fee)

        if let value = try container.decodeIfPresent(String.self, forKey: .value) {
            self.value = BigUInt(string: value)
        } else {
            value = nil
        }
        total = try container.decodeIfPresent(ZetaTotal.self, forKey: .total)

        hash = try container.decodeIfPresent(String.self, forKey: .hash)
        txHash = try container.decodeIfPresent(String.self, forKey: .txHash)
    }
}

struct ZetaFee: Codable {
    let type: String
    @StringCodable var value: BigUInt
}

struct ZetaAddress: Codable {
    let hash: String
}

struct NextPageParams: Codable {
    let blockNumber, index, itemsCount: Int?

    enum CodingKeys: String, CodingKey {
        case blockNumber = "block_number"
        case index
        case itemsCount = "items_count"
    }
}

struct ZetaTotal: Codable {
    let decimals: String
    @StringCodable var value: BigUInt
}
