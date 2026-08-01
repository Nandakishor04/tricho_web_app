import SwiftUI

struct HistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var navigateToObjectDetected = false
    
    @State private var historyItems: [HistoryItem] = []
    @State private var selectedItem: HistoryItem? = nil
    
    var filteredItems: [HistoryItem] {
        if searchText.isEmpty {
            return historyItems
        } else {
            let query = searchText.lowercased()
            return historyItems.filter {
                $0.condition.lowercased().contains(query) ||
                ($0.patientName?.lowercased().contains(query) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            ZStack {
                HStack {
                    BackButton()
                    Spacer()
                }
                
                Text("History")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 24)
            .frame(height: 60)
            .background(Color.white)
            
            ZStack {
                Color.brandPink.opacity(0.20).ignoresSafeArea() // Pink shade as requested
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search history...", text: $searchText)
                            .font(.system(size: 18))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.borderBright, lineWidth: 0.6)
                    )
                    .padding(16)
                    
                    // Content List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                Button(action: {
                                    selectedItem = item
                                    navigateToObjectDetected = true
                                }) {
                                    HStack(spacing: 16) {
                                        if let localImg = StorageManager.shared.loadImage(fileName: item.imageUri.components(separatedBy: "/").last ?? item.imageUri) {
                                            Image(uiImage: localImg)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        } else if let imageUrl = item.imageUrl {
                                            AsyncImage(url: imageUrl) { image in
                                                image.resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.1)
                                            }
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .foregroundColor(.gray.opacity(0.3))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Scalp Analysis")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.black)
                                            
                                            
                                            Text(item.condition)
                                                .font(.system(size: 14))
                                                .foregroundColor(.brandPink.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.borderBright, lineWidth: 0.6)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
            
        }
        .onAppear {
            loadHistory()
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToObjectDetected) {
            if let item = selectedItem {
                ObjectDetectedView(historyItem: item)
            }
        }
    }
    
    private func loadHistory() {
        // Cleanup old items without images
        StorageManager.shared.cleanupLegacyHistory()
        
        // Load local history first
        historyItems = StorageManager.shared.getHistory()
        
        // Then sync with server
        NetworkManager.shared.fetchHistory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let serverItems):
                    var localItems = StorageManager.shared.getHistory()
                    var wasUpdated = false
                    
                    for sItem in serverItems {
                        if let index = localItems.firstIndex(where: { $0.id == sItem.id || ($0.timestamp == sItem.timestamp && $0.imageUri == sItem.imageUri) }) {
                            // Update existing item with server data (which might have more fields)
                            localItems[index] = sItem
                            wasUpdated = true
                        } else {
                            // New item
                            localItems.append(sItem)
                            wasUpdated = true
                        }
                    }
                    
                    if wasUpdated {
                        localItems.sort { $0.timestamp > $1.timestamp }
                        StorageManager.shared.syncHistoryList(localItems)
                    }
                    historyItems = StorageManager.shared.getHistory()
                case .failure:
                    // Fallback already happened (loaded local history)
                    break
                }
            }
        }
    }
}

// Removed local HistoryItem struct as it is now in Models.swift

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
