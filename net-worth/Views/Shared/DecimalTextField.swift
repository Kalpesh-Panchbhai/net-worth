import SwiftUI

/// Reusable decimal text field that restricts input to numbers with up to a fixed number of
/// fraction digits. Optionally allows a leading minus sign. Keeps UX lenient while typing
/// (e.g., allows trailing "." or just "-") but sanitizes aggressively on change.
public struct DecimalTextField: View {
    @Binding var text: String
    public var placeholder: String = "0.00"
    public var fractionDigits: Int = 2
    public var allowNegative: Bool = true
    public var alignTrailing: Bool = true

    public init(text: Binding<String>, placeholder: String = "0.00", fractionDigits: Int = 2, allowNegative: Bool = true, alignTrailing: Bool = true) {
        self._text = text
        self.placeholder = placeholder
        self.fractionDigits = max(0, fractionDigits)
        self.allowNegative = allowNegative
        self.alignTrailing = alignTrailing
    }

    public var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numbersAndPunctuation)
            .multilineTextAlignment(alignTrailing ? .trailing : .leading)
            .onChange(of: text) { _, newValue in
                let sanitized = sanitize(newValue)
                if sanitized != newValue { text = sanitized }
            }
    }

    private func sanitize(_ input: String) -> String {
        var out = ""
        var hasDot = false
        var hasMinus = false
        for ch in input {
            if ch >= "0" && ch <= "9" {
                out.append(ch)
                continue
            }
            if ch == "." && !hasDot {
                hasDot = true
                out.append(ch)
                continue
            }
            if allowNegative && ch == "-" && !hasMinus && out.isEmpty {
                hasMinus = true
                out.append(ch)
                continue
            }
            // drop any other characters
        }
        // Enforce fraction digit limit
        if hasDot, let dot = out.firstIndex(of: ".") {
            let fracStart = out.index(after: dot)
            let frac = out[fracStart...]
            if frac.count > fractionDigits {
                let keep = out[..<out.index(fracStart, offsetBy: fractionDigits)]
                out = String(keep)
            }
        }
        // Disallow a bare "-0" becoming "-00..." — normalize repeated leading zeros (optional)
        // Allow intermediate states like "-" or "0." while typing
        return out
    }
}
