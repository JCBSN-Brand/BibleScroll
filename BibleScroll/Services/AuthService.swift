//
//  AuthService.swift
//  BibleScroll
//
//  DEPRECATED: This service is no longer used.
//  Premium status is now tracked by SubscriptionService.isPremium
//  which properly syncs with StoreKit purchases.
//
//  This file can be safely deleted.
//

import Foundation

/// DEPRECATED: Use SubscriptionService.isPremium instead
/// This class is no longer used and can be removed.
@available(*, deprecated, message: "Use SubscriptionService.isPremium instead")
class AuthService: ObservableObject {
    @Published var isPremium: Bool = false
}
