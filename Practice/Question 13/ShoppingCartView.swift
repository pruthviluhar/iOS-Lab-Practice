
import SwiftUI

// MARK: - Main Tab Bar

struct ShoppingCartView: View {    @Environment(CartManager.self) private var cart

    var body: some View {
        TabView {
            ProductsView()
                .tabItem {
                    Label("Products", systemImage: "square.grid.2x2")
                }
                .tag(0)

            CartView()
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
                .badge(cart.itemCount)
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

// MARK: - Products

struct ProductsView: View {
    @Environment(CartManager.self) private var cart

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if cart.isLoadingProducts && cart.products.isEmpty {
                    ProgressView("Loading products...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let error = cart.productLoadError {
                    ContentUnavailableView {
                        Label("Products Unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await cart.loadProducts()
                            }
                        }
                    }

                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(cart.products) { product in
                                ProductCard(product: product)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Products")
            .task {
                await cart.loadProducts()
            }
        }
    }
}

struct ProductCard: View {
    @Environment(CartManager.self) private var cart

    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: product.image)
                .resizable()
                .scaledToFit()
                .frame(height: 65)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.blue)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(product.name)
                .font(.headline)
                .lineLimit(2)

            Text(product.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("₹\(product.price, specifier: "%.2f")")
                .font(.subheadline.bold())

            Button {
                cart.addToCart(product)
            } label: {
                Label("Add to Cart", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Cart

struct CartView: View {
    @Environment(CartManager.self) private var cart

    var body: some View {
        NavigationStack {
            Group {
                if cart.cartItems.isEmpty {
                    ContentUnavailableView(
                        "Your Cart Is Empty",
                        systemImage: "cart",
                        description: Text("Add some products to get started.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            cartItemsSection
                            couponSection
                            priceSummary
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Cart")
        }
    }

    private var cartItemsSection: some View {
        VStack(spacing: 0) {
            ForEach(cart.products.filter {
                cart.quantities[$0.id, default: 0] > 0
            }) { product in
                HStack(spacing: 12) {
                    Image(systemName: product.image)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 55, height: 55)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(product.name)
                            .font(.subheadline.bold())

                        Text("₹\(product.price, specifier: "%.2f") each")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            "₹\(product.price * Double(cart.quantities[product.id, default: 0]), specifier: "%.2f")"
                        )
                        .font(.subheadline.weight(.medium))
                    }

                    Spacer(minLength: 4)

                    Stepper(
                        value: Binding(
                            get: {
                                cart.quantities[product.id, default: 0]
                            },
                            set: { newValue in
                                cart.setQuantity(
                                    for: product,
                                    quantity: newValue
                                )
                            }
                        ),
                        in: 0...99
                    ) {
                        Text("\(cart.quantities[product.id, default: 0])")
                            .monospacedDigit()
                            .frame(minWidth: 20)
                    }
                    .fixedSize()
                }
                .padding(.vertical, 12)

                Divider()
            }
        }
    }

    private var couponSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coupon Code")
                .font(.headline)

            HStack {
                TextField("Enter code", text: Binding(
                    get: { cart.couponInput },
                    set: { cart.couponInput = $0 }
                ))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

                if cart.appliedCoupon != nil {
                    Button("Remove") {
                        cart.removeCoupon()
                    }
                    .foregroundStyle(.red)
                } else {
                    Button("Apply") {
                        cart.applyCoupon()
                    }
                    .fontWeight(.semibold)
                }
            }
            .padding(12)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )

            if let coupon = cart.appliedCoupon {
                Label("\(coupon) applied", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            if let error = cart.couponError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("SAVE10: 10% off  •  FLAT100: ₹100 off above ₹500")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private var priceSummary: some View {
        VStack(spacing: 12) {
            Text("Price Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            priceRow("Subtotal", value: cart.subtotal)
            priceRow("Discount", value: -cart.discount, color: .green)
            priceRow("GST (18%)", value: cart.gst)

            Divider()

            HStack {
                Text("Grand Total")
                    .font(.headline)

                Spacer()

                Text("₹\(cart.grandTotal, specifier: "%.2f")")
                    .font(.title3.bold())
            }
        }
        .padding()
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func priceRow(
        _ title: String,
        value: Double,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text("₹\(value, specifier: "%.2f")")
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 15) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 55))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("My Profile")
                                .font(.headline)

                            Text("Shopping App User")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    Label("Personal Information", systemImage: "person")
                    Label("My Addresses", systemImage: "location")
                    Label("My Orders", systemImage: "shippingbox")
                }

                Section("Support") {
                    Label("Help & Support", systemImage: "questionmark.circle")
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ShoppingCartView()
        .environment(CartManager())
}
