import Foundation

enum Formatters {
    /// Currency with cents, e.g. "$94.00".
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    /// Currency with no cents, e.g. "$94" — used in dense places like the month list.
    static let currencyWhole: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f
    }()

    /// "Tuesday, June 10"
    static let weekdayLong: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    /// "Jun 1"
    static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

extension Double {
    /// "$94.00"
    var asCurrency: String {
        Formatters.currency.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    /// "$94"
    var asCurrencyWhole: String {
        Formatters.currencyWhole.string(from: NSNumber(value: self)) ?? "$0"
    }

    /// Signed currency for deltas, e.g. "+$12" / "-$15".
    var asSignedCurrencyWhole: String {
        let prefix = self >= 0 ? "+" : "-"
        return prefix + abs(self).asCurrencyWhole
    }
}
