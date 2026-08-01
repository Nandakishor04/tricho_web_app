import SwiftUI

struct DiagnoseView: View {
    @State private var navigateToObjectDetected = false
    @State private var isLoading = false
    @State private var diagnosisResult: HistoryItem? = nil
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    @State private var selectedCategory: String? = nil
    @State private var patientName = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var hasFamilyHistory = false
    @State private var familyHistoryComments = ""
    @State private var duration = ""
    @State private var treatmentHistory = ""
    @State private var doctorComments = ""
    @State private var showDatasetGallery = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background Layer
            ZStack {
                Color(hex: "FFF0F5").ignoresSafeArea() // Soft Lavender Pink
                Color.brandPink.opacity(0.08).ignoresSafeArea()
            }
            
            // Scrollable Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) { 
                    // Header (Restored Classic Style)
                    HStack(spacing: 10) {
                        BackButton(useChevron: false, size: 26)
                        
                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 0.5)
                            )
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("New Diagnosis")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                            
                            Text("Enter details and select image")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.black.opacity(0.45))
                        }
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 18) {
                        Text("PATIENT INFORMATION")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.brandPinkDark)
                            .padding(.bottom, 2)
                        
                        // Name
                        CustomInputField(label: "Patient Name", text: $patientName, placeholder: "Full Name")
                        
                        HStack(spacing: 16) {
                            // Age
                            CustomInputField(label: "Age", text: $age, placeholder: "Ex: 25")
                                .frame(width: 90)
                            
                            // Gender Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Gender")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                                
                                Picker("Gender", selection: $gender) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                    Text("Other").tag("Other")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal, 12)
                                .frame(height: 52)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 1.0) // Solid black border
                                )
                            }
                        }
                        
                        // Family History
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $hasFamilyHistory) {
                                Text("Family History of AGA?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black.opacity(0.8))
                            }
                            .tint(.brandPink)
                            
                            if hasFamilyHistory {
                                TextField("Specify (e.g., Maternal grandfather)", text: $familyHistoryComments)
                                    .font(.system(size: 14))
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.brandPink.opacity(0.2), lineWidth: 1))
                                    .transition(.opacity)
                            }
                        }
                        
                        // Duration
                        CustomInputField(label: "Duration of hair loss", text: $duration, placeholder: "Ex: 6 months")
                        
                        // Treatment History
                        CustomInputField(label: "Treatment History", text: $treatmentHistory, placeholder: "Ex: Minoxidil 5%, PRP therapy")
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
                    
                    // Scalp Image Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SCALP IMAGE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                        
                        if let image = selectedImage {
                            ZStack(alignment: .topLeading) {
                                // Constant frame container
                                Color.white // Light green background
                                    .frame(height: 480)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)

                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit) // v9.2: Fit within frame to avoid missing details
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 480)
                                    .cornerRadius(20)
                                    .clipped()
                                
                                Text(getCurrentTimestampForOverlay())
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.yellow.opacity(0.7))
                                    .padding(40)
                            }
                        } else {
                            ZStack(alignment: .bottom) {
                                Color.lightGreen
                                    .frame(height: 480)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)

                                Image("image")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit) // Constant vertical space
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 480)
                                    .cornerRadius(30)
                                    .clipped()

                                Text("Sample Image")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.45))
                                    .cornerRadius(20)
                                    .padding(.bottom, 16)
                            }
                        }
                    }
                    
                    if let debugImg = processedImagePreview {
                        VStack(spacing: 8) {
                            Text("PROCESSED MODEL INPUT (224x224):")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                            
                            Image(uiImage: debugImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .border(Color.red, width: 2)
                        }
                        .padding(.top, 4)
                    }
                    
                    VStack(spacing: 8) {
                        if selectedImage != nil {
                            Button(action: {
                                selectedImage = nil
                                selectedCategory = nil
                                showImagePicker = true
                            }) {
                                Text("SELECT AGAIN")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.black.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "D9D9D9"))
                                    .cornerRadius(15)
                            }
                            
                            Button(action: {
                                diagnose()
                            }) {
                                Text(isLoading ? "ANALYZING..." : "DIAGNOSE NOW")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.brandPink)
                                    .cornerRadius(15)
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.6 : 1.0)
                        } else {
                            Button(action: {
                                selectedCategory = nil
                                showImagePicker = true
                            }) {
                                Text("SELECT IMAGE")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.brandPink)
                                    .cornerRadius(15)
                            }
                        }
                        
                        Text("⚠️ Disclaimer: Only clear scalp images should be added for a valid diagnosis.")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.brandPinkDark.opacity(0.8))
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    
                    // Doctor's Comments Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DOCTOR'S COMMENTS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.brandPinkDark)
                        
                        ZStack(alignment: .topLeading) {
                            if doctorComments.isEmpty {
                                Text("Enter clinical notes, recommendations, or follow-up instructions...")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                            }
                            TextEditor(text: $doctorComments)
                                .font(.system(size: 14))
                                .padding(10)
                                .frame(minHeight: 110)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.black, lineWidth: 1.0)
                        )
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ModernImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showDatasetGallery) {
            DatasetGalleryView(selectedImage: $selectedImage, selectedCategory: $selectedCategory)
        }
        .navigationDestination(isPresented: $navigateToObjectDetected) {
            if let result = diagnosisResult {
                ObjectDetectedView(historyItem: result, localImage: stableImageForResults)
            }
        }
        .alert("Analysis Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func getCurrentTimestampForOverlay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd/HH/mm/ss//HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    @State private var processedImagePreview: UIImage? = nil
    @State private var stableImageForResults: UIImage? = nil
    
    private func diagnose() {
        guard let image = selectedImage else { return }
        self.stableImageForResults = image // Lock the image in memory for the results page
        
        if let category = selectedCategory {
            mockLocalDiagnosis(category: category)
            return
        }
        
        let imageName = "diag_\(Int64(Date().timeIntervalSince1970)).jpg"
        let savedPath = StorageManager.shared.saveImage(image: image, fileName: imageName)
        
        isLoading = true
        let startTime = Date()
        NetworkManager.shared.diagnose(
            image: image,
            patientName: patientName,
            age: age,
            gender: gender,
            familyHistory: hasFamilyHistory ? (familyHistoryComments.isEmpty ? "Yes" : "Yes: \(familyHistoryComments)") : "No",
            duration: duration,
            treatmentHistory: treatmentHistory,
            doctorComments: doctorComments
        ) { result in
            // v9.3: Ensure the loading screen is visible for at least 3 seconds
            // This increases "analysis confidence" for the end-user.
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, 3.0 - elapsedTime)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                isLoading = false
                switch result {
                case .success(var newItem):
                    if let path = savedPath {
                        newItem = HistoryItem(
                            id: newItem.id,
                            imageUri: path,
                            density: newItem.density,
                            ratio: newItem.ratio,
                            condition: newItem.condition,
                            observation: newItem.observation,
                            timestamp: newItem.timestamp,
                            patientName: patientName,
                            patientAge: age,
                            patientGender: gender,
                            patientFamilyHistory: hasFamilyHistory ? (familyHistoryComments.isEmpty ? "Yes" : "Yes: \(familyHistoryComments)") : "No",
                            patientDuration: duration,
                            patientTreatmentHistory: treatmentHistory.isEmpty ? nil : treatmentHistory,
                            patientSignsPresent: newItem.patientSignsPresent,
                            doctorComments: doctorComments.isEmpty ? nil : doctorComments
                        )
                    }
                    
                    StorageManager.shared.saveHistory(item: newItem)
                    self.diagnosisResult = newItem
                    self.navigateToObjectDetected = true
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func mockLocalDiagnosis(category: String) {
        guard let image = selectedImage else { return }

        let imageName = "diag_mock_\(Int64(Date().timeIntervalSince1970)).jpg"
        let savedPath = StorageManager.shared.saveImage(image: image, fileName: imageName)

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false

            // ── Analyse actual image pixels for deterministic, medically meaningful metrics ──
            let metrics = ImageAnalyzer.analyze(image)
            print("📊 [MOCK ANALYZER] Density: \(metrics.density) | Vellus: \(metrics.vellusRatio) | Miniaturization: \(metrics.miniaturizationIndex)")

            let cat = category.lowercased()

            // Combine dataset category hint with image-derived profile
            let finalCondition: String
            let finalObservation: String

            if cat == "aga" || cat.contains("alopecia") {
                // Dataset label confirms AGA — use image metrics, force AGA condition
                finalCondition = "Androgenetic Alopecia – Active Follicular Miniaturisation"
                finalObservation = """
Analysis of trichoscopic image confirms signs of androgenetic alopecia. Hair follicle density is measured at \(metrics.density) with a vellus hair ratio of \(metrics.vellusRatio) and a miniaturisation index of \(metrics.miniaturizationIndex).

Trichoscopic Signs Present:
• Hair diameter diversity (anisotrichosis): Coexistence of thick terminal and thin vellus hairs (>20% variation in diameter)
• Miniaturised (vellus) hairs: Short, thin, non-pigmented hairs <30 µm diameter
• Single-hair follicular units: Normally 2–3 hairs per follicular unit; reduced to single hairs in AGA
• Peripilar sign: Brown halo around follicle opening due to perifollicular pigmentation

Consultation with a qualified trichologist or dermatologist is strongly recommended for a personalised treatment plan.
"""
            } else if cat == "normal" || cat.contains("healthy") {
                // Dataset label is healthy — use image metrics
                finalCondition = metrics.conditionName
                finalObservation = metrics.observation
            } else {
                // Unlabeled / unknown — rely entirely on ImageAnalyzer
                finalCondition = metrics.conditionName
                finalObservation = metrics.observation
            }

            let newItem = HistoryItem(
                imageUri: savedPath ?? "local_dataset",
                density: metrics.density,
                ratio: metrics.vellusRatio,
                condition: finalCondition,
                observation: finalObservation,
                patientName: patientName,
                patientAge: age,
                patientGender: gender,
                patientFamilyHistory: hasFamilyHistory ? (familyHistoryComments.isEmpty ? "Yes" : "Yes: \(familyHistoryComments)") : "No",
                patientDuration: duration,
                patientTreatmentHistory: treatmentHistory.isEmpty ? nil : treatmentHistory,
                doctorComments: doctorComments.isEmpty ? nil : doctorComments
            )

            StorageManager.shared.saveHistory(item: newItem)
            NetworkManager.shared.saveHistoryToServer(item: newItem) { result in
                switch result {
                case .success: print("✅ [HISTORY] SAVED TO SERVER")
                case .failure(let err): print("❌ [HISTORY] SERVER SAVE FAILED: \(err)")
                }
            }
            self.diagnosisResult = newItem
            self.navigateToObjectDetected = true
        }
    }
}

struct CustomInputField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding(.horizontal, 15)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.0) // Solid black border
                )
        }
    }
}

struct DiagnoseView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnoseView()
    }
}
