import SwiftUI

struct ObjectDetectedView: View {
    @Environment(\.dismiss) var dismiss
    let historyItem: HistoryItem
    let localImage: UIImage?
    @State private var showDeleteConfirm = false

    init(historyItem: HistoryItem, localImage: UIImage? = nil) {
        self.historyItem = historyItem
        self.localImage = localImage
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(12)
                        }
                        Spacer()
                    }
                    VStack(spacing: 2) {
                        Text("Diagnosis Result")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text("AI-assisted preliminary scalp assessment")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 56)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                // ── Scrollable Content ──────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Medical Disclaimer & Citations (TOP PRIORITY) ──
                        MedicalDisclaimerFooter()
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                        
                        Color.black.opacity(0.5)
                            .frame(height: 1)
                            .padding(.horizontal, 20)

                        // ── Scalp Image (FORCE LOAD) ────────────────
                        HStack {
                            Spacer()
                            ZStack {
                                Color.lightGreen
                                
                                if let local = localImage {
                                    // FORCE DISPLAY memory image
                                    Image(uiImage: local)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let stored = StorageManager.shared.loadImage(fileName: historyItem.imageUri.components(separatedBy: "/").last ?? historyItem.imageUri) {
                                    // FORCE DISPLAY local file
                                    Image(uiImage: stored)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let url = historyItem.imageUrl {
                                    // Fallback to Server
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .padding(40)
                                }
                            }
                            .frame(width: 250, height: 250)
                            .cornerRadius(12)
                            .clipped()
                            Spacer()
                        }
                        .padding(.vertical, 24)

                        // ── Primary Results Table ────────────────────
                        VStack(alignment: .leading, spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scalp Condition:")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Text("Scalp Condition : \(historyItem.condition)")
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(Color.brandPink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            
                            Divider().padding(.horizontal, 20)
                            
                            ResultMetricRow(label: "Hair Density:", value: "Density : \(historyItem.density)")
                            Divider().padding(.horizontal, 20)
                            
                            ResultMetricRow(label: "Miniaturized Ratio:", value: "Miniaturized Hair Ratio : \(historyItem.displayRatio)")
                            Divider().padding(.horizontal, 20)
                            
                            ResultMetricRow(label: "Vellus Hair Percentage:", value: "\(historyItem.vellusPercentage)")
                            Divider().padding(.horizontal, 20)
                            
                            ResultMetricRow(label: "Detailed Condition:", value: "Scalp Condition : \(historyItem.condition)")
                            Divider().padding(.horizontal, 20)
                        }

                        // ── Observation ──────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Observation:")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.top, 16)

                            Text(historyItem.observation)
                                .font(.system(size: 15))
                                .foregroundColor(.black.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // ── Patient Information Table ─────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            Text("PATIENT DETAILS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.top, 10)

                            DetailItem(label: "Name", value: historyItem.patientName ?? "N/A")
                            DetailItem(label: "Age", value: historyItem.patientAge ?? "N/A")
                            DetailItem(label: "Gender", value: historyItem.patientGender ?? "N/A")
                            DetailItem(label: "Family History", value: historyItem.patientFamilyHistory ?? "N/A")
                            
                            Divider()
                            
                            DetailItem(label: "Duration of hair loss", value: historyItem.patientDuration ?? "N/A")
                            DetailItem(label: "Treatment History", value: historyItem.patientTreatmentHistory ?? "N/A")
                            DetailItem(label: "Doctor's Comment", value: historyItem.doctorComments ?? "N/A")

                            if let signs = historyItem.patientSignsPresent, !signs.isEmpty {
                                Divider()
                                DetailItem(label: "Signs Present", value: signs)
                            }
                        }
                        .padding(20)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 20)


                        // ── Action Buttons ─────────────────────────────
                        VStack(spacing: 12) {
                            Button(action: { dismiss() }) {
                                Text("Save")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(Color.brandPink.opacity(0.80))
                                    .cornerRadius(30)
                                    .shadow(color: Color.brandPink.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: { 
                                self.showDeleteConfirm = true 
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .cornerRadius(30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.black, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Are you sure you want to delete this diagnosis?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                // v9.5: Delete locally AND from server
                NetworkManager.shared.deleteHistoryItem(id: historyItem.id) { _ in }
                StorageManager.shared.deleteHistory(item: historyItem)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct ResultMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.black)
            Spacer()
        }
    }
}
