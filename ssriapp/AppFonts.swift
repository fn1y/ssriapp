import SwiftUI
import UIKit

// These app-local definitions keep .font(.headline), .font(.title.bold()), etc.
// using SN Pro. They do not replace fonts inside Apple's own system UI.
extension Font {
    static let largeTitle = Font.custom("SNPro-Regular", size: 34, relativeTo: .largeTitle)
    static let title = Font.custom("SNPro-Regular", size: 28, relativeTo: .title)
    static let title2 = Font.custom("SNPro-Regular", size: 22, relativeTo: .title2)
    static let title3 = Font.custom("SNPro-Regular", size: 20, relativeTo: .title3)
    static let headline = Font.custom("SNPro-Semibold", size: 17, relativeTo: .headline)
    static let subheadline = Font.custom("SNPro-Regular", size: 15, relativeTo: .subheadline)
    static let body = Font.custom("SNPro-Regular", size: 17, relativeTo: .body)
    static let callout = Font.custom("SNPro-Regular", size: 16, relativeTo: .callout)
    static let footnote = Font.custom("SNPro-Regular", size: 13, relativeTo: .footnote)
    static let caption = Font.custom("SNPro-Regular", size: 12, relativeTo: .caption)
    static let caption2 = Font.custom("SNPro-Regular", size: 11, relativeTo: .caption2)
}

enum AppFonts {
    @MainActor
    static func configureNavigationTitles() {
        let navigationBar = UINavigationBar.appearance()
        if let font = UIFont(name: "SNPro-Semibold", size: 17) {
            navigationBar.titleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
            ]
        }
        if let font = UIFont(name: "SNPro-Bold", size: 34) {
            navigationBar.largeTitleTextAttributes = [
                .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
            ]
        }
    }
}
