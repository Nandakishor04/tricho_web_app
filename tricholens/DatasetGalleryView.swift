import SwiftUI

struct DatasetImage: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let path: String
    
    enum CodingKeys: String, CodingKey {
        case name, category, path
    }
}

struct DatasetGalleryView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    @Binding var selectedCategory: String?
    
    @State private var datasets: [DatasetImage] = []
    @State private var searchText = ""
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var filteredDatasets: [DatasetImage] {
        if searchText.isEmpty {
            return datasets
        } else {
            return datasets.filter { $0.category.lowercased().contains(searchText.lowercased()) || $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                
                Text("Gallery")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 24)
            .frame(height: 70)
            .background(Color.white)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search category (AGA, normal...)", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .padding(.bottom, 10)
            
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredDatasets) { item in
                            Button(action: {
                                if let img = UIImage(contentsOfFile: item.path) {
                                    selectedImage = img
                                    selectedCategory = item.category
                                    dismiss()
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let img = UIImage(contentsOfFile: item.path) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: (UIScreen.main.bounds.width - 72) / 3, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                        } else {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 100)
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(item.category)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.brandPinkDark)
                                            .cornerRadius(5)
                                            .padding(6)
                                    }
                                }
                                .padding(4)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            loadDataset()
        }
        .navigationBarHidden(true)
    }
    
    private func loadDataset() {
        guard let path = Bundle.main.path(forResource: "dataset", ofType: "json") ?? 
                Optional("/Users/sail/Downloads/Tricholens_Project 2/tricholens/tricholens/dataset.json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoded = try JSONDecoder().decode([DatasetImage].self, from: data)
            self.datasets = decoded
        } catch {
            print("Error loading dataset: \(error)")
        }
    }
}

struct DatasetGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        DatasetGalleryView(selectedImage: .constant(nil), selectedCategory: .constant(nil))
    }
}
