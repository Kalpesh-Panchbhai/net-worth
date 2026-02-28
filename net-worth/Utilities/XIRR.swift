import Foundation

/// Protocol for any data point that has a date, value, and invested amount.
protocol DatedInvestmentPoint {
    var pointDate: Date { get }
    var pointValue: Double { get }
    var pointInvested: Double { get }
}

/// XIRR (Extended Internal Rate of Return) calculator.
///
/// Matches Excel's XIRR definition:
///   Find rate `r` such that  Σ  C_i / (1+r)^((d_i − d_0)/365) = 0
/// Uses Newton-Raphson with Bisection fallback for robustness.
struct XIRR {

    // MARK: - Public API

    /// Calculate XIRR from an array of data points that conform to `DatedInvestmentPoint`.
    /// - Returns: Annualized return as a percentage (e.g. 12.5 for 12.5%), or nil if it cannot be computed.
    static func calculate<P: DatedInvestmentPoint>(from points: [P]) -> Double? {
        guard points.count >= 2 else { return nil }

        // Build cash-flow series
        var cashFlows: [(date: Date, amount: Double)] = []

        // Day 0: initial invested amount goes out (negative)
        cashFlows.append((points[0].pointDate, -points[0].pointInvested))

        // Intermediate: each change in invested is an additional outflow
        for i in 1..<points.count {
            let delta = points[i].pointInvested - points[i - 1].pointInvested
            if abs(delta) > 0.01 {
                cashFlows.append((points[i].pointDate, -delta))
            }
        }

        // Final: current portfolio value comes back (positive)
        let last = points[points.count - 1]
        cashFlows.append((last.pointDate, last.pointValue))

        guard cashFlows.count >= 2 else { return nil }

        // Must have at least one positive and one negative cash flow
        let hasPositive = cashFlows.contains { $0.amount > 0 }
        let hasNegative = cashFlows.contains { $0.amount < 0 }
        guard hasPositive && hasNegative else { return nil }

        return solve(cashFlows: cashFlows)
    }

    // MARK: - Solver

    /// Excel XIRR: Σ C_i · (1+r)^(−(d_i−d_0)/365) = 0
    private static func solve(cashFlows: [(date: Date, amount: Double)]) -> Double? {
        let d0 = cashFlows[0].date

        // Pre-compute day fractions (Excel uses exactly 365)
        let flows: [(t: Double, c: Double)] = cashFlows.map { cf in
            let days = cf.date.timeIntervalSince(d0) / 86400.0
            return (days / 365.0, cf.amount)
        }

        // NPV at a given rate
        func npv(_ r: Double) -> Double {
            flows.reduce(0.0) { sum, f in sum + f.c * pow(1.0 + r, -f.t) }
        }

        // Derivative of NPV w.r.t. r
        func dnpv(_ r: Double) -> Double {
            flows.reduce(0.0) { sum, f in sum + (-f.t) * f.c * pow(1.0 + r, -f.t - 1.0) }
        }

        // --- Newton-Raphson (primary) ---
        var rate = 0.1  // initial guess 10%
        let maxIter = 200
        let tol = 1e-7

        for _ in 0..<maxIter {
            let f = npv(rate)
            if abs(f) < tol { return rate * 100.0 }

            let df = dnpv(rate)
            guard df.isFinite, abs(df) > 1e-12 else { break }

            var step = f / df
            // Dampen large steps to avoid overshooting
            if abs(step) > 1.0 { step = step > 0 ? 1.0 : -1.0 }
            rate -= step

            // Keep rate > -1 (discount factor must remain positive)
            if rate <= -1.0 { rate = -0.99 }
        }

        // Check if Newton converged
        if abs(npv(rate)) < tol { return rate * 100.0 }

        // --- Bisection fallback ---
        var lo = -0.99
        var hi = 10.0  // 1000%
        var fLo = npv(lo)
        let fHi = npv(hi)

        // Need opposite signs to bracket the root
        guard fLo * fHi < 0 else { return nil }

        for _ in 0..<300 {
            let mid = (lo + hi) / 2.0
            let fMid = npv(mid)
            if abs(fMid) < tol { return mid * 100.0 }
            if fLo * fMid < 0 {
                hi = mid
            } else {
                lo = mid
                fLo = fMid
            }
        }

        return nil
    }
}
