import SwiftUI

// Reusable, minimal transaction row following app design tokens
@ViewBuilder
public func transactionRowView(date: Date, value: Double, operation: String?, currency: String, invested: Double? = nil, showUnits: Bool = false) -> some View {
    HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateFormatter.dayMonYear.string(from: date))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            if let op = operation, !op.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(op)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 4) {
            if showUnits {
                let tint: Color = value >= 0 ? .airbnbSuccess : .red
                HStack(spacing: 6) {
                    Text("Units")
                        .font(.caption2.weight(.bold))
                    Text(value, format: .number.precision(.fractionLength(0...6)))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundColor(tint)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Capsule().fill(tint.opacity(0.12)))
                .contentTransition(.numericText())
            } else {
                Text(value, format: .currency(code: currency))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(value >= 0 ? .airbnbSuccess : .red)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            if let inv = invested {
                Text("Invested · " + CurrencyShort.shortString(inv, currency: currency))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
    .padding(14)
    .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    .background(
        RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
            .fill(Color.elevatedBackground)
    )
    .elevatedShadow()
}

// Overload: show delta compared to previous transaction
@ViewBuilder
public func transactionRowView(
    date: Date,
    value: Double,
    previousValue: Double?,
    operation: String?,
    currency: String,
    invested: Double? = nil,
    previousInvested: Double? = nil,
    showUnits: Bool = false
) -> some View {
    HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
            Text(DateFormatter.dayMonYear.string(from: date))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            if let op = operation, !op.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(op)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        Spacer()
        let amountColor: Color = value >= 0 ? .airbnbSuccess : .red
        VStack(alignment: .trailing, spacing: 4) {
            if showUnits {
                let tint: Color = amountColor
                HStack(spacing: 6) {
                    Text("Units")
                        .font(.caption2.weight(.bold))
                    Text(value, format: .number.precision(.fractionLength(0...6)))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundColor(tint)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Capsule().fill(tint.opacity(0.12)))
                .contentTransition(.numericText())
            } else {
                Text(value, format: .currency(code: currency))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(amountColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            if let prev = previousValue {
                let delta = value - prev
                let tint: Color = delta >= 0 ? .airbnbSuccess : .red
                let pctText: String? = prev.magnitude > 0 ? (delta / prev.magnitude).formatted(.percent.precision(.fractionLength(1))) : nil
                HStack(spacing: 6) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.bold))
                    if showUnits {
                        Text(abs(delta), format: .number.precision(.fractionLength(0...6)))
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                    } else {
                        Text(CurrencyShort.shortString(abs(delta), currency: currency))
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                    }
                    if let p = pctText {
                        Text("•").font(.caption2.weight(.bold))
                        Text(p)
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .foregroundColor(tint)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Capsule().fill(tint.opacity(0.12)))
            }
            if let inv = invested, let pinv = previousInvested {
                let invDelta = inv - pinv
                let tint: Color = invDelta >= 0 ? .airbnbSuccess : .red
                let pctText: String? = pinv.magnitude > 0 ? (invDelta / pinv.magnitude).formatted(.percent.precision(.fractionLength(1))) : nil
                HStack(spacing: 6) {
                    Image(systemName: invDelta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.bold))
                    Text("Invested " + CurrencyShort.shortString(abs(invDelta), currency: currency))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                    if let p = pctText {
                        Text("•").font(.caption2.weight(.bold))
                        Text(p)
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .foregroundColor(tint)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Capsule().fill(tint.opacity(0.12)))
            } else if let inv = invested {
                Text("Invested · " + CurrencyShort.shortString(inv, currency: currency))
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }
    .padding(14)
    .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
    .background(
        RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
            .fill(Color.elevatedBackground)
    )
    .elevatedShadow()
}

// Shimmer placeholder for transaction row
@ViewBuilder
public func transactionPlaceholderRow() -> some View {
    ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: LayoutConstants.cardCornerRadius, style: .continuous)
            .fill(Color.elevatedBackground)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                ShimmerBlock(width: 120, height: 12, cornerRadius: 4)
                ShimmerBlock(width: 80, height: 10, cornerRadius: 4)
            }
            Spacer()
            ShimmerBlock(width: 100, height: 16, cornerRadius: 4)
        }
        .padding(14)
    }
    .frame(maxWidth: .infinity, minHeight: 56)
    .elevatedShadow()
}
