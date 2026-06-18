import SwiftUI
import UIKit

/// Configures global UIKit appearance proxies so the navigation bar and tab bar
/// adopt the Ristoro system (ink bars, gold accents, Deco typography). Called
/// once at app launch.
enum ThemeAppearance {
    static func apply() {
        let paper = UIColor(Theme.Palette.paper1)
        let ink = UIColor(Theme.Palette.ink1)
        let gold = UIColor(Theme.Palette.gold)
        let goldDeep = UIColor(Theme.Palette.goldDeep)

        // Navigation bar: paper background, ink titles, gold large-title accent.
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = paper
        nav.shadowColor = UIColor(Theme.Palette.line)
        let titleFont = UIFont(name: "AvenirNext-DemiBold", size: 17) ?? .boldSystemFont(ofSize: 17)
        let largeFont = UIFont(name: "Futura-Medium", size: 30) ?? .boldSystemFont(ofSize: 30)
        nav.titleTextAttributes = [.foregroundColor: ink, .font: titleFont]
        nav.largeTitleTextAttributes = [.foregroundColor: ink, .font: largeFont]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = goldDeep

        // Tab bar: paper background with gold selection.
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = paper
        tab.shadowColor = UIColor(Theme.Palette.line)
        let item = tab.stackedLayoutAppearance
        item.selected.iconColor = gold
        item.selected.titleTextAttributes = [.foregroundColor: goldDeep,
                                             .font: UIFont(name: "AvenirNext-DemiBold", size: 10) ?? .systemFont(ofSize: 10)]
        item.normal.iconColor = UIColor(Theme.Palette.ink3)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.Palette.ink3),
                                          .font: UIFont(name: "AvenirNext-Medium", size: 10) ?? .systemFont(ofSize: 10)]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
