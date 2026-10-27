
import SwiftUI

struct DestinationCardView: View {
    let destination: Destination
    let onDecision: (Bool) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isExiting = false

    private let threshold: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                VStack(spacing: 0) {
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.cyan.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Text(destination.emoji)
                            .font(.system(size: 100))
                    }
                    .frame(height: geometry.size.height * 0.55)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 24,
                            topTrailingRadius: 24
                        )
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(destination.name)
                            .font(.largeTitle.bold())

                        Text(destination.country)
                            .font(.title3)
                            .foregroundStyle(.secondary)

                        Text(destination.description)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }

                HStack {
                    Text("LIKE")
                        .foregroundStyle(.green)
                        .rotationEffect(.degrees(-15))
                        .opacity(dragOffset.width > 0
                                 ? min(abs(dragOffset.width) / threshold, 1)
                                 : 0)

                    Spacer()

                    Text("NOPE")
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(15))
                        .opacity(dragOffset.width < 0
                                 ? min(abs(dragOffset.width) / threshold, 1)
                                 : 0)
                }
                .font(.system(size: 30, weight: .heavy))
                .padding(24)
                .padding(.top, 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(dragOffset)
            .rotationEffect(
                .degrees(Double(dragOffset.width / 20))
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !isExiting else { return }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        guard !isExiting else { return }

                        if value.translation.width > threshold {
                            finishSwipe(like: true, width: geometry.size.width)
                        } else if value.translation.width < -threshold {
                            finishSwipe(like: false, width: geometry.size.width)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
    }

    private func finishSwipe(like: Bool, width: CGFloat) {
        guard !isExiting else { return }
        isExiting = true

        let direction: CGFloat = like ? 1 : -1

        withAnimation(.easeIn(duration: 0.22)) {
            dragOffset = CGSize(
                width: direction * (width + 300),
                height: 80
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
            onDecision(like)
            dragOffset = .zero
            isExiting = false
        }
    }
}
