import SwiftUI

// Reusable row card for financial assets (Accounts, Watchlists, etc.)
struct AssetRowCard: View {
    let name: String
    let current: Double
    let invested: Double
    let previous: Double
    let currency: String
    // Optional badge shown near the title (e.g., watchlist account count)
    var countBadge: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                header
                meta
                stats
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: LayoutConstants.cardMinHeight, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }

    // MARK: - Subviews
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(name)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            if let c = countBadge, c > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.stack").font(.caption)
                    Text("\(c)")
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(.secondary)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(Capsule().fill(Color.secondary.opacity(0.12)))
                .fixedSize()
            }
            Spacer(minLength: 0)
            Text(current, format: .currency(code: currency))
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private var meta: some View {
        HStack(spacing: 8) {
            Text("Invested")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            Text(invested, format: .currency(code: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.airbnbPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }

    private var stats: some View {
        let totalPL = current - invested
        let plPct: Double? = invested.magnitude > 0 ? (totalPL / invested.magnitude) : nil
        let plPctText: String? = plPct.map { $0.formatted(.percent.precision(.fractionLength(1))) }

        let dayDelta = current - previous
        let dayPct: Double? = previous.magnitude > 0 ? (dayDelta / previous.magnitude) : nil
        let dayPctText: String? = dayPct.map { $0.formatted(.percent.precision(.fractionLength(1))) }

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("P/L")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                WideStatPill(
                    icon: totalPL >= 0 ? "arrow.up.right" : "arrow.down.right",
                    value: abs(totalPL),
                    currency: currency,
                    percent: plPctText,
                    tint: totalPL >= 0 ? .airbnbSuccess : .red
                )
            }
            HStack(spacing: 10) {
                Text("1 day change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
                WideStatPill(
                    icon: dayDelta >= 0 ? "arrow.up.right" : "arrow.down.right",
                    value: abs(dayDelta),
                    currency: currency,
                    percent: dayPctText,
                    tint: dayDelta >= 0 ? .airbnbSuccess : .red
                )
            }
        }
    }
}

extension AssetRowCard {
    var bodyWithModifiers: some View {
        body
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: LayoutConstants.cardMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                    .fill(Color.elevatedBackground)
            )
            .elevatedShadow()
    }
}

extension AssetRowCard {
    static func placeholder(countBadge: Int? = nil) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Title + current value row
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.placeholderFill)
                        .frame(width: 140, height: 14)
                        .fixedSize()
                    if let c = countBadge, c > 0 {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.placeholderFill)
                            .frame(width: 36, height: 18)
                    }
                    Spacer(minLength: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.placeholderFill)
                        .frame(width: 90, height: 16)
                }
                // Invested row
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.placeholderFill)
                        .frame(width: 60, height: 10)
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.placeholderFill)
                        .frame(width: 80, height: 12)
                }
                // Two stat lines (P/L and 1 day change)
                VStack(spacing: 8) {
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.placeholderFill)
                            .frame(width: 40, height: 10)
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.placeholderFill)
                            .frame(width: 110, height: 18)
                    }
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.placeholderFill)
                            .frame(width: 80, height: 10)
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.placeholderFill)
                            .frame(width: 110, height: 18)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
                .fill(Color.elevatedBackground)
        )
        .elevatedShadow()
    }
}
