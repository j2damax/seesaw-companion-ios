// TermsView.swift
// SeeSaw — Tier 2 companion app
//
// Screen 2 — Terms and conditions.
// The "Continue" button is only visible once the parent toggles acceptance.

import SwiftUI

struct TermsView: View {

    private let coordinator: AppCoordinator

    @State private var hasAccepted = false

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                termsScroll
                    .frame(maxHeight: .infinity)

                Divider()

                acceptanceFooter
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color(.systemBackground))
            }
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Scrollable terms body

    private var termsScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                termsSection(
                    title: "1. Privacy & Data",
                    body: """
                    SeeSaw processes all camera and microphone data entirely on-device. \
                    No raw images, audio recordings, or biometric data are ever transmitted \
                    to external servers. Only anonymised scene labels and story prompts are \
                    sent to our cloud service.
                    """
                )
                termsSection(
                    title: "2. Children's Privacy",
                    body: """
                    This app is designed for use by parents on behalf of children. We \
                    comply with COPPA and applicable children's privacy laws. Parents retain \
                    full control over all data and can delete it at any time via Settings → \
                    Sign Out.
                    """
                )
                termsSection(
                    title: "3. Acceptable Use",
                    body: """
                    SeeSaw is intended solely for personal, non-commercial use in educational \
                    and storytelling contexts. You agree not to reverse-engineer, redistribute, \
                    or use the service for any unlawful purpose.
                    """
                )
                termsSection(
                    title: "4. Disclaimer",
                    body: """
                    SeeSaw is provided "as is" without warranty of any kind. AI-generated \
                    stories are creative outputs and should be reviewed by a parent before \
                    sharing with children.
                    """
                )
                termsSection(
                    title: "5. Changes to Terms",
                    body: """
                    We may update these terms from time to time. Continued use of the app \
                    after changes constitutes acceptance of the new terms.
                    """
                )
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func termsSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Accept toggle + continue

    private var acceptanceFooter: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $hasAccepted) {
                Text("I agree to the terms and conditions")
                    .font(.subheadline.weight(.medium))
            }
            .tint(.teal)

            if hasAccepted {
                Button {
                    UserDefaults.standard.hasAcceptedTerms = true
                    coordinator.termsAccepted()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.teal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: hasAccepted)
    }
}

#Preview {
    let container = AppDependencyContainer()
    TermsView(coordinator: AppCoordinator(container: container))
}
