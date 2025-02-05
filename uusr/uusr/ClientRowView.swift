import SwiftUI

struct ClientRowView: View {
    @ObservedObject var user: User

    var body: some View {
        VStack {
            HStack {
                
                if user.photo != nil {
                    Image(uiImage: user.photo!)
                        .resizable()
                        .frame(width: 50, height: 50)
                }else{
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(user.firstName.prefix(1)))
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        )
                }

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

                    // **Status Display**
                    Text("Status: \(getStatusText())")
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .bold()
                }

                Spacer()
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // Helper function to get formatted status text
    func getStatusText() -> String {
        let activeStatuses = user.statusDictionary.filter { $0.value }.keys
        return activeStatuses.isEmpty ? "None" : activeStatuses.joined(separator: ", ")
    }
}
