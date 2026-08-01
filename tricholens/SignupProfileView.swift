import SwiftUI

struct SignupProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var dob = Date()
    @State private var gender = ""
    @State private var country = ""
    @State private var showDatePicker = false
    
    private let genders = ["Male", "Female", "Other"]
    
    private var isNameValid: Bool {
        name.rangeOfCharacter(from: .letters) != nil
    }
    
    private var calculatedAge: Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }
    
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isMobileValid: Bool {
        // 10 digits and starting with [6-9]
        let mobileRegex = "^[6-9]\\d{9}$"
        let mobilePredicate = NSPredicate(format:"SELF MATCHES %@", mobileRegex)
        return mobilePredicate.evaluate(with: mobile)
    }
    
    private var isAgeValid: Bool {
        calculatedAge >= 15
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && isEmailValid && isMobileValid && isAgeValid && !country.isEmpty && !gender.isEmpty
    }
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        BackButton()
                        Spacer()
                    }
                    
                    Text("Personal Information")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .frame(height: 70)
                .glassStyle(cornerRadius: 0)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Fields Card
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Name", text: $name, iconName: "person")
                                if !name.isEmpty && !isNameValid {
                                    Text("Name must contain characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Email", text: $email, keyboardType: .emailAddress, iconName: "envelope")
                                if !email.isEmpty && !isEmailValid {
                                    Text("Invalid email format")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mobile number")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                CustomTextField(hint: "Mobile number", text: $mobile, keyboardType: .phonePad, iconName: "phone")
                                if !mobile.isEmpty && !isMobileValid {
                                    Text("Invalid number")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            DatePickerField(date: $dob, showPicker: $showDatePicker, iconName: "calendar")
                            
                            if dob != Date() && !isAgeValid {
                                Text("Minimum age is 15 years")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                Text("\(calculatedAge)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.strokeLightGray, lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                Menu {
                                    Picker("Gender", selection: $gender) {
                                        ForEach(genders, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        if gender.isEmpty {
                                            Text("Gender")
                                                .foregroundColor(.gray.opacity(0.8))
                                                .font(.system(size: 16))
                                        } else {
                                            Text(gender)
                                                .foregroundColor(.black)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.strokeLightGray, lineWidth: 1)
                                    )
                                }
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
                        
                        PrimaryButton(title: "Save", action: {
                            dismiss()
                        })
                        .padding(.bottom, 30)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
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
                            
                            DatePicker("", selection: $dob, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.appPink) // Full solid pink background as requested
                        }
                        .cornerRadius(20)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showDatePicker)
            }
        }
    }
    
    // Sub-component for Date of Birth
    private func DatePickerField(date: Binding<Date>, showPicker: Binding<Bool>, iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
            
            Button(action: {
                showPicker.wrappedValue = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    
                    Text(getFormattedDate(date.wrappedValue))
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.strokeLightGray, lineWidth: 1.5)
                )
            }
        }
    }
    
    private func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct SignupProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignupProfileView()
        }
    }
}
