import Foundation
import BigInt

struct CrossChainConfirmationData {
    let wallet: MetaAccountModel
    let originChainAsset: ChainAsset
    let destChainModel: ChainModel
    let amount: BigUInt
    let amountViewModel: BalanceViewModelProtocol
    let originChainFee: BalanceViewModelProtocol
    let destChainFee: BalanceViewModelProtocol
}
