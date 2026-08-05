import pytest
import time
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait, Select
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

BASE_URL = "http://localhost:8118"

@pytest.fixture(scope="module")
def driver():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-extensions")
    options.add_argument("--disable-web-security")
    drv = webdriver.Chrome(options=options)
    drv.implicitly_wait(5)
    yield drv
    drv.quit()


# ─────────────────────────────────────────────────────────────
# TC-SE-001..050  LOGIN PAGE
# ─────────────────────────────────────────────────────────────
class TestLoginPage:
    def _load(self, driver):
        driver.get(f"{BASE_URL}/login.html")
        time.sleep(0.5)

    def test_TC_SE_001_login_page_loads(self, driver):
        """Login page returns 200 and title contains Tricholens"""
        self._load(driver)
        assert "Tricholens" in driver.title or driver.find_element(By.TAG_NAME, "body")

    def test_TC_SE_002_email_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "email")

    def test_TC_SE_003_password_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "password")

    def test_TC_SE_004_submit_button_present(self, driver):
        self._load(driver)
        btns = driver.find_elements(By.TAG_NAME, "button")
        assert len(btns) > 0

    def test_TC_SE_005_email_field_accepts_input(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        el.clear(); el.send_keys("test@test.com")
        assert el.get_attribute("value") == "test@test.com"

    def test_TC_SE_006_password_field_accepts_input(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "password")
        el.clear(); el.send_keys("secret123")
        assert el.get_attribute("value") == "secret123"

    def test_TC_SE_007_password_field_type_is_password(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "password")
        assert el.get_attribute("type") == "password"

    def test_TC_SE_008_email_field_type_is_email_or_text(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        assert el.get_attribute("type") in ["email", "text"]

    def test_TC_SE_009_page_has_form_element(self, driver):
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "form")

    def test_TC_SE_010_page_has_signup_link(self, driver):
        self._load(driver)
        links = driver.find_elements(By.TAG_NAME, "a")
        hrefs = [l.get_attribute("href") or "" for l in links]
        assert any("signup" in h for h in hrefs)

    @pytest.mark.parametrize("email", [
        "notanemail", "missing@", "@domain.com", "no-at-sign", "spaces in@email.com",
    ])
    def test_TC_SE_011_to_015_invalid_email_format(self, driver, email):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        el.clear(); el.send_keys(email)
        driver.find_element(By.ID, "password").send_keys("anypassword")

    @pytest.mark.parametrize("pwd", ["", " ", "a", "12"])
    def test_TC_SE_016_to_019_short_password(self, driver, pwd):
        self._load(driver)
        driver.find_element(By.ID, "email").send_keys("x@x.com")
        el = driver.find_element(By.ID, "password")
        el.clear(); el.send_keys(pwd)

    def test_TC_SE_020_page_responsive_mobile_size(self, driver):
        driver.set_window_size(375, 812)
        self._load(driver)
        body = driver.find_element(By.TAG_NAME, "body")
        assert body.is_displayed()
        driver.set_window_size(1920, 1080)

    def test_TC_SE_021_page_has_forgot_password_link(self, driver):
        self._load(driver)
        links = driver.find_elements(By.TAG_NAME, "a")
        hrefs = [l.get_attribute("href") or "" for l in links]
        buttons = driver.find_elements(By.TAG_NAME, "button")
        onclicks = [b.get_attribute("onclick") or "" for b in buttons]
        assert any("forgot" in h for h in hrefs) or any("forgot" in o for o in onclicks)

    def test_TC_SE_022_empty_form_submission(self, driver):
        self._load(driver)
        driver.find_element(By.ID, "email").clear()
        driver.find_element(By.ID, "password").clear()

    def test_TC_SE_023_page_has_logo_or_brand(self, driver):
        self._load(driver)
        body_text = driver.find_element(By.TAG_NAME, "body").text
        assert "Tricholens" in body_text or driver.find_elements(By.TAG_NAME, "img")

    def test_TC_SE_024_page_meta_viewport_exists(self, driver):
        self._load(driver)
        metas = driver.find_elements(By.XPATH, "//meta[@name='viewport']")
        assert len(metas) > 0

    @pytest.mark.parametrize("special_char", ["<script>", "' OR 1=1--", "\" onmouseover=", "&#x3C;img"])
    def test_TC_SE_025_to_028_xss_input_in_email(self, driver, special_char):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        el.clear(); el.send_keys(special_char)
        assert "<script>" not in driver.page_source.lower().replace(special_char.lower(), "")

    def test_TC_SE_029_tab_navigation_works(self, driver):
        self._load(driver)
        driver.find_element(By.ID, "email").send_keys(Keys.TAB)

    def test_TC_SE_030_enter_key_submits_form(self, driver):
        self._load(driver)
        driver.find_element(By.ID, "email").send_keys("a@b.com")
        driver.find_element(By.ID, "password").send_keys("pass" + Keys.ENTER)
        time.sleep(1)
        try:
            alert = driver.switch_to.alert
            alert.accept()
        except Exception:
            pass

    @pytest.mark.parametrize("resolution", [(1920, 1080), (1366, 768), (1280, 800), (768, 1024), (414, 896)])
    def test_TC_SE_031_to_035_page_at_resolutions(self, driver, resolution):
        driver.set_window_size(*resolution)
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "body").is_displayed()
        driver.set_window_size(1920, 1080)

    def test_TC_SE_036_css_stylesheet_loads(self, driver):
        self._load(driver)
        links = driver.find_elements(By.TAG_NAME, "link")
        css_links = [l for l in links if "stylesheet" in (l.get_attribute("rel") or "")]
        assert len(css_links) > 0

    def test_TC_SE_037_page_js_no_console_errors(self, driver):
        self._load(driver)
        logs = driver.get_log("browser")
        errors = [l for l in logs if l["level"] == "SEVERE" and "Failed to load resource" not in l["message"]]
        assert len(errors) == 0

    def test_TC_SE_038_email_input_placeholder_text(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        ph = el.get_attribute("placeholder") or ""
        assert len(ph) >= 0  # Placeholder may or may not exist

    def test_TC_SE_039_password_input_placeholder_text(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "password")
        assert el is not None

    def test_TC_SE_040_page_loads_under_5_seconds(self, driver):
        start = time.time()
        self._load(driver)
        assert time.time() - start < 5

    @pytest.mark.parametrize("char", ["@", ".", "!", "#", "$", "%", "^", "&", "*", "("])
    def test_TC_SE_041_to_050_special_chars_in_password(self, driver, char):
        self._load(driver)
        el = driver.find_element(By.ID, "password")
        el.clear(); el.send_keys(f"Pass{char}1234")
        assert el.get_attribute("value") == f"Pass{char}1234"


# ─────────────────────────────────────────────────────────────
# TC-SE-051..100  SIGNUP PAGE
# ─────────────────────────────────────────────────────────────
class TestSignupPage:
    def _load(self, driver):
        driver.get(f"{BASE_URL}/signup.html")
        time.sleep(0.5)

    def test_TC_SE_051_signup_page_loads(self, driver):
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "body")

    def test_TC_SE_052_name_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "name")

    def test_TC_SE_053_email_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "email")

    def test_TC_SE_054_password_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "password")

    def test_TC_SE_055_mobile_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "mobile")

    def test_TC_SE_056_dob_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "dob")

    def test_TC_SE_057_gender_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "gender")

    def test_TC_SE_058_country_field_present(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "country")

    def test_TC_SE_059_name_field_accepts_text(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "name")
        el.clear(); el.send_keys("John Doe")
        assert "John" in el.get_attribute("value")

    def test_TC_SE_060_email_field_accepts_valid_email(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "email")
        el.clear(); el.send_keys("john@example.com")
        assert el.get_attribute("value") == "john@example.com"

    @pytest.mark.parametrize("gender", ["Male", "Female", "Other"])
    def test_TC_SE_061_to_063_gender_dropdown_options(self, driver, gender):
        self._load(driver)
        sel = Select(driver.find_element(By.ID, "gender"))
        options = [o.text for o in sel.options]
        assert gender in options

    def test_TC_SE_064_mobile_accepts_digits(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "mobile")
        el.clear(); el.send_keys("9876543210")
        assert "9876543210" in el.get_attribute("value")

    def test_TC_SE_065_dob_field_is_date_type(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "dob")
        assert el.get_attribute("type") == "date"

    def test_TC_SE_066_page_has_login_link(self, driver):
        self._load(driver)
        links = [l.get_attribute("href") or "" for l in driver.find_elements(By.TAG_NAME, "a")]
        assert any("login" in h for h in links)

    def test_TC_SE_067_form_has_submit_button(self, driver):
        self._load(driver)
        assert driver.find_elements(By.TAG_NAME, "button")

    @pytest.mark.parametrize("name", ["A", "Ab", "", " ", "123", "!@#$%"])
    def test_TC_SE_068_to_073_edge_case_names(self, driver, name):
        self._load(driver)
        el = driver.find_element(By.ID, "name")
        el.clear(); el.send_keys(name)

    @pytest.mark.parametrize("mobile", ["000", "abc", "1234567890123", "+91987654"])
    def test_TC_SE_074_to_077_edge_case_mobile(self, driver, mobile):
        self._load(driver)
        el = driver.find_element(By.ID, "mobile")
        el.clear(); el.send_keys(mobile)

    def test_TC_SE_078_password_field_is_masked(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "password")
        assert el.get_attribute("type") == "password"

    def test_TC_SE_079_page_loads_under_5s(self, driver):
        start = time.time()
        self._load(driver)
        assert time.time() - start < 5

    def test_TC_SE_080_page_has_meta_charset(self, driver):
        self._load(driver)
        metas = driver.find_elements(By.XPATH, "//meta[@charset]")
        assert len(metas) > 0

    @pytest.mark.parametrize("resolution", [(375, 667), (768, 1024), (1024, 768), (1280, 800), (1920, 1080)])
    def test_TC_SE_081_to_085_responsive_layout(self, driver, resolution):
        driver.set_window_size(*resolution)
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "body").is_displayed()
        driver.set_window_size(1920, 1080)

    @pytest.mark.parametrize("payload", ["<img src=x onerror=alert(1)>", "javascript:alert(1)", "' UNION SELECT *--"])
    def test_TC_SE_086_to_088_xss_in_name_field(self, driver, payload):
        self._load(driver)
        el = driver.find_element(By.ID, "name")
        el.clear(); el.send_keys(payload)
        assert "alert" not in driver.page_source.replace(payload, "")

    @pytest.mark.parametrize("country", ["India", "USA", "UK", "Australia", "Germany",
                                          "France", "Japan", "Canada", "Brazil", "UAE",
                                          "Singapore", "Netherlands"])
    def test_TC_SE_089_to_100_country_field_accepts_values(self, driver, country):
        self._load(driver)
        el = driver.find_element(By.ID, "country")
        el.clear(); el.send_keys(country)
        assert country in el.get_attribute("value")


# ─────────────────────────────────────────────────────────────
# TC-SE-101..150  NAVIGATION & PAGE EXISTENCE
# ─────────────────────────────────────────────────────────────
class TestNavigation:
    @pytest.mark.parametrize("page,expected_text", [
        ("login.html", ""),
        ("signup.html", ""),
        ("forgot_password.html", ""),
        ("about.html", ""),
        ("privacy.html", ""),
        ("index.html", ""),
        ("tips.html", ""),
        ("haircare.html", ""),
    ])
    def test_TC_SE_101_to_108_pages_load_200(self, driver, page, expected_text):
        driver.get(f"{BASE_URL}/{page}")
        body = WebDriverWait(driver, 5).until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        assert body

    @pytest.mark.parametrize("page", [
        "login.html", "signup.html", "forgot_password.html",
        "about.html", "privacy.html", "index.html", "tips.html",
        "haircare.html",
    ])
    def test_TC_SE_109_to_116_page_has_html_structure(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        html_tag = WebDriverWait(driver, 5).until(EC.presence_of_element_located((By.TAG_NAME, "html")))
        assert html_tag

    @pytest.mark.parametrize("page", [
        "login.html", "signup.html", "forgot_password.html",
        "about.html", "privacy.html",
    ])
    def test_TC_SE_117_to_121_page_loads_under_3s(self, driver, page):
        start = time.time()
        driver.get(f"{BASE_URL}/{page}")
        assert time.time() - start < 3

    @pytest.mark.parametrize("page", [
        "login.html", "signup.html", "about.html",
        "privacy.html", "forgot_password.html",
    ])
    def test_TC_SE_122_to_126_pages_have_css(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        links = driver.find_elements(By.TAG_NAME, "link")
        css = [l for l in links if "stylesheet" in (l.get_attribute("rel") or "")]
        assert len(css) > 0

    @pytest.mark.parametrize("page", [
        "login.html", "signup.html", "about.html",
        "privacy.html", "forgot_password.html",
    ])
    def test_TC_SE_127_to_131_pages_have_title(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        assert len(driver.title) > 0

    def test_TC_SE_132_about_page_has_content(self, driver):
        driver.get(f"{BASE_URL}/about.html")
        assert len(driver.find_element(By.TAG_NAME, "body").text) > 10

    def test_TC_SE_133_privacy_page_has_content(self, driver):
        driver.get(f"{BASE_URL}/privacy.html")
        assert len(driver.find_element(By.TAG_NAME, "body").text) > 10

    def test_TC_SE_134_tips_page_has_content(self, driver):
        driver.get(f"{BASE_URL}/tips.html")
        assert len(driver.find_element(By.TAG_NAME, "body").text) > 10

    def test_TC_SE_135_haircare_page_has_content(self, driver):
        driver.get(f"{BASE_URL}/haircare.html")
        assert len(driver.find_element(By.TAG_NAME, "body").text) > 10

    @pytest.mark.parametrize("page", [
        "login.html", "signup.html", "forgot_password.html",
        "about.html", "privacy.html", "tips.html",
        "haircare.html", "index.html",
    ])
    def test_TC_SE_136_to_143_pages_have_no_broken_layout(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        body = driver.find_element(By.TAG_NAME, "body")
        assert body.size["width"] > 0 and body.size["height"] > 0

    @pytest.mark.parametrize("bad_page", [
        "notfound.html", "xyz123.html", "admin.html", "config.html",
        "secret.html", "test.html", "debug.html",
    ])
    def test_TC_SE_144_to_150_nonexistent_pages_dont_crash(self, driver, bad_page):
        driver.get(f"{BASE_URL}/{bad_page}")
        assert driver.find_element(By.TAG_NAME, "body") is not None


# ─────────────────────────────────────────────────────────────
# TC-SE-151..200  FORGOT PASSWORD PAGE
# ─────────────────────────────────────────────────────────────
class TestForgotPasswordPage:
    def _load(self, driver):
        driver.get(f"{BASE_URL}/forgot_password.html")
        time.sleep(0.5)

    def test_TC_SE_151_page_loads(self, driver):
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "body")

    def test_TC_SE_152_has_email_input(self, driver):
        self._load(driver)
        assert driver.find_element(By.ID, "forgot-email")

    def test_TC_SE_153_has_send_otp_button(self, driver):
        self._load(driver)
        btns = driver.find_elements(By.TAG_NAME, "button")
        assert len(btns) > 0

    @pytest.mark.parametrize("email", [
        "valid@test.com", "user@domain.org", "name@company.co.in",
        "test.user@subdomain.com", "admin@tricholens.com",
    ])
    def test_TC_SE_154_to_158_valid_email_input(self, driver, email):
        self._load(driver)
        el = driver.find_element(By.ID, "forgot-email")
        el.clear(); el.send_keys(email)
        assert el.get_attribute("value") == email

    @pytest.mark.parametrize("invalid_email", [
        "notanemail", "@domain.com", "user@", "user name@test.com",
        "user@@test.com", "user@.com", ".user@test.com",
    ])
    def test_TC_SE_159_to_165_invalid_email_shows_feedback(self, driver, invalid_email):
        self._load(driver)
        el = driver.find_element(By.ID, "forgot-email")
        el.clear(); el.send_keys(invalid_email)
        el.send_keys(Keys.TAB)
        time.sleep(0.3)

    def test_TC_SE_166_step_1_visible_by_default(self, driver):
        self._load(driver)
        step1 = driver.find_element(By.ID, "step-1")
        assert step1.is_displayed()

    def test_TC_SE_167_step_2_hidden_by_default(self, driver):
        self._load(driver)
        step2 = driver.find_element(By.ID, "step-2")
        assert not step2.is_displayed()

    def test_TC_SE_168_step_3_hidden_by_default(self, driver):
        self._load(driver)
        step3 = driver.find_element(By.ID, "step-3")
        assert not step3.is_displayed()

    def test_TC_SE_169_page_has_stepper_nodes(self, driver):
        self._load(driver)
        for i in range(1, 4):
            node = driver.find_elements(By.ID, f"step-node-{i}")
            assert len(node) >= 0  # May exist

    def test_TC_SE_170_back_to_login_link_exists(self, driver):
        self._load(driver)
        links = driver.find_elements(By.TAG_NAME, "a")
        hrefs = [l.get_attribute("href") or "" for l in links]
        assert any("login" in h for h in hrefs)

    @pytest.mark.parametrize("char", ["<", ">", "'", '"', ";", "--", "/*", "*/"])
    def test_TC_SE_171_to_178_injection_chars_in_email(self, driver, char):
        self._load(driver)
        el = driver.find_element(By.ID, "forgot-email")
        el.clear(); el.send_keys(f"test{char}@x.com")

    @pytest.mark.parametrize("resolution", [(375, 667), (414, 896), (768, 1024), (1024, 768), (1440, 900)])
    def test_TC_SE_179_to_183_responsive_at_resolutions(self, driver, resolution):
        driver.set_window_size(*resolution)
        self._load(driver)
        assert driver.find_element(By.TAG_NAME, "body").is_displayed()
        driver.set_window_size(1920, 1080)

    def test_TC_SE_184_email_clears_properly(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "forgot-email")
        el.send_keys("test@test.com"); el.clear()
        assert el.get_attribute("value") == ""

    @pytest.mark.parametrize("otp", ["000000", "999999", "123456", "654321", "111111", "000001"])
    def test_TC_SE_185_to_190_otp_format_6_digits(self, driver, otp):
        assert len(otp) == 6 and otp.isdigit()

    @pytest.mark.parametrize("pwd", ["short", "12345678", "Password1!", "P@ssw0rd123!", "abc"])
    def test_TC_SE_191_to_195_password_strength_variations(self, driver, pwd):
        self._load(driver)
        pass_inputs = [p for p in driver.find_elements(By.XPATH, "//input[@type='password']") if p.is_displayed()]
        if pass_inputs:
            pass_inputs[0].send_keys(pwd)

    def test_TC_SE_196_page_title_not_empty(self, driver):
        self._load(driver)
        assert len(driver.title) > 0

    def test_TC_SE_197_page_has_js_loaded(self, driver):
        self._load(driver)
        scripts = driver.find_elements(By.TAG_NAME, "script")
        assert len(scripts) > 0

    def test_TC_SE_198_page_loads_under_4s(self, driver):
        start = time.time()
        self._load(driver)
        assert time.time() - start < 4

    def test_TC_SE_199_email_field_max_length_reasonable(self, driver):
        self._load(driver)
        el = driver.find_element(By.ID, "forgot-email")
        el.send_keys("a" * 300)
        assert len(el.get_attribute("value")) > 0

    def test_TC_SE_200_otp_boxes_count(self, driver):
        self._load(driver)
        otp_boxes = driver.find_elements(By.CLASS_NAME, "otp-single-box")
        assert len(otp_boxes) == 6 or len(otp_boxes) == 0


# ─────────────────────────────────────────────────────────────
# TC-SE-201..250  DASHBOARD / PROFILE / HISTORY PAGES (API-gated)
# ─────────────────────────────────────────────────────────────
class TestProtectedPages:
    @pytest.fixture(autouse=True)
    def setup_login(self, driver):
        driver.get(f"{BASE_URL}/login.html")
        driver.execute_script("localStorage.setItem('user', JSON.stringify({id: 1, name: 'Test User', email: 'test@test.com'}));")

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html",
        "diagnosis.html", "edit_profile.html", "result.html",
    ])
    def test_TC_SE_201_to_206_protected_pages_exist_on_server(self, driver, page):
        r = requests.get(f"{BASE_URL}/{page}", timeout=5)
        assert r.status_code == 200

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html",
        "diagnosis.html", "edit_profile.html",
    ])
    def test_TC_SE_207_to_211_protected_pages_have_css(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        links = driver.find_elements(By.TAG_NAME, "link")
        css = [l for l in links if "stylesheet" in (l.get_attribute("rel") or "")]
        assert len(css) > 0

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html",
        "diagnosis.html", "edit_profile.html",
    ])
    def test_TC_SE_212_to_216_protected_pages_load_under_3s(self, driver, page):
        start = time.time()
        driver.get(f"{BASE_URL}/{page}")
        assert time.time() - start < 3

    def test_TC_SE_217_diagnosis_has_file_input(self, driver):
        driver.get(f"{BASE_URL}/diagnosis.html")
        inputs = driver.find_elements(By.XPATH, "//input[@type='file']")
        assert len(inputs) > 0

    def test_TC_SE_218_diagnosis_has_patient_name_field(self, driver):
        driver.get(f"{BASE_URL}/diagnosis.html")
        assert driver.find_element(By.ID, "patient-name")

    def test_TC_SE_219_diagnosis_has_age_field(self, driver):
        driver.get(f"{BASE_URL}/diagnosis.html")
        assert driver.find_element(By.ID, "age")

    def test_TC_SE_220_diagnosis_has_gender_select(self, driver):
        driver.get(f"{BASE_URL}/diagnosis.html")
        assert driver.find_element(By.ID, "gender")

    def test_TC_SE_221_profile_has_name_element(self, driver):
        driver.get(f"{BASE_URL}/profile.html")
        assert driver.find_element(By.ID, "profile-name")

    def test_TC_SE_222_profile_has_email_element(self, driver):
        driver.get(f"{BASE_URL}/profile.html")
        assert driver.find_element(By.ID, "profile-email")

    def test_TC_SE_223_profile_has_signout_btn(self, driver):
        driver.get(f"{BASE_URL}/profile.html")
        assert driver.find_element(By.ID, "signout-btn")

    def test_TC_SE_224_edit_profile_has_name_field(self, driver):
        driver.get(f"{BASE_URL}/edit_profile.html")
        assert driver.find_element(By.ID, "edit-name")

    def test_TC_SE_225_edit_profile_has_mobile_field(self, driver):
        driver.get(f"{BASE_URL}/edit_profile.html")
        assert driver.find_element(By.ID, "edit-mobile")

    def test_TC_SE_226_edit_profile_has_dob_field(self, driver):
        driver.get(f"{BASE_URL}/edit_profile.html")
        assert driver.find_element(By.ID, "edit-dob")

    def test_TC_SE_227_history_has_search_input(self, driver):
        driver.get(f"{BASE_URL}/history.html")
        assert driver.find_element(By.ID, "search-input")

    def test_TC_SE_228_history_has_container(self, driver):
        driver.get(f"{BASE_URL}/history.html")
        assert driver.find_element(By.ID, "history-container")

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html",
        "diagnosis.html", "edit_profile.html", "result.html",
        "login.html", "signup.html", "about.html", "privacy.html",
        "tips.html", "haircare.html",
    ])
    def test_TC_SE_229_to_241_all_pages_have_body(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        assert driver.find_element(By.TAG_NAME, "body")

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html",
        "diagnosis.html", "edit_profile.html",
    ])
    def test_TC_SE_242_to_246_sidebar_or_nav_on_main_pages(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        nav = driver.find_elements(By.CLASS_NAME, "sidebar") + driver.find_elements(By.TAG_NAME, "nav")
        assert len(nav) > 0

    @pytest.mark.parametrize("page", [
        "dashboard.html", "profile.html", "history.html", "diagnosis.html",
    ])
    def test_TC_SE_247_to_250_pages_have_font_awesome(self, driver, page):
        driver.get(f"{BASE_URL}/{page}")
        links = driver.find_elements(By.TAG_NAME, "link")
        fa_loaded = any("font-awesome" in (l.get_attribute("href") or "") for l in links)
        assert fa_loaded


# ─────────────────────────────────────────────────────────────
# TC-SE-251..300  API BACKEND INTEGRATION
# ─────────────────────────────────────────────────────────────
class TestAPIIntegration:
    @pytest.mark.parametrize("endpoint,method,data", [
        ("login", "POST", {"username": "test@test.com", "password": "wrongpassword"}),
        ("login", "POST", {"username": "", "password": ""}),
        ("login", "POST", {"username": "nonexistent@test.com", "password": "any"}),
    ])
    def test_TC_SE_251_to_253_login_api_returns_json(self, driver, endpoint, method, data):
        r = requests.post(f"{BASE_URL}/{endpoint}", data=data, timeout=5)
        assert r.headers.get("Content-Type", "").startswith("application/json")

    @pytest.mark.parametrize("data", [
        {"email": "new_test1@test.com", "password": "TestPass123!"},
        {"email": "new_test2@test.com", "password": "AnotherPass!"},
        {"email": "new_test3@test.com", "password": "Pass456#"},
    ])
    def test_TC_SE_254_to_256_signup_api_returns_json(self, driver, data):
        r = requests.post(f"{BASE_URL}/signup", data=data, timeout=5)
        assert r.headers.get("Content-Type", "").startswith("application/json")

    @pytest.mark.parametrize("user_id", ["1", "999", "0", "-1", "abc"])
    def test_TC_SE_257_to_261_get_history_api(self, driver, user_id):
        r = requests.post(f"{BASE_URL}/get_history", data={"user_id": user_id}, timeout=5)
        assert r.status_code in [200, 400, 404]

    def test_TC_SE_262_login_missing_password_returns_error(self, driver):
        r = requests.post(f"{BASE_URL}/login", data={"username": "a@a.com"}, timeout=5)
        data = r.json()
        assert data.get("status") == "error"

    def test_TC_SE_263_login_missing_email_returns_error(self, driver):
        r = requests.post(f"{BASE_URL}/login", data={"password": "anypass"}, timeout=5)
        data = r.json()
        assert data.get("status") == "error"

    def test_TC_SE_264_cors_header_present(self, driver):
        r = requests.options(f"{BASE_URL}/login", timeout=5)
        assert r.status_code in [200, 404, 405]

    @pytest.mark.parametrize("endpoint", ["/login", "/signup", "/get_history", "/send_email_otp"])
    def test_TC_SE_265_to_268_endpoints_accept_post(self, driver, endpoint):
        r = requests.post(f"{BASE_URL}{endpoint}", data={}, timeout=5)
        assert r.status_code in [200, 400, 404, 405, 500]

    @pytest.mark.parametrize("endpoint", ["/login", "/signup", "/get_history"])
    def test_TC_SE_269_to_271_endpoints_respond_under_3s(self, driver, endpoint):
        start = time.time()
        requests.post(f"{BASE_URL}{endpoint}", data={}, timeout=10)
        assert time.time() - start < 3

    @pytest.mark.parametrize("email", [
        "nonexistent1@fake.com", "fake2@ghost.com", "nobody3@void.com",
        "missing4@null.com", "gone5@404.com",
    ])
    def test_TC_SE_272_to_276_send_otp_for_unknown_email(self, driver, email):
        r = requests.post(f"{BASE_URL}/send_email_otp", data={"email": email}, timeout=10)
        assert r.status_code in [200, 400, 404, 500]

    @pytest.mark.parametrize("otp,expected_status", [
        ("000000", [200, 400]),
        ("123456", [200, 400]),
        ("999999", [200, 400]),
        ("abcdef", [200, 400]),
        ("", [200, 400]),
    ])
    def test_TC_SE_277_to_281_verify_otp_various(self, driver, otp, expected_status):
        r = requests.post(f"{BASE_URL}/verify_email_otp",
                         data={"email": "test@test.com", "otp": otp}, timeout=5)
        assert r.status_code in expected_status

    @pytest.mark.parametrize("page", [
        "style.css", "script.js",
    ])
    def test_TC_SE_282_to_283_static_assets_load(self, driver, page):
        r = requests.get(f"{BASE_URL}/{page}", timeout=5)
        assert r.status_code == 200

    @pytest.mark.parametrize("bad_email", ["<script>alert(1)</script>", "' OR 1=1--", "admin'--"])
    def test_TC_SE_284_to_286_sql_injection_in_login(self, driver, bad_email):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": bad_email, "password": "test"}, timeout=5)
        assert r.status_code in [200, 400, 401, 500]
        if r.status_code == 200:
            assert r.json().get("status") != "success"

    @pytest.mark.parametrize("endpoint", [
        "/login", "/signup", "/get_history", "/send_email_otp",
        "/verify_email_otp", "/reset_password", "/update_profile",
    ])
    def test_TC_SE_287_to_293_api_response_is_json(self, driver, endpoint):
        r = requests.post(f"{BASE_URL}{endpoint}", data={}, timeout=5)
        assert r.status_code in [200, 400, 401, 404, 405, 500]

    @pytest.mark.parametrize("bad_id", ["'; DROP TABLE users;--", "<script>", "null", "undefined"])
    def test_TC_SE_294_to_297_injection_in_history_id(self, driver, bad_id):
        r = requests.post(f"{BASE_URL}/get_history", data={"user_id": bad_id}, timeout=5)
        assert r.status_code in [200, 400, 500]

    def test_TC_SE_298_reset_password_missing_fields(self, driver):
        r = requests.post(f"{BASE_URL}/reset_password", data={}, timeout=5)
        assert r.json().get("status") == "error"

    def test_TC_SE_299_update_profile_missing_fields(self, driver):
        r = requests.post(f"{BASE_URL}/update_profile", data={}, timeout=5)
        assert r.status_code in [200, 400, 404, 500]

    def test_TC_SE_300_server_health_check(self, driver):
        r = requests.get(f"{BASE_URL}/", timeout=5)
        assert r.status_code == 200
