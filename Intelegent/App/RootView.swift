import SwiftUI

enum AppTab: String, Hashable {
    case home, catalog, cart, profile
}

struct RootView: View {
    @Environment(AppState.self) private var state

    @State private var tab: AppTab = Self.initialTab
    @State private var homePath = NavigationPath()
    @State private var catalogPath = NavigationPath()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $homePath) {
                HomeView()
                    .withRoutes()
            }
            .tabItem { Label("Главная", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack(path: $catalogPath) {
                CatalogView()
                    .withRoutes()
            }
            .tabItem { Label("Каталог", systemImage: "square.grid.2x2") }
            .tag(AppTab.catalog)

            NavigationStack {
                CartPlaceholderView()
            }
            .tabItem { Label("Корзина", systemImage: "bag") }
            .badge(state.cartQuantity)
            .tag(AppTab.cart)

            NavigationStack {
                ProfilePlaceholderView()
            }
            .tabItem { Label("Профиль", systemImage: "person") }
            .tag(AppTab.profile)
        }
        .tint(Palette.fg)
        .overlay(alignment: .bottom) { AddedToCartToast() }
        .onAppear(perform: openScreenshotScreen)
    }

    // MARK: - Режим скриншотов (CI)

    /// CI запускает приложение с `-uiScreen product` и т. п. и снимает экран.
    /// UserDefaults сам читает аргументы запуска вида `-ключ значение`.
    private static var screenshotScreen: String? {
        UserDefaults.standard.string(forKey: "uiScreen")
    }

    private static var initialTab: AppTab {
        switch screenshotScreen {
        case "catalog", "section", "product": .catalog
        case "cart": .cart
        case "profile": .profile
        default: .home
        }
    }

    private func openScreenshotScreen() {
        switch Self.screenshotScreen {
        case "section":
            catalogPath.append(Route.section(Self.demoSection))
        case "product":
            let slug = UserDefaults.standard.string(forKey: "uiProduct") ?? "futbolka-black-g-wagon-2"
            catalogPath.append(Route.product(slug: slug))
        default:
            break
        }
    }

    private static var demoSection: Section {
        let json = #"{"id":3,"attribute_data":{"name":{"ru":"Футболки"}},"url":{"slug":"futbolki"},"image":null}"#
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try! decoder.decode(Section.self, from: Data(json.utf8))
    }
}

private extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .section(let section):
                SectionProductsView(section: section)
            case .product(let slug):
                ProductDetailView(slug: slug)
            case .search(let text):
                SearchResultsView(query: text)
            }
        }
    }
}

// MARK: - Общая шапка

/// Шапка экрана как на мобильном сайте: логотип слева, переключатель темы справа.
struct AppHeader: ViewModifier {
    @AppStorage("theme") private var theme: ThemeChoice = .system
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Logo(size: 20)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        theme = colorScheme == .dark ? .light : .dark
                    } label: {
                        Image(systemName: colorScheme == .dark ? "sun.max" : "moon")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.fg)
                            .frame(width: 36, height: 36)
                            .overlay(RoundedRectangle(cornerRadius: Palette.radius).stroke(Palette.lineStrong))
                    }
                    .accessibilityLabel("Переключить тему")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.canvas, for: .navigationBar)
    }
}

extension View {
    func appHeader() -> some View { modifier(AppHeader()) }

    /// Фон экрана и стиль заголовка для вложенных экранов
    func screen(_ title: String = "") -> some View {
        background(Palette.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.canvas, for: .navigationBar)
    }
}

// MARK: - Временные экраны

struct CartPlaceholderView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        EmptyStateView(
            systemImage: "bag",
            title: state.cartQuantity > 0 ? "В корзине \(state.cartQuantity) \(Format.pluralize(state.cartQuantity, "товар", "товара", "товаров"))" : "Корзина пуста",
            text: "Экран корзины — следующий этап"
        )
        .frame(maxHeight: .infinity)
        .screen("Корзина")
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        EmptyStateView(
            systemImage: "person",
            title: "Профиль",
            text: "Вход и личный кабинет появятся после добавления токенов в API"
        )
        .frame(maxHeight: .infinity)
        .screen("Профиль")
    }
}
