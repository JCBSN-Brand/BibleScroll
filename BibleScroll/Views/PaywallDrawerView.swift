//
//  PaywallDrawerView.swift
//  BibleScroll
//
//  Paywall drawer for premium features
//

import SwiftUI

struct PaywallDrawerView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var withFreeTrial: Bool = false
    @State private var animateIn = false
    @State private var isPurchasing = false
    
    enum SubscriptionPlan {
        case monthly
        case yearly
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.height < 700
            let horizontalPadding: CGFloat = min(32, geometry.size.width * 0.08)
            
            ZStack {
                Color.white
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: isCompact ? 30 : 60)
                        
                        // Crown icon
                        Image("crown-icon")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isCompact ? 50 : 70, height: isCompact ? 50 : 70)
                            .foregroundColor(.black)
                            .opacity(animateIn ? 1 : 0)
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .animation(.easeOut(duration: 0.5), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 16 : 28)
                        
                        // Title
                        Text("Unlock Scroll The Bible")
                            .font(.custom("Georgia", size: isCompact ? 24 : 28))
                            .fontWeight(.regular)
                            .foregroundColor(.black)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 8 : 12)
                        
                        // Subtitle
                        Text("Deeper study. Unlimited access.")
                            .font(.system(size: isCompact ? 13 : 15, weight: .medium))
                            .foregroundColor(.gray)
                            .tracking(0.5)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.15), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 24 : 40)
                        
                        // Features list
                        VStack(spacing: isCompact ? 12 : 16) {
                            PaywallFeatureRow(text: "AI-powered Bible study", isCompact: isCompact)
                            PaywallFeatureRow(text: "Explain It Easier button", isCompact: isCompact)
                            PaywallFeatureRow(text: "Cross-references & context", isCompact: isCompact)
                            PaywallFeatureRow(text: "Ad-free experience", isCompact: isCompact)
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 20 : 32)
                        
                        // Free trial toggle
                        PaywallFreeTrialToggle(withFreeTrial: $withFreeTrial, isCompact: isCompact)
                            .padding(.horizontal, horizontalPadding)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 15)
                            .animation(.easeOut(duration: 0.4).delay(0.22), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 14 : 20)
                        
                        // Subscription options
                        VStack(spacing: isCompact ? 10 : 12) {
                            // Yearly plan
                            PaywallSubscriptionOptionView(
                                plan: .yearly,
                                isSelected: selectedPlan == .yearly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                onSelect: { selectedPlan = .yearly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            // Monthly plan
                            PaywallSubscriptionOptionView(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                withFreeTrial: withFreeTrial,
                                isCompact: isCompact,
                                onSelect: { selectedPlan = .monthly },
                                getPrice: getPrice,
                                getSavings: getSavings
                            )
                            
                            // No commitment text
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: isCompact ? 10 : 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Text("No commitment · Cancel anytime")
                                    .font(.system(size: isCompact ? 10 : 12, weight: .regular))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, isCompact ? 2 : 4)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.25), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 12 : 16)
                        
                        // Subscribe button
                        Button(action: {
                            Task {
                                await purchaseSubscription()
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isPurchasing {
                                    CrownLoadingView(size: 18, tint: .white)
                                }
                                Text(isPurchasing ? "Processing..." : "Continue")
                                    .font(.system(size: isCompact ? 15 : 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isCompact ? 14 : 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isPurchasing ? Color.gray : Color.black)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, horizontalPadding)
                        .disabled(isPurchasing)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.95)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 10 : 16)
                        
                        // Restore purchases
                        Button(action: {
                            Task {
                                await subscriptionService.restorePurchases()
                                if subscriptionService.isPremium {
                                    isPresented = false
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: isCompact ? 11 : 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: animateIn)
                        
                        Spacer()
                            .frame(height: isCompact ? 16 : 30)
                        
                        // Terms
                        HStack(spacing: 4) {
                            Text("Terms")
                                .underline()
                            Text("·")
                            Text("Privacy")
                                .underline()
                        }
                        .font(.system(size: isCompact ? 10 : 11, weight: .regular))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.bottom, isCompact ? 20 : 30)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: animateIn)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .scrollDisabled(geometry.size.height >= 700)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onDisappear {
            animateIn = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSubscription() async {
        isPurchasing = true
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        guard let product = subscriptionService.getProduct(
            yearly: selectedPlan == .yearly,
            withTrial: withFreeTrial
        ) else {
            print("❌ Product not found")
            isPurchasing = false
            return
        }
        
        let success = await subscriptionService.purchase(product)
        
        if success {
            // Close paywall on successful purchase
            isPresented = false
        }
        
        isPurchasing = false
    }
    
    private func getPrice(for plan: SubscriptionPlan, withTrial: Bool) -> String {
        if let product = subscriptionService.getProduct(yearly: plan == .yearly, withTrial: withTrial) {
            return product.displayPrice
        }
        // Fallback to hardcoded prices
        switch (plan, withTrial) {
        case (.monthly, false): return "$3.99"
        case (.monthly, true): return "$4.99"
        case (.yearly, false): return "$19.99"
        case (.yearly, true): return "$29.99"
        }
    }
    
    private func getMonthlyEquivalent(for plan: SubscriptionPlan, withTrial: Bool) -> String {
        switch (plan, withTrial) {
        case (.monthly, _): return "/month"
        case (.yearly, false): return "/month ($1.67/mo)"
        case (.yearly, true): return "/month ($2.49/mo)"
        }
    }
    
    private func getSavings(for plan: SubscriptionPlan, withTrial: Bool) -> String? {
        switch plan {
        case .monthly: return nil
        case .yearly: return withTrial ? "Save 50%" : "Save 58%"
        }
    }
}

// MARK: - Feature Row
struct PaywallFeatureRow: View {
    let text: String
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: isCompact ? 10 : 12) {
            Image(systemName: "checkmark")
                .font(.system(size: isCompact ? 10 : 12, weight: .bold))
                .foregroundColor(.black)
            
            Text(text)
                .font(.system(size: isCompact ? 13 : 15, weight: .regular))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
        }
        .padding(.horizontal, isCompact ? 40 : 50)
    }
}

// MARK: - Free Trial Toggle
struct PaywallFreeTrialToggle: View {
    @Binding var withFreeTrial: Bool
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Pay Now option (left)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    withFreeTrial = false
                }
            }) {
                Text("Pay Now")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(withFreeTrial ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(withFreeTrial ? Color.clear : Color.black)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Free Trial option (right)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    withFreeTrial = true
                }
            }) {
                Text("Free Trial")
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .foregroundColor(withFreeTrial ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 10 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(withFreeTrial ? Color.black : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Subscription Option View
struct PaywallSubscriptionOptionView: View {
    let plan: PaywallDrawerView.SubscriptionPlan
    let isSelected: Bool
    let withFreeTrial: Bool
    var isCompact: Bool = false
    let onSelect: () -> Void
    let getPrice: (PaywallDrawerView.SubscriptionPlan, Bool) -> String
    let getSavings: (PaywallDrawerView.SubscriptionPlan, Bool) -> String?
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: isCompact ? 18 : 22, height: isCompact ? 18 : 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.black)
                            .frame(width: isCompact ? 10 : 12, height: isCompact ? 10 : 12)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(plan == .yearly ? "Annual" : "Monthly")
                            .font(.system(size: isCompact ? 14 : 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        if let savings = getSavings(plan, withFreeTrial) {
                            Text(savings)
                                .font(.system(size: isCompact ? 9 : 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, isCompact ? 6 : 8)
                                .padding(.vertical, isCompact ? 2 : 3)
                                .background(
                                    Capsule()
                                        .fill(Color.black)
                                )
                        }
                    }
                    
                }
                
                Spacer()
                
                // Price
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(plan == .yearly ? (withFreeTrial ? "$2.49" : "$1.67") : getPrice(plan, withFreeTrial))
                        .font(.system(size: isCompact ? 16 : 18, weight: .semibold))
                        .foregroundColor(.black)
                    Text("/month")
                        .font(.system(size: isCompact ? 10 : 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, isCompact ? 14 : 18)
            .padding(.vertical, isCompact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.black.opacity(0.03) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallDrawerView(isPresented: .constant(true))
}

