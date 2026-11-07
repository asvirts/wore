import SwiftUI
import WoreStore

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlements
    @State private var statusBanner: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 42))
                            .foregroundStyle(.tint)
                        Text("Wore Pro")
                            .font(.title.bold())
                        Text("Your clothes. Pay once.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        feature("Unlimited garments", "The free closet holds 40 pieces. Pro removes the cap.", "infinity")
                        feature("Cost per wear", "Price divided by wears, after the first wear. No price means no number.", "divide")
                        feature("Unworn list", "Pieces you haven't worn, on their own list. Not a fake cost.", "archivebox")
                        feature("Trip lists", "A checklist of pieces you own, with a packed mark.", "suitcase")
                        feature("Today widget", "Today's outfit on the Home Screen.", "rectangle.grid.1x2")
                    }
                    .padding(20)
                    .background(.quaternary.opacity(0.35), in: .rect(cornerRadius: 20))

                    if let error = entitlements.lastError ?? statusBanner {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        Button {
                            Task {
                                let outcome = await entitlements.purchase()
                                if outcome == .purchased {
                                    dismiss()
                                } else if outcome == .pending {
                                    statusBanner = "Purchase is pending approval."
                                }
                            }
                        } label: {
                            Group {
                                if entitlements.isBusy {
                                    ProgressView()
                                } else {
                                    Text("Unlock Wore Pro — \(entitlements.displayPrice)")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .disabled(entitlements.isBusy || entitlements.isPro)

                        Button("Restore Purchases") {
                            Task {
                                let restored = await entitlements.restore()
                                if restored {
                                    dismiss()
                                } else if entitlements.lastError == nil {
                                    statusBanner = "No previous Wore Pro purchase found for this Apple Account."
                                }
                            }
                        }
                        .font(.subheadline)
                        .disabled(entitlements.isBusy)

                        Text("One-time purchase for iPhone and iPad. Family Sharing included. No subscription and no ads.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
        }
        .task {
            await entitlements.loadProductIfNeeded()
        }
    }

    private func feature(_ title: String, _ detail: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
