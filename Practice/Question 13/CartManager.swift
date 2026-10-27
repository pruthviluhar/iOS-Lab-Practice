
import Foundation
import Observation

@MainActor
@Observable
final class CartManager {

    var products: [Product] = []
    var quantities: [Int: Int] = [:]

    var couponInput = ""
    var appliedCoupon: String?
    var couponError: String?
    var productLoadError: String?

    var isLoadingProducts = false

    // MARK: - Cart Items

    var cartItems: [(product: Product, quantity: Int)] {
        products.compactMap { product in
            guard let quantity = quantities[product.id],
                  quantity > 0 else {
                return nil
            }

            return (product, quantity)
        }
    }

    var itemCount: Int {
        quantities.values.reduce(0, +)
    }

    var subtotal: Double {
        cartItems.reduce(0) { total, item in
            total + item.product.price * Double(item.quantity)
        }
    }

    // MARK: - Coupon

    var discount: Double {
        guard let appliedCoupon else { return 0 }

        switch appliedCoupon {
        case "SAVE10":
            return subtotal * 0.10

        case "FLAT100":
            return subtotal > 500 ? 100 : 0

        default:
            return 0
        }
    }

    var gst: Double {
        max(0, subtotal - discount) * 0.18
    }

    var grandTotal: Double {
        max(0, subtotal - discount) + gst
    }

    // MARK: - Load JSON

    func loadProducts() async {
        guard products.isEmpty, !isLoadingProducts else {
            return
        }

        isLoadingProducts = true
        productLoadError = nil

        defer {
            isLoadingProducts = false
        }

        do {
            guard let url = Bundle.main.url(
                forResource: "products",
                withExtension: "json"
            ) else {
                throw ProductLoadingError.fileNotFound
            }

            let data = try Data(contentsOf: url)
            products = try JSONDecoder().decode(
                [Product].self,
                from: data
            )
        } catch {
            productLoadError =
                "Unable to load products.json. Check the file and Target Membership."
        }
    }

    // MARK: - Quantity

    func addToCart(_ product: Product) {
        quantities[product.id, default: 0] += 1
        clearCoupon()
    }

    func setQuantity(for product: Product, quantity: Int) {
        if quantity <= 0 {
            quantities.removeValue(forKey: product.id)
        } else {
            quantities[product.id] = quantity
        }

        clearCoupon()
    }

    // MARK: - Apply Coupon

    func applyCoupon() {
        let code = couponInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !code.isEmpty else {
            appliedCoupon = nil
            couponError = "Please enter a coupon code."
            return
        }

        switch code {
        case "SAVE10":
            appliedCoupon = code
            couponError = nil

        case "FLAT100":
            if subtotal > 500 {
                appliedCoupon = code
                couponError = nil
            } else {
                appliedCoupon = nil
                couponError = "FLAT100 requires an order above ₹500."
            }

        default:
            appliedCoupon = nil
            couponError = "Invalid coupon code."
        }
    }

    func removeCoupon() {
        appliedCoupon = nil
        couponInput = ""
        couponError = nil
    }

    private func clearCoupon() {
        guard let appliedCoupon else { return }

        if appliedCoupon == "FLAT100" && subtotal <= 500 {
            self.appliedCoupon = nil
            couponError = "FLAT100 requires an order above ₹500."
        }
    }
}

private enum ProductLoadingError: Error {
    case fileNotFound
}
