
import SwiftUI

struct TaskListView: View {

    @AppStorage("savedTasksJSON")
    private var savedTasksJSON = "[]"

    @State private var tasks: [TaskItem] = []
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedSort: TaskSort = .manual
    @State private var showingAddTask = false

    enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"

        var id: String { rawValue }
    }

    enum TaskSort: String, CaseIterable, Identifiable {
        case manual = "Default Order"
        case priority = "Priority"
        case date = "Date"

        var id: String { rawValue }
    }

    // Filter tasks
    var filteredTasks: [TaskItem] {
        switch selectedFilter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }

    // Sort tasks
    var displayedTasks: [TaskItem] {
        switch selectedSort {
        case .manual:
            return filteredTasks

        case .priority:
            let rank: [Priority: Int] = [
                .high: 0,
                .medium: 1,
                .low: 2
            ]

            return filteredTasks.sorted {
                rank[$0.priority, default: 3]
                    < rank[$1.priority, default: 3]
            }

        case .date:
            return filteredTasks.sorted {
                $0.createdAt > $1.createdAt
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases) { filter in
                        Text(filter.rawValue)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(displayedTasks) { task in
                        HStack(spacing: 12) {
                            Image(
                                systemName: task.isCompleted
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundStyle(
                                task.isCompleted ? .green : .secondary
                            )

                            VStack(alignment: .leading, spacing: 5) {
                                Text(task.title)
                                    .strikethrough(task.isCompleted)
                                    .foregroundStyle(
                                        task.isCompleted
                                            ? .secondary
                                            : .primary
                                    )

                                HStack(spacing: 8) {
                                    Text(task.priority.title + " Priority")
                                        .font(.caption)
                                        .foregroundStyle(
                                            priorityColor(task.priority)
                                        )

                                    Text(task.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleTask(task)
                        }
                    }
                    .onDelete(perform: deleteTasks)
                    .onMove(perform: moveTasks)
                }
                .listStyle(.plain)
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(TaskSort.allCases) { sort in
                            Button {
                                selectedSort = sort
                            } label: {
                                if selectedSort == sort {
                                    Label(
                                        sort.rawValue,
                                        systemImage: "checkmark"
                                    )
                                } else {
                                    Text(sort.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView { title, priority in
                    let newTask = TaskItem(
                        title: title,
                        priority: priority
                    )
                    tasks.append(newTask)
                    saveTasks()
                }
            }
            .onAppear {
                loadTasks()
            }
            .onChange(of: tasks) {
                saveTasks()
            }
        }
    }

    // Toggle completion
    private func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(
            where: { $0.id == task.id }
        ) else {
            return
        }

        tasks[index].isCompleted.toggle()
    }

    // Delete selected tasks
    private func deleteTasks(at offsets: IndexSet) {
        let idsToDelete = offsets.map { displayedTasks[$0].id }

        tasks.removeAll { idsToDelete.contains($0.id) }
    }

    // Reorder tasks in default order
    private func moveTasks(
        from source: IndexSet,
        to destination: Int
    ) {
        guard selectedSort == .manual,
              selectedFilter == .all else {
            return
        }

        tasks.move(fromOffsets: source, toOffset: destination)
    }

    // Priority color
    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }

    // Save tasks as JSON in AppStorage
    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            savedTasksJSON = String(
                decoding: data,
                as: UTF8.self
            )
        } catch {
            print("Unable to save tasks: \(error)")
        }
    }

    // Restore saved tasks
    private func loadTasks() {
        guard let data = savedTasksJSON.data(using: .utf8) else {
            return
        }

        do {
            tasks = try JSONDecoder().decode(
                [TaskItem].self,
                from: data
            )
        } catch {
            print("Unable to load tasks: \(error)")
        }
    }
}

// Add Task Sheet
struct AddTaskView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var priority: Priority = .medium

    let onSave: (String, Priority) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)

                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanTitle = title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )

                        guard !cleanTitle.isEmpty else {
                            return
                        }

                        onSave(cleanTitle, priority)
                        dismiss()
                    }
                    .disabled(
                        title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }
}

#Preview {
    TaskListView()
}
