import SwiftUI

// Global variable to hold the document ID
var currentUserDocumentID: String?

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
                HStack {
                    Text("Client List")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)

                    Spacer()

                    // Sign Out Button
                    Button(action: {
                        print("Signing out. Setting isLoggedIn to false.")
                        userViewModel.isLoggedIn = false // Set isLoggedIn to false to log out
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal)

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

    // Fetch all clients from Firestore using FireBaseServer
    func fetchClients() {
        FireBaseServer.shared.fetchClients { (fetchedClients, error) in
            if let error = error {
                print("Error fetching clients: \(error)")
                return
            }
            self.clients = fetchedClients ?? []
            sortClients()
            print("Fetched \(self.clients.count) clients.")
        }
    }

    // Sorting clients explicitly
    func sortClients() {
        clients.sort {
            switch selectedSortOption {
            case .firstName:
                return $0.firstName.localizedCaseInsensitiveCompare($1.firstName) == .orderedAscending
            case .lastName:
                return $0.lastName.localizedCaseInsensitiveCompare($1.lastName) == .orderedAscending
            case .unitNumber:
                return ($0.unitNumber ?? "").localizedCaseInsensitiveCompare($1.unitNumber ?? "") == .orderedAscending
            }
        }
    }

    // Computed property to filter clients
    var filteredAndSortedClients: [User] {
        let filteredClients = clients.filter { client in
            searchText.isEmpty ||
            client.firstName.localizedCaseInsensitiveContains(searchText) ||
            client.lastName.localizedCaseInsensitiveContains(searchText) ||
            (client.unitNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (client.buildingName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        return filteredClients
    }
}

struct ClientRowView: View {
    @ObservedObject var user: User
    @State private var showStatusOptions: Bool = false

    var body: some View {
        VStack {
            HStack {
                // Profile Image
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(user.firstName.prefix(1)))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    )
                
                // User Details
                VStack(alignment: .leading) {
                    Text("\(user.firstName) \(user.lastName)")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let unitNumber = user.unitNumber, let buildingName = user.buildingName {
                        Text("Address: \(unitNumber), \(buildingName)")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    
                    // Display User ID
                    Text("User ID: \(currentUserDocumentID ?? "N/A")")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Status Button
                Button(action: {
                    print("Status button clicked for User ID: \(currentUserDocumentID ?? "N/A")")
                    showStatusOptions.toggle()
                }) {
                    Text("Status")
                        .foregroundColor(.blue)
                        .padding(5)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }
            .padding()

            // Status Options
            if showStatusOptions {
                VStack {
                    ForEach(Status.allCases, id: \.self) { status in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { user.statusDictionary[status.rawValue] ?? false },
                                set: { isSelected in
                                    updateStatus(isSelected: isSelected, status: status, for: user)
                                }
                            )) {
                                Text(status.rawValue.capitalized)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // Method to handle status updates
    func updateStatus(isSelected: Bool, status: Status, for user: User) {
        user.statusDictionary[status.rawValue] = isSelected

        // Save status locally
        saveStatusLocally(for: user)

        // Push the updated status to Firestore using FireBaseServer
        FireBaseServer.shared.updateStatus(for: currentUserDocumentID ?? "", status: user.statusDictionary) { error in
            if let error = error {
                print("Error updating status: \(error)")
            } else {
                print("Status successfully updated for user: \(currentUserDocumentID ?? "N/A")")
            }
        }
    }

    func saveStatusLocally(for user: User) {
        UserDefaults.standard.set(user.statusDictionary, forKey: "status_\(currentUserDocumentID ?? "N/A")")
    }
}
