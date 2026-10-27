
import SwiftUI

struct QuizView: View {

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var score = 0

    @State private var displayedOptions: [QuizOption] = []
    @State private var selectedOptionID: UUID?
    @State private var showResults = false
    @State private var errorMessage = ""

    private var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else {
            return nil
        }
        return questions[currentIndex]
    }

    private var percentage: Int {
        guard !questions.isEmpty else { return 0 }
        return Int((Double(score) / Double(questions.count) * 100).rounded())
    }

    private var grade: String {
        switch percentage {
        case 90...100: return "A"
        case 70..<90: return "B"
        case 50..<70: return "C"
        default: return "Fail"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)

                        Text(errorMessage)
                            .multilineTextAlignment(.center)

                        Button("Try Again") {
                            startQuiz()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()

                } else if showResults {
                    resultsView

                } else if let question = currentQuestion {
                    quizContent(question)

                } else {
                    ProgressView("Loading quiz...")
                }
            }
            .navigationTitle("SwiftUI Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if questions.isEmpty && errorMessage.isEmpty {
                    startQuiz()
                }
            }
        }
    }

    // MARK: - Quiz Screen

    private func quizContent(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 24) {

            HStack {
                Text("Question \(currentIndex + 1)/\(questions.count)")
                    .font(.headline)

                Spacer()

                Text("Score: \(score)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(currentIndex + 1),
                total: Double(max(questions.count, 1))
            )
            .tint(.blue)

            Text(question.question)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(displayedOptions) { option in
                    Button {
                        selectOption(option)
                    } label: {
                        HStack {
                            Text(option.text)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            if selectedOptionID != nil && option.isCorrect {
                                Image(systemName: "checkmark.circle.fill")
                            } else if selectedOptionID == option.id {
                                Image(systemName: "xmark.circle.fill")
                            }
                        }
                        .font(.body.weight(.medium))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(optionForeground(for: option))
                        .background(
                            optionBackground(for: option),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedOptionID != nil)
                }
            }

            Spacer()

            if selectedOptionID != nil {
                Button {
                    goToNextQuestion()
                } label: {
                    Text(
                        currentIndex == questions.count - 1
                            ? "See Results"
                            : "Next Question"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }

    // MARK: - Answer Selection

    private func selectOption(_ option: QuizOption) {
        guard selectedOptionID == nil else { return }

        selectedOptionID = option.id

        if option.isCorrect {
            score += 1
        }
    }

    private func optionBackground(for option: QuizOption) -> Color {
        guard selectedOptionID != nil else {
            return Color.gray.opacity(0.12)
        }

        if option.isCorrect {
            return Color.green.opacity(0.2)
        }

        if option.id == selectedOptionID {
            return Color.red.opacity(0.2)
        }

        return Color.gray.opacity(0.12)
    }

    private func optionForeground(for option: QuizOption) -> Color {
        guard selectedOptionID != nil else {
            return .primary
        }

        if option.isCorrect {
            return .green
        }

        if option.id == selectedOptionID {
            return .red
        }

        return .primary
    }

    // MARK: - Next Question

    private func goToNextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            prepareOptions()
        } else {
            showResults = true
        }
    }

    // MARK: - Load and Shuffle JSON

    private func startQuiz() {
        errorMessage = ""

        guard let url = Bundle.main.url(
            forResource: "quizData",
            withExtension: "json"
        ) else {
            errorMessage = """
            quizData.json was not found.
            Check that the file is included in your app target.
            """
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedQuestions = try JSONDecoder().decode(
                [QuizQuestion].self,
                from: data
            )

            guard !decodedQuestions.isEmpty else {
                errorMessage = "No quiz questions were found."
                return
            }

            for question in decodedQuestions {
                guard question.options.indices.contains(
                    question.answerIndex
                ) else {
                    errorMessage = "A question has an invalid answer index."
                    return
                }
            }

            questions = decodedQuestions.shuffled()
            currentIndex = 0
            score = 0
            showResults = false
            prepareOptions()

        } catch {
            errorMessage = "Could not load quiz: \(error.localizedDescription)"
        }
    }

    // Shuffle options while preserving the correct answer
    private func prepareOptions() {
        guard let question = currentQuestion else { return }

        displayedOptions = question.options.enumerated().map {
            index, text in

            QuizOption(
                text: text,
                isCorrect: index == question.answerIndex
            )
        }.shuffled()

        selectedOptionID = nil
    }

    // MARK: - Results Screen

    private var resultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 65))
                .foregroundStyle(.orange)

            Text("Quiz Completed!")
                .font(.largeTitle.bold())

            Text("\(score) / \(questions.count)")
                .font(.system(size: 40, weight: .bold))

            Text("Percentage: \(percentage)%")
                .font(.title3)

            Text("Grade: \(grade)")
                .font(.title.bold())
                .foregroundStyle(
                    grade == "Fail" ? .red : .green
                )

            Button {
                startQuiz()
            } label: {
                Label("Restart Quiz", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.top)
        }
        .padding(24)
    }
}

#Preview {
    QuizView()
}
