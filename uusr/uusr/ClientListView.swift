import SwiftUI
import FirebaseFirestore

struct ClientListView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var clients: [User] = []
    @State private var searchText: String = ""
    @State private var selectedSortOption: SortOption = .firstName

    enum SortOption {
        case firstName, lastName, unitNumber
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Title
                Text("Client List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                // 🔥 Sign Out Button (Now in .toolbar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("Signing out. Setting isLoggedIn to false.")
                            userViewModel.isLoggedIn = false // Sign out
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }

                // Search Field
                TextField("Search by name or address", text: $searchText)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // Sort Options
                HStack {
                    Text("Sort by:")
                        .font(.subheadline)
                    Picker("Sort Option", selection: $selectedSortOption) {
                        Text("First Name").tag(SortOption.firstName)
                        Text("Last Name").tag(SortOption.lastName)
                        Text("Unit Number").tag(SortOption.unitNumber)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: selectedSortOption) { _ in
                        sortClients()
                    }
                }
                .padding(.top, 10)

                // Client List
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredAndSortedClients, id: \.id) { client in
                            NavigationLink(destination: PersonalDetailView(user: client)) {
                                ClientRowView(user: client)
                            }
                        }
                    }
                    .padding([.leading, .trailing])
                }
                Spacer()
            }
            .padding(.top, 20)
            .onAppear {
                fetchClients()
            }
        }
    }

    // Fetch all clients from Firestore
    func fetchClients() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("❌ Error fetching clients: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("❌ No client documents found.")
                return
            }

            self.clients = documents.compactMap { document in
                let data = document.data()
                let userId = document.documentID // ✅ Firestore Document ID

                print("✅ Fetched Firestore User ID: \(userId)") // Debugging

                let statusData = data["status"] as? [String: Bool] ?? [:]

                return User(
                    firestoreDocumentID: userId, // ✅ Assign Firestore ID
                    email: data["email"] as? String ?? "",
                    password: data["password"] as? String ?? "",
                    role: (data["role"] as? String == "manager") ? .manager : .individual,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    unitNumber: data["unitNumber"] as? String,
                    buildingName: data["buildingName"] as? String,
                    statusDictionary: statusData
                )
            }
            sortClients()
            print("✅ Fetched \(self.clients.count) clients.")
        }
    }

    // Sorting clients explicitly
    func sortClients() {
        clients.sort {
            switch selectedSortOption {
            case .firstName:
                return $0.firstName < $1.firstName
            case .lastName:
                return $0.lastName < $1.lastName
            case .unitNumber:
                return ($0.unitNumber ?? "") < ($1.unitNumber ?? "")
            }
        }
    }

    // Computed property to filter clients
    var filteredAndSortedClients: [User] {
        let filteredClients = clients.filter { client in
            searchText.isEmpty ||
            client.firstName.contains(searchText) ||
            client.lastName.contains(searchText) ||
            (client.unitNumber?.contains(searchText) ?? false) ||
            (client.buildingName?.contains(searchText) ?? false)
        }
        return filteredClients
    }
}
