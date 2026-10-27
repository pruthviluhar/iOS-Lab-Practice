
import SwiftUI

struct StarRatingView: View {
    let rating: Int
    var onRatingChanged: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    onRatingChanged?(star)
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(
                            star <= rating ? .orange : .gray
                        )
                }
                .buttonStyle(.plain)
                .disabled(onRatingChanged == nil)
                .accessibilityLabel("\(star) stars")
            }
        }
    }
}

#Preview {
    StarRatingView(rating: 3)
        .padding()
}
