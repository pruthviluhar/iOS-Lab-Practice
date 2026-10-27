import SwiftUI

@main
struct ShoppingCartApp: App {
    @State private var cartManager = CartManager()

    var body: some Scene {
        WindowGroup {
            ShoppingCartView()
                .environment(cartManager)
        }
    }
}
