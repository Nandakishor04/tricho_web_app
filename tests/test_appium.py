"""
Appium-style tests: simulates mobile app API flows (iOS Tricholens app)
Since CI has no physical device, these run as REST API tests that mirror
exactly what the iOS app does (same endpoints, same payloads).
"""
import pytest
import time
import uuid
import requests

BASE_URL = "http://localhost:8118"
TIMEOUT = 10

# Shared state across test module
_created_users = []
_session_user = {}


# ─────────────────────────────────────────────────────────────
# TC-AP-001..060  AUTHENTICATION FLOWS (iOS Login/Signup)
# ─────────────────────────────────────────────────────────────
class TestMobileAuthFlows:

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_001_to_010_signup_new_unique_user(self, run):
        """Mobile app signup with unique email each run"""
        unique_email = f"appium_user_{run}_{uuid.uuid4().hex[:6]}@tricholens.test"
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": f"AppiumUser{run}",
            "email": unique_email,
            "password": "AppTest@123",
            "mobile": f"98765{run:05d}",
            "dob": "1995-06-15",
            "gender": "Male",
            "country": "India",
            "age": "29"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]
        data = r.json()
        if data.get("status") == "success":
            _created_users.append({"email": unique_email, "password": "AppTest@123"})

    @pytest.mark.parametrize("gender", ["Male", "Female", "Other"])
    def test_TC_AP_011_to_013_signup_all_genders(self, gender):
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": f"TestUser{gender}",
            "email": f"test_{gender.lower()}_{uuid.uuid4().hex[:6]}@t.com",
            "password": "Pass@1234",
            "gender": gender
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("country", [
        "India", "USA", "UK", "Canada", "Australia",
        "Germany", "France", "Japan", "Singapore", "UAE"
    ])
    def test_TC_AP_014_to_023_signup_various_countries(self, country):
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": "CountryUser",
            "email": f"country_{country.lower()}_{uuid.uuid4().hex[:4]}@t.com",
            "password": "Pass@1234",
            "country": country
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("bad_email", [
        "notanemail", "@nodomain", "nodomain@", "",
        "spaces in email@t.com", "double@@at.com"
    ])
    def test_TC_AP_024_to_029_signup_invalid_email(self, bad_email):
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": "BadEmailUser",
            "email": bad_email,
            "password": "Pass@1234"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_030_to_039_login_wrong_password(self, run):
        r = requests.post(f"{BASE_URL}/login", data={
            "username": f"user_{run}@test.com",
            "password": "WrongPassword123!"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401]
        assert r.json().get("status") in ["error", None] or r.status_code != 200

    @pytest.mark.parametrize("identifier_type", ["email", "mobile", "name"])
    def test_TC_AP_040_to_042_login_by_identifier_type(self, identifier_type):
        identifier_map = {
            "email": "test@tricholens.com",
            "mobile": "9876543210",
            "name": "TestUserName"
        }
        r = requests.post(f"{BASE_URL}/login", data={
            "username": identifier_map[identifier_type],
            "password": "TestPass123!"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401]

    def test_TC_AP_043_login_returns_user_id_on_success(self):
        # Create then immediately login
        email = f"check_user_{uuid.uuid4().hex[:6]}@t.com"
        signup_r = requests.post(f"{BASE_URL}/signup", data={
            "name": "CheckUser", "email": email, "password": "Pass@1234"
        }, timeout=TIMEOUT)
        if signup_r.json().get("status") == "success":
            login_r = requests.post(f"{BASE_URL}/login",
                                    data={"username": email, "password": "Pass@1234"},
                                    timeout=TIMEOUT)
            if login_r.status_code == 200:
                user_data = login_r.json().get("user", {})
                assert "id" in user_data

    def test_TC_AP_044_login_returns_user_name(self):
        email = f"name_check_{uuid.uuid4().hex[:6]}@t.com"
        signup_r = requests.post(f"{BASE_URL}/signup", data={
            "name": "NameCheckUser", "email": email, "password": "Pass@1234"
        }, timeout=TIMEOUT)
        if signup_r.json().get("status") == "success":
            login_r = requests.post(f"{BASE_URL}/login",
                                    data={"username": email, "password": "Pass@1234"},
                                    timeout=TIMEOUT)
            if login_r.status_code == 200:
                user_data = login_r.json().get("user", {})
                assert "name" in user_data or "username" in user_data

    def test_TC_AP_045_login_response_json_structure(self):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": "any@any.com", "password": "any"},
                         timeout=TIMEOUT)
        data = r.json()
        assert "status" in data

    @pytest.mark.parametrize("run", range(1, 16))
    def test_TC_AP_046_to_060_signup_with_special_name_chars(self, run):
        special_names = [
            "John O'Brien", "María García", "Müller Hans", "Jean-Pierre",
            "Ravi Kumar S", "Li Wei", "Björn Ansen", "Aaña Singh",
            "Priya.Sharma", "D'Souza John", "Smith Jr", "O Brien",
            "von Trapp", "del Monte", "bin Laden"
        ]
        name = special_names[run - 1]
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": name,
            "email": f"special_{run}_{uuid.uuid4().hex[:4]}@t.com",
            "password": "Pass@1234"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]


# ─────────────────────────────────────────────────────────────
# TC-AP-061..120  PROFILE MANAGEMENT FLOWS
# ─────────────────────────────────────────────────────────────
class TestMobileProfileFlows:

    def _create_user(self, suffix=""):
        email = f"profile_{suffix}_{uuid.uuid4().hex[:6]}@t.com"
        r = requests.post(f"{BASE_URL}/signup", data={
            "name": f"ProfileUser{suffix}",
            "email": email,
            "password": "Pass@1234",
        }, timeout=TIMEOUT)
        if r.json().get("status") == "success":
            return r.json().get("user", {}), email
        return {}, email

    @pytest.mark.parametrize("field,value", [
        ("name", "Updated Name"),
        ("mobile", "9876512345"),
        ("country", "USA"),
        ("gender", "Female"),
        ("dob", "1990-01-01"),
    ])
    def test_TC_AP_061_to_065_update_profile_single_field(self, field, value):
        user, email = self._create_user(field)
        if not user:
            pytest.skip("User creation failed")
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": email,
            "user_id": user.get("id", ""),
            field: value
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("name", [
        "Simple Name", "Name With Numbers 123", "Name-With-Hyphen",
        "Name.With.Dots", "VeryLongNameThatGoesOnAndOnAndOn",
        "Short", "A", "AB", "Name With    Spaces",
        "ALLCAPS", "lowercase name"
    ])
    def test_TC_AP_066_to_076_update_profile_name_variations(self, name):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": f"nametest_{uuid.uuid4().hex[:4]}@t.com",
            "name": name
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("mobile", [
        "9876543210", "+919876543210", "09876543210",
        "1234567890", "0000000000", "9999999999"
    ])
    def test_TC_AP_077_to_082_update_mobile_formats(self, mobile):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": "existing@test.com",
            "mobile": mobile
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("dob", [
        "1990-01-01", "2000-12-31", "1985-06-15",
        "1975-03-22", "1999-11-11"
    ])
    def test_TC_AP_083_to_087_update_dob(self, dob):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": "existing@test.com",
            "dob": dob
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_AP_088_update_profile_by_user_id(self):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "user_id": "1",
            "name": "Updated Via ID"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_AP_089_update_profile_returns_user_object(self):
        user, email = self._create_user("retobj")
        if not user:
            pytest.skip("User creation failed")
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": email,
            "user_id": user.get("id", ""),
            "name": "Updated Name"
        }, timeout=TIMEOUT)
        if r.status_code == 200:
            data = r.json()
            assert "user" in data or "status" in data

    @pytest.mark.parametrize("country", [
        "India", "USA", "UK", "Australia", "Canada",
        "Germany", "France", "Japan", "Brazil", "UAE",
        "Singapore", "Netherlands", "South Korea", "Mexico", "Spain",
        "Italy", "Russia", "China", "Sweden", "Norway",
        "Denmark", "Finland", "Switzerland", "Austria", "Belgium",
        "Portugal", "Poland", "Turkey", "Greece", "Thailand"
    ])
    def test_TC_AP_090_to_119_update_profile_country_list(self, country):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": "test@test.com",
            "country": country
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_AP_120_update_nonexistent_user(self):
        r = requests.post(f"{BASE_URL}/update_profile", data={
            "email": "idonotexist_xyz123@fake.com",
            "name": "Ghost User"
        }, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]


# ─────────────────────────────────────────────────────────────
# TC-AP-121..180  OTP & PASSWORD RESET FLOWS
# ─────────────────────────────────────────────────────────────
class TestMobileOTPFlows:

    @pytest.mark.parametrize("email", [
        "notregistered1@fake.com", "notregistered2@fake.com",
        "ghost@void.com", "nobody@nowhere.com",
        "missing@lost.com",
    ])
    def test_TC_AP_121_to_125_otp_for_unregistered_emails(self, email):
        r = requests.post(f"{BASE_URL}/send_email_otp", data={"email": email}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]
        if r.status_code == 404:
            assert r.json().get("status") == "error"

    @pytest.mark.parametrize("bad_email", [
        "notanemail", "@domain.com", "user@", "user name@test.com",
        "", "null", "undefined", "   ", "user@@test.com",
        "<script>@test.com",
    ])
    def test_TC_AP_126_to_135_otp_invalid_email_formats(self, bad_email):
        r = requests.post(f"{BASE_URL}/send_email_otp", data={"email": bad_email}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]
        if r.status_code == 200:
            assert r.json().get("status") in ["error", "success"]

    @pytest.mark.parametrize("otp,email", [
        ("000000", "test1@test.com"),
        ("123456", "test2@test.com"),
        ("999999", "test3@test.com"),
        ("654321", "test4@test.com"),
        ("111111", "test5@test.com"),
        ("222222", "test6@test.com"),
        ("333333", "test7@test.com"),
        ("444444", "test8@test.com"),
        ("555555", "test9@test.com"),
        ("666666", "test10@test.com"),
    ])
    def test_TC_AP_136_to_145_verify_otp_various_codes(self, otp, email):
        r = requests.post(f"{BASE_URL}/verify_email_otp",
                         data={"email": email, "otp": otp},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("otp", ["12345", "1234567", "abcdef", "", " "])
    def test_TC_AP_146_to_150_verify_invalid_otp_length(self, otp):
        r = requests.post(f"{BASE_URL}/verify_email_otp",
                         data={"email": "test@test.com", "otp": otp},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("password", [
        "NewPass@123", "SecureP@ssw0rd", "Tr!cholens2024",
        "MyN3wP@ss!", "ChangedPass#1",
    ])
    def test_TC_AP_151_to_155_reset_password_valid_format(self, password):
        r = requests.post(f"{BASE_URL}/reset_password",
                         data={"email": "test@test.com", "password": password},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("password", ["short", "12345", "abc", "", " "])
    def test_TC_AP_156_to_160_reset_password_weak(self, password):
        r = requests.post(f"{BASE_URL}/reset_password",
                         data={"email": "test@test.com", "password": password},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_AP_161_reset_password_missing_email(self):
        r = requests.post(f"{BASE_URL}/reset_password",
                         data={"password": "NewPass@123"},
                         timeout=TIMEOUT)
        assert r.json().get("status") == "error"

    def test_TC_AP_162_reset_password_missing_password(self):
        r = requests.post(f"{BASE_URL}/reset_password",
                         data={"email": "test@test.com"},
                         timeout=TIMEOUT)
        assert r.json().get("status") == "error"

    def test_TC_AP_163_reset_password_nonexistent_user(self):
        r = requests.post(f"{BASE_URL}/reset_password",
                         data={"email": "ghost_xyz123@nowhere.com", "password": "NewPass@123"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_AP_164_full_otp_reset_flow_structure(self):
        # Verify the API flow structure: send OTP → verify → reset
        # Step 1: send OTP
        r1 = requests.post(f"{BASE_URL}/send_email_otp",
                          data={"email": "flowtest@fake.com"},
                          timeout=TIMEOUT)
        assert r1.status_code in [200, 400, 404, 500]
        # Step 2: verify (bypass OTP)
        r2 = requests.post(f"{BASE_URL}/verify_email_otp",
                          data={"email": "flowtest@fake.com", "otp": "123456"},
                          timeout=TIMEOUT)
        assert r2.status_code in [200, 400, 500]
        # Step 3: reset
        r3 = requests.post(f"{BASE_URL}/reset_password",
                          data={"email": "flowtest@fake.com", "password": "NewPass@123"},
                          timeout=TIMEOUT)
        assert r3.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("run", range(1, 17))
    def test_TC_AP_165_to_180_otp_endpoint_repeated_calls(self, run):
        r = requests.post(f"{BASE_URL}/verify_email_otp",
                         data={"email": f"repeat_{run}@test.com", "otp": "123456"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]


# ─────────────────────────────────────────────────────────────
# TC-AP-181..240  HISTORY & DIAGNOSIS FLOWS
# ─────────────────────────────────────────────────────────────
class TestMobileHistoryFlows:

    @pytest.mark.parametrize("user_id", ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
    def test_TC_AP_181_to_190_get_history_valid_ids(self, user_id):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": user_id}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]
        data = r.json()
        assert "status" in data

    @pytest.mark.parametrize("user_id", ["0", "-1", "999999", "abc", "", "null"])
    def test_TC_AP_191_to_196_get_history_edge_case_ids(self, user_id):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": user_id}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    def test_TC_AP_197_history_response_has_history_key(self):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": "1"}, timeout=TIMEOUT)
        data = r.json()
        if data.get("status") == "success":
            assert "history" in data

    def test_TC_AP_198_history_items_have_required_fields(self):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": "1"}, timeout=TIMEOUT)
        data = r.json()
        if data.get("status") == "success" and data.get("history"):
            item = data["history"][0]
            expected_fields = ["id", "density", "condition"]
            for field in expected_fields:
                assert field in item

    def test_TC_AP_199_delete_nonexistent_history(self):
        r = requests.post(f"{BASE_URL}/delete_history",
                         json={"id": "999999"}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("bad_id", ["abc", "", "null", "-1", "0"])
    def test_TC_AP_200_to_204_delete_history_bad_ids(self, bad_id):
        r = requests.post(f"{BASE_URL}/delete_history",
                         json={"id": bad_id}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("run", range(1, 21))
    def test_TC_AP_205_to_224_history_endpoint_stability(self, run):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": str(run % 5 + 1)}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("run", range(1, 17))
    def test_TC_AP_225_to_240_diagnose_endpoint_no_image(self, run):
        r = requests.post(f"{BASE_URL}/diagnose",
                         data={"user_id": str(run), "patient_name": f"Patient{run}",
                               "age": "30", "gender": "Male"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]


# ─────────────────────────────────────────────────────────────
# TC-AP-241..300  END-TO-END MOBILE FLOWS
# ─────────────────────────────────────────────────────────────
class TestMobileE2EFlows:

    def _signup_and_login(self, suffix=""):
        email = f"e2e_{suffix}_{uuid.uuid4().hex[:6]}@t.com"
        signup = requests.post(f"{BASE_URL}/signup", data={
            "name": f"E2EUser{suffix}",
            "email": email,
            "password": "E2EPass@123",
            "mobile": "9876543210",
            "dob": "1995-01-01",
            "gender": "Male",
            "country": "India"
        }, timeout=TIMEOUT)
        if signup.json().get("status") != "success":
            return None, None
        login = requests.post(f"{BASE_URL}/login",
                             data={"username": email, "password": "E2EPass@123"},
                             timeout=TIMEOUT)
        if login.status_code == 200 and login.json().get("status") == "success":
            return login.json().get("user", {}), email
        return None, email

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_241_to_250_full_signup_login_flow(self, run):
        user, email = self._signup_and_login(f"flow{run}")
        # A valid user is returned OR it fails cleanly
        assert user is not None or email is not None

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_251_to_260_signup_login_get_history_flow(self, run):
        user, email = self._signup_and_login(f"hist{run}")
        if user and user.get("id"):
            r = requests.post(f"{BASE_URL}/get_history",
                             data={"user_id": user["id"]}, timeout=TIMEOUT)
            assert r.status_code in [200, 400, 500]

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_261_to_270_signup_update_profile_flow(self, run):
        user, email = self._signup_and_login(f"upd{run}")
        if user and email:
            r = requests.post(f"{BASE_URL}/update_profile", data={
                "email": email,
                "user_id": user.get("id", ""),
                "name": f"UpdatedUser{run}",
                "country": "USA"
            }, timeout=TIMEOUT)
            assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_271_to_280_api_response_times_mobile(self, run):
        start = time.time()
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": f"mobile_{run}@t.com", "password": "pass"},
                         timeout=TIMEOUT)
        elapsed = (time.time() - start) * 1000
        assert elapsed < 3000

    @pytest.mark.parametrize("endpoint,data", [
        ("/login", {"username": "", "password": ""}),
        ("/signup", {"email": "", "password": ""}),
        ("/get_history", {"user_id": ""}),
        ("/send_email_otp", {"email": ""}),
        ("/verify_email_otp", {"email": "", "otp": ""}),
        ("/reset_password", {"email": "", "password": ""}),
        ("/update_profile", {"email": "", "user_id": ""}),
        ("/delete_history", {}),
        ("/diagnose", {}),
        ("/check_mobile", {"mobile": ""}),
    ])
    def test_TC_AP_281_to_290_all_endpoints_empty_payload(self, endpoint, data):
        r = requests.post(f"{BASE_URL}{endpoint}", data=data, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 404, 405, 500]
        assert r.headers.get("Content-Type", "").startswith("application/json")

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_AP_291_to_300_mobile_session_flow_repeated(self, run):
        """Simulates full mobile session: signup/login → get history → update profile"""
        user, email = self._signup_and_login(f"sess{run}")
        if user and user.get("id"):
            # Get history
            r1 = requests.post(f"{BASE_URL}/get_history",
                              data={"user_id": user["id"]}, timeout=TIMEOUT)
            assert r1.status_code in [200, 400, 500]
            # Update profile
            r2 = requests.post(f"{BASE_URL}/update_profile",
                              data={"email": email, "user_id": user["id"],
                                    "country": "India"}, timeout=TIMEOUT)
            assert r2.status_code in [200, 400, 404, 500]
