import SwiftUI

/// Вкладка «Каталог»: поиск + плитки разделов.
struct CatalogView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var showResults = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                SectionTitle(title: "Каталог", eyebrow: "INTELEGENTOFF")
                SectionTiles(sections: state.sections)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 24)
        }
        .background(Palette.canvas.ignoresSafeArea())
        .appHeader()
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Поиск товаров...")
        .onSubmit(of: .search) { submitSearch() }
        .navigationDestination(isPresented: $showResults) {
            SearchResultsView(query: query.trimmingCharacters(in: .whitespaces))
        }
        .refreshable { await state.loadSections() }
        .task { await state.loadSections() }
    }

    private func submitSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        showResults = true
    }
}

/// Товары раздела (страница /{section_slug})
struct SectionProductsView: View {
    let section: Section

    var body: some View {
        ProductListView(title: section.name, source: .collection(section.slug))
    }
}

/// Результаты поиска (/search?q=)
struct SearchResultsView: View {
    let query: String

    var body: some View {
        ProductListView(title: "Поиск: \(query)", source: .search(query))
    }
}

/// Список товаров с сортировкой и бесконечной подгрузкой (ProductsList / CatalogListing)
struct ProductListView: View {
    enum Source: Equatable {
        case collection(String)
        case search(String)
    }

    let title: String
    let source: Source

    @State private var products: [Product] = []
    @State private var page = 1
    @State private var lastPage = 1
    @State private var total: Int?
    @State private var loading = true
    @State private var sort: CatalogSort?
    @State private var cartSlug: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .appFont(28, .bold)
                    .caps(-0.04, size: 28)
                    .foregroundStyle(Palette.fg)

                HStack {
                    sortMenu
                    Spacer()
                    if let total {
                        Text("\(total) \(Format.pluralize(total, "товар", "товара", "товаров"))")
                            .appFont(12)
                            .foregroundStyle(Palette.subtle)
                    }
                }

                ProductGrid(products: products, loading: loading) { cartSlug = $0.slug }

                if page < lastPage, !products.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .onAppear { Task { await loadMore() } }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
        }
        .screen()
        .addToCartSheet(slug: $cartSlug)
        .refreshable { await reload() }
        .task(id: sort) { await reload() }
    }

    private var sortMenu: some View {
        Menu {
            Button(CatalogSort.popularTitle) { sort = nil }
            ForEach(CatalogSort.allCases) { option in
                Button(option.title) { sort = option }
            }
        } label: {
            HStack(spacing: 6) {
                Text(sort?.title ?? CatalogSort.popularTitle)
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
            }
            .appFont(12, .medium)
            .foregroundStyle(Palette.fg)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .overlay(RoundedRectangle(cornerRadius: Palette.radius).stroke(Palette.line))
        }
    }

    private func fetch(page: Int) async throws -> CatalogResponse {
        switch source {
        case .collection(let slug):
            return try await ShopAPI.collection(slug: slug, page: page, sort: sort)
        case .search(let text):
            return try await ShopAPI.search(text, page: page, sort: sort)
        }
    }

    private func reload() async {
        loading = true
        defer { loading = false }

        do {
            let response = try await fetch(page: 1)
            products = response.products.data
            page = response.products.currentPage
            lastPage = response.products.lastPage
            total = response.products.total
        } catch {
            products = []
            lastPage = 1
        }
    }

    private func loadMore() async {
        guard !loading, page < lastPage else { return }
        loading = true
        defer { loading = false }

        do {
            let response = try await fetch(page: page + 1)
            // Защита от дублей, если каталог изменился между страницами
            let known = Set(products.map(\.id))
            products += response.products.data.filter { !known.contains($0.id) }
            page = response.products.currentPage
            lastPage = response.products.lastPage
        } catch {
            lastPage = page
        }
    }
}
