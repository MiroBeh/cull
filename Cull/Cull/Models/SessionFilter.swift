import Foundation
import Photos

enum SessionFilter: Hashable {
    case all
    case month(year: Int, month: Int)
    case album(localId: String, title: String)

    var displayTitle: String {
        switch self {
        case .all:
            return "All Photos"
        case .month(let y, let m):
            var comps = DateComponents()
            comps.year = y
            comps.month = m
            guard let date = Calendar.current.date(from: comps) else { return "Photos" }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM yyyy"
            return fmt.string(from: date)
        case .album(_, let title):
            return title
        }
    }
}

struct MonthBucket: Identifiable, Hashable {
    let year: Int
    let month: Int
    let totalCount: Int
    let unreviewedCount: Int

    var id: String { "\(year)-\(month)" }

    var displayTitle: String {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }
}
