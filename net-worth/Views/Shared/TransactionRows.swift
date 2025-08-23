import SwiftUI

// Reusable, minimal transaction row following app design tokens
@ViewBuilder
public func transactionRowView(date: Date, value: Double, operation: String?, currency: String) -> some View {
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
        Text(value, format: .currency(code: currency))
            .font(.headline.weight(.semibold))
            .foregroundColor(value >= 0 ? .airbnbSuccess : .red)
            .monospacedDigit()
            .contentTransition(.numericText())
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
public func transactionRowView(date: Date, value: Double, previousValue: Double?, operation: String?, currency: String) -> some View {
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
            Text(value, format: .currency(code: currency))
                .font(.headline.weight(.semibold))
                .foregroundColor(amountColor)
                .monospacedDigit()
                .contentTransition(.numericText())
            if let prev = previousValue {
                let delta = value - prev
                let tint: Color = delta >= 0 ? .airbnbSuccess : .red
                HStack(spacing: 6) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.bold))
                    Text(CurrencyShort.shortString(abs(delta), currency: currency))
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundColor(tint)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Capsule().fill(tint.opacity(0.12)))
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
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.placeholderFill)
                    .frame(width: 120, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.placeholderFill)
                    .frame(width: 80, height: 10)
                    .opacity(0.85)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.placeholderFill)
                .frame(width: 100, height: 16)
        }
        .padding(14)
        .shimmer()
    }
    .frame(maxWidth: .infinity, minHeight: 56)
    .elevatedShadow()
}
