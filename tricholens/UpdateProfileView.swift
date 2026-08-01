import SwiftUI

struct UpdateProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var dob = ""
    @State private var gender = ""
    @State private var age = ""
    @State private var country = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var dobDate = Date()
    @State private var showDatePicker = false
    
    private var isNameValid: Bool {
        name.rangeOfCharacter(from: .letters) != nil
    }
    
    private var isMobileValid: Bool {
        let mobileRegex = "^[6-9]\\d{9}$"
        let mobilePredicate = NSPredicate(format:"SELF MATCHES %@", mobileRegex)
        return mobilePredicate.evaluate(with: mobile)
    }
    
    private var calculatedAge: Int {
        Calendar.current.dateComponents([.year], from: dobDate, to: Date()).year ?? 0
    }
    
    private var isAgeValid: Bool {
        calculatedAge >= 15
    }
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 0) {
                            ZStack {
                                HStack {
                                    Button(action: {
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                
                                Text("Personal Information")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            
                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.top, 20)
                                .padding(.bottom, 60)
                        }
                        .background(Color.premiumGradient)
                        .clipShape(RoundedCorner(radius: 40, corners: [.bottomLeft, .bottomRight]))
                        
                        VStack(spacing: 24) {
                            // Form Fields
                            VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Name", text: $name, iconName: "person")
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email (Locked)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Email", text: $email, keyboardType: .emailAddress, iconName: "envelope")
                                    .disabled(true)
                                    .opacity(0.6)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mobile number")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Mobile number", text: $mobile, keyboardType: .phonePad, iconName: "phone")
                                if !mobile.isEmpty && !isMobileValid {
                                    Text("Invalid 10-digit number")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date of Birth")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.gray)
                                    
                                    Button(action: { showDatePicker = true }) {
                                        CustomTextField(hint: "Select DOB", text: .constant(getFormattedDate(dobDate)), iconName: "calendar")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                    if !isAgeValid {
                                        Text("Minimum age is 15 years")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(.leading, 4)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Gender")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.gray)
                                    CustomTextField(hint: "Gender", text: $gender, iconName: "person.fill")
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Age (Calculated)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.gray)
                                    CustomTextField(hint: "Age", text: .constant("\(calculatedAge)"), keyboardType: .numberPad, iconName: "person.circle")
                                        .disabled(true)
                                        .opacity(0.8)
                                }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Country/Region")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Country/Region", text: $country, iconName: "globe")
                            }
                        }
                        .padding(24)
                        .glassStyle(cornerRadius: 30)
                        
                        PrimaryButton(title: isLoading ? "UPDATING..." : "Update") {
                            update()
                        }
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.6 : 1.0)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, -40)
                }
            }
        }
        }
        .onAppear {
            if let user = StorageManager.shared.getUser() {
                name = user.name
                email = user.email
                mobile = user.mobile
                gender = user.gender ?? ""
                country = user.country ?? ""
                
                // Parse DOB string back to Date
                if let dobString = user.dob {
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    if let date = df.date(from: dobString) {
                        dobDate = date
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Update Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .overlay {
            if showDatePicker {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDatePicker = false
                        }
                    
                    VStack {
                        Spacer()
                        VStack(spacing: 0) {
                            HStack {
                                Button("Cancel") { showDatePicker = false }
                                Spacer()
                                Button("Done") { showDatePicker = false }
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(Color(white: 0.98))
                            
                            DatePicker("", selection: $dobDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.appPink)
                        }
                        .cornerRadius(20)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    private func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func update() {
        if name.isEmpty || !isNameValid {
            errorMessage = "Please enter a valid Name"
            showAlert = true
            return
        }
        if !isMobileValid {
            errorMessage = "Please enter a valid 10-digit Mobile Number"
            showAlert = true
            return
        }
        if !isAgeValid {
            errorMessage = "Minimum age is 15 years"
            showAlert = true
            return
        }

        isLoading = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dateFormatter.string(from: dobDate)

        NetworkManager.shared.updateProfile(
            email: email,
            name: name,
            mobile: mobile,
            dob: dobString,
            gender: gender,
            age: "\(calculatedAge)",
            country: country
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success", var updatedUser = response.user {
                        updatedUser.country = country
                        StorageManager.shared.saveUser(updatedUser)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        errorMessage = response.message
                        showAlert = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

struct UpdateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateProfileView()
    }
}
