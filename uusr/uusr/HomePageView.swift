//
//  HomePage.swift
//  uusr
//  Created by Jianming Chen on 2024-11-05.
//
import SwiftUI

struct HomePageView: View {
    @State private var searchText: String = ""
    @State private var sortAscending: Bool = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Home Page")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                    .padding(.leading)
                
                // Search bar
                TextField("Search", text: $searchText)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding([.leading, .trailing])

                // Sort button (placeholder action)
                HStack {
                    Text("Sort")
                        .font(.subheadline)
                    Button(action: {
                        sortAscending.toggle()
                    }) {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                            .foregroundColor(.blue)
                    }
                }
                .padding([.leading, .trailing])
                
                // Placeholder content
                ScrollView {
                    VStack(spacing: 10) {
                        Text("No data available")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding()
                    }
                    .padding([.leading, .trailing])
                }
            }
            .navigationBarHidden(true)
            .padding()
        }
    }
}

struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}
