import SwiftUI
import UserNotifications
import FirebaseFirestore
import WebKit

struct TaskView: View {
    @ObservedObject var user: User
    @State private var tasks: [(String, String, Date, [String], Bool, String?)] = []
    @State private var newTask: String = ""
    @State private var selectedTaskType: String = "Med Reminders"
    @State private var selectedDate = Date()
    @State private var repeatDays: [String] = []
    @State private var isRecurring: Bool = false

    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack {
                Text("Tasks for \(user.firstName) \(user.lastName)")
                    .font(.title)
                    .padding()

                // List of Tasks
                ForEach(tasks.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("**[\(tasks[index].0)]** \(tasks[index].1)")
                            .foregroundColor(.primary)

                        if tasks[index].4 {
                            Text("Reminder: **DISABLED**")
                                .foregroundColor(.red)
                                .font(.footnote)
                        } else {
                            Text("Reminder: \(formattedDate(tasks[index].2))")
                                .foregroundColor(.gray)
                                .font(.footnote)
                        }

                        if !tasks[index].3.isEmpty {
                            Text("Repeats: \(tasks[index].3.joined(separator: ", "))")
                                .foregroundColor(.blue)
                                .font(.footnote)
                        }

                        HStack {
                            Button(action: { tasks[index].4.toggle() }) {
                                Text(tasks[index].4 ? "Enable" : "Disable")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(tasks[index].4 ? Color.green : Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                if let docID = tasks[index].5 {
                                    deleteTaskFromFirestore(docID)
                                }
                                removeNotification(for: tasks[index].1)
                                tasks.remove(at: index)
                            }) {
                                Text("Delete")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }

                // Add New Task Section
                VStack {
                    Picker("Select Task Type", selection: $selectedTaskType) {
                        ForEach(["Med Reminders", "Vitals Check", "House Keeping", "Exercise", "Appointments"], id: \.self) { taskType in
                            Text(taskType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)

                    TextField("Enter new task", text: $newTask)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 5)

                    DatePicker("Set Reminder Time", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(.vertical, 5)

                    Toggle("Repeat Weekly", isOn: $isRecurring)
                        .padding(.vertical, 5)

                    Button(action: {
                        if !newTask.isEmpty {
                            saveTaskToFirestore()
                            scheduleNotification(taskName: newTask, taskDate: selectedDate, repeatDays: repeatDays)
                        }
                    }) {
                        Text("Add Task")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                // 🎥 YouTube Video Section
                VStack {
                    Text("Watch Video Tutorial")
                        .font(.headline)
                        .padding(.top)

                    YouTubePlayerView(videoID: "L0R9rbg_AYo")
                        .frame(height: 250)
                        .cornerRadius(8)
                        .padding()

                    Button(action: {
                        openYouTubeLink("https://www.youtube.com/watch?v=L0R9rbg_AYo")
                    }) {
                        Text("Open in YouTube")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            requestNotificationPermission()
            fetchTasksFromFirestore()
        }
        .navigationBarTitle("Tasks", displayMode: .inline)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter.string(from: date)
    }

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }

    func scheduleNotification(taskName: String, taskDate: Date, repeatDays: [String]) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = taskName
        content.sound = .default

        if repeatDays.isEmpty {
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: taskDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: taskName, content: content, trigger: trigger)
            center.add(request)
        } else {
            for day in repeatDays {
                let weekday = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].firstIndex(of: day)! + 1
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: taskDate)
                dateComponents.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(taskName)_\(day)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    func removeNotification(for taskName: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [taskName])
    }

    func saveTaskToFirestore() {
        guard !user.firestoreDocumentID.isEmpty else {
            print("Error: User does not have a valid Firestore document ID")
            return
        }

        let taskData: [String: Any] = [
            "type": selectedTaskType,
            "description": newTask,
            "date": selectedDate,
            "repeatDays": repeatDays,
            "isActive": true,
            "userID": user.firestoreDocumentID
        ]

        db.collection("tasks").addDocument(data: taskData) { error in
            if let error = error {
                print("Error saving task: \(error.localizedDescription)")
            } else {
                fetchTasksFromFirestore()
            }
        }
    }

    func fetchTasksFromFirestore() {
        db.collection("tasks")
            .whereField("userID", isEqualTo: user.firestoreDocumentID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching tasks: \(error.localizedDescription)")
                } else {
                    self.tasks = snapshot?.documents.compactMap { document in
                        let data = document.data()
                        return (
                            data["type"] as? String ?? "",
                            data["description"] as? String ?? "",
                            (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                            data["repeatDays"] as? [String] ?? [],
                            !(data["isActive"] as? Bool ?? true),
                            document.documentID
                        )
                    } ?? []
                }
            }
    }
    
    func deleteTaskFromFirestore(_ documentID: String) {
        db.collection("tasks").document(documentID).delete { error in
            if let error = error {
                print("Error deleting task: \(error.localizedDescription)")
            } else {
                print("Task deleted successfully!")
            }
        }
    }

    func openYouTubeLink(_ link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
