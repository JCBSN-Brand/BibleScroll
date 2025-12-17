//
//  SubscriptionService.swift
//  BibleScroll
//
//  Handles in-app subscription purchases with StoreKit 2
//

import Foundation
import StoreKit

@MainActor
class SubscriptionService: ObservableObject {
    // Product IDs matching App Store Connect
    static let monthlyPayNow = "com.gabrieljacobson.biblescroll.premium.monthly.paynow"
    static let monthlyTrial = "com.gabrieljacobson.biblescroll.premium.monthly.trial"
    static let yearlyPayNow = "com.gabrieljacobson.biblescroll.premium.yearly.paynow"
    static let yearlyTrial = "com.gabrieljacobson.biblescroll.premium.yearly.trial"
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    private var updateListenerTask: Task<Void, Never>?
    
    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [
                Self.monthlyPayNow,
                Self.monthlyTrial,
                Self.yearlyPayNow,
                Self.yearlyTrial
            ]
            
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Get Product
    
    func getProduct(yearly: Bool, withTrial: Bool) -> Product? {
        let productID: String
        
        switch (yearly, withTrial) {
        case (false, false): productID = Self.monthlyPayNow
        case (false, true): productID = Self.monthlyTrial
        case (true, false): productID = Self.yearlyPayNow
        case (true, true): productID = Self.yearlyTrial
        }
        
        return products.first { $0.id == productID }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                print("✅ Purchase successful: \(product.id)")
                isLoading = false
                return true
                
            case .userCancelled:
                print("⚠️ User cancelled purchase")
                isLoading = false
                return false
                
            case .pending:
                print("⏳ Purchase pending")
                isLoading = false
                return false
                
            @unknown default:
                print("❌ Unknown purchase result")
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ Purchase error: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ Purchases restored")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Restore error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if subscription is still active
                if transaction.revocationDate == nil {
                    purchasedIDs.insert(transaction.productID)
                }
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }
        
        purchasedProductIDs = purchasedIDs
        print("📦 Purchased products: \(purchasedIDs)")
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            // Listen for transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    // Update purchased products
                    await self.updatePurchasedProducts()
                    
                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
}

// MARK: - Errors

enum SubscriptionError: Error {
    case failedVerification
}

