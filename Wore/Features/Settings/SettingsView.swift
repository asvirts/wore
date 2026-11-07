import SwiftUI
import WoreCore
import WoreStore

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EntitlementManager.self) private var entitlements
    @Environment(AppRouter.self) private var router
    @State private var status: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if entitlements.isPro {
                        LabeledContent("Wore Pro") {
                            Label("Unlocked", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Color.accentColor)
                                .font(.subheadline.weight(.semibold))
                        }
                    } else {
                        Button {
                            router.showPaywall = true
                            dismiss()
                        } label: {
                            HStack {
                                Label("Unlock Wore Pro", systemImage: "sparkles")
                                Spacer()
                                Text(entitlements.displayPrice)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    Button("Restore Purchases") {
                        Task {
                            let restored = await entitlements.restore()
                            if restored {
                                status = "Wore Pro is restored."
                            } else if entitlements.lastError == nil {
                                status = "No previous Wore Pro purchase found for this Apple Account."
                            } else {
                                status = entitlements.lastError
                            }
                        }
                    }
                    .disabled(entitlements.isBusy)
                    if let status {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Wore Pro is \(entitlements.displayPrice) once. Family Sharing included. The free closet holds \(ClosetCap.freeLimit) garments, on-device cutout, and the daily outfit log.")
                }

                Section {
                    LabeledContent("Photos", value: "On this device")
                    LabeledContent("Account", value: "None")
                    LabeledContent("Ads", value: "None")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Your closet stays on this iPhone or iPad. Wore does not collect data. App Store privacy label: Data Not Collected.")
                }

                Section {
                    Link("Support", destination: WoreConfig.supportURL)
                    Link("Privacy Policy", destination: WoreConfig.privacyPolicyURL)
                    Link("Terms of Use", destination: WoreConfig.termsURL)
                } header: {
                    Text("About")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
