import Foundation
import StoreKit
import Combine

final class HvpStoreManager: NSObject, ObservableObject {
    struct Pack: Identifiable {
        let id: String
        let name: String
        let fallbackPrice: String
        let spotlights: Int
    }

    static let catalog: [Pack] = [
        Pack(id: "com.huvypum.iap.t4k9qm", name: "Spotlight Pack 1", fallbackPrice: "$0.99", spotlights: 8),
        Pack(id: "com.huvypum.iap.b7n2xw", name: "Spotlight Pack 2", fallbackPrice: "$2.99", spotlights: 28),
        Pack(id: "com.huvypum.iap.c8p5zd", name: "Spotlight Pack 3", fallbackPrice: "$4.99", spotlights: 56),
        Pack(id: "com.huvypum.iap.f1r6yh", name: "Spotlight Pack 4", fallbackPrice: "$9.99", spotlights: 120),
        Pack(id: "com.huvypum.iap.g3s8vk", name: "Spotlight Pack 5", fallbackPrice: "$19.99", spotlights: 260),
        Pack(id: "com.huvypum.iap.h5u0lm", name: "Spotlight Pack 6", fallbackPrice: "$29.99", spotlights: 420),
        Pack(id: "com.huvypum.iap.j9w2nd", name: "Spotlight Pack 7", fallbackPrice: "$49.99", spotlights: 760),
        Pack(id: "com.huvypum.iap.k2y4pe", name: "Spotlight Pack 8", fallbackPrice: "$99.99", spotlights: 1600)
    ]

    @Published var spotlights: Int = 8
    @Published var isBuying = false
    @Published var statusText: String = ""
    @Published var events: [HvpCreditEvent] = []

    private var request: SKProductsRequest?
    private var pendingPackId: String?
    private var updatesTask: Task<Void, Never>?
    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        watchTransactionUpdates()
        if defaults.object(forKey: HvpKeys.spotlights) == nil {
            spotlights = 8
            persistBalance()
        } else {
            spotlights = defaults.integer(forKey: HvpKeys.spotlights)
        }
    }

    deinit {
        updatesTask?.cancel()
        SKPaymentQueue.default().remove(self)
    }

    private func watchTransactionUpdates() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await self?.credit(transaction)
                await transaction.finish()
            }
        }
    }

    @MainActor
    private func credit(_ transaction: Transaction) {
        guard let pack = pack(for: transaction.productID) else { return }
        grant(spotlights: pack.spotlights, packKey: pack.id, transactionId: String(transaction.id))
        statusText = "Added Spotlights from \(pack.name)."
        isBuying = false
        pendingPackId = nil
    }

    func loadBalance() {
        if defaults.object(forKey: HvpKeys.spotlights) == nil {
            spotlights = 8
            persistBalance()
        } else {
            spotlights = defaults.integer(forKey: HvpKeys.spotlights)
        }
    }

    func buy(_ pack: Pack) {
        guard !isBuying else { return }
        isBuying = true
        statusText = "Checking that pack…"
        pendingPackId = pack.id
        let req = SKProductsRequest(productIdentifiers: [pack.id])
        req.delegate = self
        request = req
        req.start()
    }

    func spendSave() -> Bool {
        guard spotlights >= HvpAppCopy.saveCost else { return false }
        spotlights -= HvpAppCopy.saveCost
        persistBalance()
        return true
    }

    func refundSave() {
        spotlights += HvpAppCopy.saveCost
        persistBalance()
    }

    func eraseBalance() {
        spotlights = 0
        events = []
        persistBalance()
    }

    private func grant(spotlights amount: Int, packKey: String, transactionId: String) {
        if events.contains(where: { $0.transactionId == transactionId }) {
            return
        }
        spotlights += amount
        persistBalance()
        events.append(
            HvpCreditEvent(
                id: UUID(),
                createdAt: Date(),
                packKey: packKey,
                transactionId: transactionId,
                granted: amount
            )
        )
    }

    private func persistBalance() {
        defaults.set(spotlights, forKey: HvpKeys.spotlights)
    }

    private func pack(for packKey: String) -> Pack? {
        Self.catalog.first { $0.id == packKey }
    }
}

extension HvpStoreManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            guard let product = response.products.first else {
                self.isBuying = false
                self.statusText = "That pack is not available right now."
                self.pendingPackId = nil
                return
            }
            guard SKPaymentQueue.canMakePayments() else {
                self.isBuying = false
                self.statusText = "Purchases are turned off on this iPhone."
                self.pendingPackId = nil
                return
            }
            SKPaymentQueue.default().add(SKPayment(product: product))
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isBuying = false
            self.statusText = "Could not reach the store. Try again."
            self.pendingPackId = nil
        }
    }
}

extension HvpStoreManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                let packKey = transaction.payment.productIdentifier
                let tid = String(transaction.transactionIdentifier ?? UUID().uuidString)
                DispatchQueue.main.async {
                    if let pack = self.pack(for: packKey) {
                        self.grant(spotlights: pack.spotlights, packKey: packKey, transactionId: tid)
                        self.statusText = "Added Spotlights from \(pack.name)."
                    }
                    self.isBuying = false
                    self.pendingPackId = nil
                }
                queue.finishTransaction(transaction)
            case .failed:
                DispatchQueue.main.async {
                    self.isBuying = false
                    self.statusText = "Purchase canceled."
                    self.pendingPackId = nil
                }
                queue.finishTransaction(transaction)
            case .restored:
                queue.finishTransaction(transaction)
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}
