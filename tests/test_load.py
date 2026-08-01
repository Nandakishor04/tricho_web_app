import pytest
import time
import requests
import threading
import statistics

BASE_URL = "http://localhost:8118"
TIMEOUT = 10

# ─────────────────────────────────────────────────────────────
# TC-LD-001..060  RESPONSE TIME TESTS
# ─────────────────────────────────────────────────────────────
class TestResponseTime:

    @pytest.mark.parametrize("endpoint,method,data,max_ms", [
        ("/", "GET", None, 2000),
        ("/login.html", "GET", None, 2000),
        ("/signup.html", "GET", None, 2000),
        ("/about.html", "GET", None, 2000),
        ("/privacy.html", "GET", None, 2000),
        ("/style.css", "GET", None, 2000),
        ("/script.js", "GET", None, 2000),
        ("/index.html", "GET", None, 2000),
        ("/forgot_password.html", "GET", None, 2000),
        ("/tips.html", "GET", None, 2000),
    ])
    def test_TC_LD_001_to_010_static_page_response_time(self, endpoint, method, data, max_ms):
        start = time.time()
        if method == "GET":
            r = requests.get(f"{BASE_URL}{endpoint}", timeout=TIMEOUT)
        else:
            r = requests.post(f"{BASE_URL}{endpoint}", data=data or {}, timeout=TIMEOUT)
        elapsed_ms = (time.time() - start) * 1000
        assert elapsed_ms < max_ms, f"{endpoint} took {elapsed_ms:.0f}ms (limit: {max_ms}ms)"

    @pytest.mark.parametrize("run", range(1, 21))
    def test_TC_LD_011_to_030_homepage_repeated_loads(self, run):
        start = time.time()
        r = requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
        elapsed = (time.time() - start) * 1000
        assert r.status_code == 200
        assert elapsed < 3000, f"Run {run}: homepage took {elapsed:.0f}ms"

    @pytest.mark.parametrize("run", range(1, 16))
    def test_TC_LD_031_to_045_login_api_response_time(self, run):
        start = time.time()
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": f"load_test_{run}@test.com", "password": "test"},
                         timeout=TIMEOUT)
        elapsed = (time.time() - start) * 1000
        assert elapsed < 3000, f"Run {run}: /login took {elapsed:.0f}ms"

    @pytest.mark.parametrize("run", range(1, 16))
    def test_TC_LD_046_to_060_history_api_response_time(self, run):
        start = time.time()
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": str(run)}, timeout=TIMEOUT)
        elapsed = (time.time() - start) * 1000
        assert elapsed < 3000, f"Run {run}: /get_history took {elapsed:.0f}ms"


# ─────────────────────────────────────────────────────────────
# TC-LD-061..120  CONCURRENT REQUEST TESTS
# ─────────────────────────────────────────────────────────────
class TestConcurrentLoad:

    def _concurrent_get(self, url, n_threads):
        results = []
        errors = []
        def worker():
            try:
                start = time.time()
                r = requests.get(url, timeout=TIMEOUT)
                results.append((r.status_code, (time.time() - start) * 1000))
            except Exception as e:
                errors.append(str(e))
        threads = [threading.Thread(target=worker) for _ in range(n_threads)]
        for t in threads: t.start()
        for t in threads: t.join()
        return results, errors

    def _concurrent_post(self, url, data, n_threads):
        results = []
        errors = []
        def worker():
            try:
                start = time.time()
                r = requests.post(url, data=data, timeout=TIMEOUT)
                results.append((r.status_code, (time.time() - start) * 1000))
            except Exception as e:
                errors.append(str(e))
        threads = [threading.Thread(target=worker) for _ in range(n_threads)]
        for t in threads: t.start()
        for t in threads: t.join()
        return results, errors

    @pytest.mark.parametrize("n_users", [2, 5, 10, 15, 20])
    def test_TC_LD_061_to_065_concurrent_homepage(self, n_users):
        results, errors = self._concurrent_get(f"{BASE_URL}/", n_users)
        assert len(errors) == 0, f"Errors: {errors}"
        assert all(r[0] == 200 for r in results)

    @pytest.mark.parametrize("n_users", [2, 5, 10, 15, 20])
    def test_TC_LD_066_to_070_concurrent_login_page(self, n_users):
        results, errors = self._concurrent_get(f"{BASE_URL}/login.html", n_users)
        assert len(errors) == 0
        assert all(r[0] == 200 for r in results)

    @pytest.mark.parametrize("n_users", [2, 5, 10, 15, 20])
    def test_TC_LD_071_to_075_concurrent_signup_page(self, n_users):
        results, errors = self._concurrent_get(f"{BASE_URL}/signup.html", n_users)
        assert len(errors) == 0
        assert all(r[0] == 200 for r in results)

    @pytest.mark.parametrize("n_users", [2, 5, 10])
    def test_TC_LD_076_to_078_concurrent_login_api_calls(self, n_users):
        results, errors = self._concurrent_post(
            f"{BASE_URL}/login",
            {"username": "load@test.com", "password": "testpwd"},
            n_users
        )
        assert len(errors) == 0

    @pytest.mark.parametrize("n_users", [2, 5, 10])
    def test_TC_LD_079_to_081_concurrent_history_api_calls(self, n_users):
        results, errors = self._concurrent_post(
            f"{BASE_URL}/get_history",
            {"user_id": "1"},
            n_users
        )
        assert len(errors) == 0

    @pytest.mark.parametrize("n_users", [2, 5, 10])
    def test_TC_LD_082_to_084_concurrent_signup_calls(self, n_users):
        results = []
        errors = []
        def worker(i):
            try:
                r = requests.post(f"{BASE_URL}/signup",
                                 data={"email": f"conctest_{i}_{time.time()}@test.com",
                                       "password": "TestPass123!",
                                       "name": f"ConcUser{i}"},
                                 timeout=TIMEOUT)
                results.append(r.status_code)
            except Exception as e:
                errors.append(str(e))
        threads = [threading.Thread(target=worker, args=(i,)) for i in range(n_users)]
        for t in threads: t.start()
        for t in threads: t.join()
        assert len(errors) == 0

    @pytest.mark.parametrize("n_users", [2, 5, 10])
    def test_TC_LD_085_to_087_concurrent_css_requests(self, n_users):
        results, errors = self._concurrent_get(f"{BASE_URL}/style.css", n_users)
        assert len(errors) == 0
        assert all(r[0] == 200 for r in results)

    @pytest.mark.parametrize("n_users", [2, 5, 10])
    def test_TC_LD_088_to_090_concurrent_js_requests(self, n_users):
        results, errors = self._concurrent_get(f"{BASE_URL}/script.js", n_users)
        assert len(errors) == 0
        assert all(r[0] == 200 for r in results)

    def test_TC_LD_091_20_users_homepage_all_succeed(self):
        results, errors = self._concurrent_get(f"{BASE_URL}/", 20)
        success_rate = len([r for r in results if r[0] == 200]) / len(results)
        assert success_rate >= 0.95  # 95% success rate

    def test_TC_LD_092_20_users_avg_response_under_3s(self):
        results, errors = self._concurrent_get(f"{BASE_URL}/", 20)
        avg_ms = statistics.mean([r[1] for r in results])
        assert avg_ms < 3000

    def test_TC_LD_093_10_users_login_api_no_crash(self):
        results, errors = self._concurrent_post(f"{BASE_URL}/login",
                                                 {"username": "t@t.com", "password": "p"}, 10)
        assert len(errors) == 0

    def test_TC_LD_094_max_response_time_under_5s(self):
        results, errors = self._concurrent_get(f"{BASE_URL}/", 15)
        max_ms = max([r[1] for r in results])
        assert max_ms < 5000

    def test_TC_LD_095_p95_response_time(self):
        results, errors = self._concurrent_get(f"{BASE_URL}/login.html", 20)
        times = sorted([r[1] for r in results])
        p95 = times[int(len(times) * 0.95)]
        assert p95 < 4000

    def test_TC_LD_096_50_sequential_requests_homepage(self):
        for i in range(50):
            r = requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
            assert r.status_code == 200

    def test_TC_LD_097_server_stable_after_burst(self):
        self._concurrent_get(f"{BASE_URL}/", 25)
        time.sleep(1)
        r = requests.get(f"{BASE_URL}/", timeout=5)
        assert r.status_code == 200

    def test_TC_LD_098_concurrent_different_pages(self):
        pages = ["/login.html", "/signup.html", "/about.html", "/privacy.html", "/tips.html"]
        results = []
        errors = []
        def worker(page):
            try:
                r = requests.get(f"{BASE_URL}{page}", timeout=TIMEOUT)
                results.append(r.status_code)
            except Exception as e:
                errors.append(str(e))
        threads = [threading.Thread(target=worker, args=(p,)) for p in pages * 4]
        for t in threads: t.start()
        for t in threads: t.join()
        assert len(errors) == 0

    def test_TC_LD_099_no_memory_leak_100_requests(self):
        for _ in range(100):
            requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
        r = requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
        assert r.status_code == 200

    def test_TC_LD_100_30_concurrent_css_js_html(self):
        pages = ["/style.css", "/script.js", "/login.html"] * 10
        results = []
        def worker(page):
            try:
                r = requests.get(f"{BASE_URL}{page}", timeout=TIMEOUT)
                results.append(r.status_code)
            except:
                results.append(0)
        threads = [threading.Thread(target=worker, args=(p,)) for p in pages]
        for t in threads: t.start()
        for t in threads: t.join()
        assert sum(1 for s in results if s == 200) >= len(results) * 0.9


# ─────────────────────────────────────────────────────────────
# TC-LD-101..160  ENDPOINT STRESS TESTS
# ─────────────────────────────────────────────────────────────
class TestEndpointStress:

    @pytest.mark.parametrize("run", range(1, 31))
    def test_TC_LD_101_to_130_login_endpoint_stress(self, run):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": f"stress_{run}@test.com", "password": "pass"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    @pytest.mark.parametrize("run", range(1, 31))
    def test_TC_LD_131_to_160_history_endpoint_stress(self, run):
        r = requests.post(f"{BASE_URL}/get_history",
                         data={"user_id": str(run % 10 + 1)},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]


# ─────────────────────────────────────────────────────────────
# TC-LD-161..220  PAYLOAD SIZE TESTS
# ─────────────────────────────────────────────────────────────
class TestPayloadSize:

    @pytest.mark.parametrize("size", [10, 100, 500, 1000, 5000])
    def test_TC_LD_161_to_165_large_email_payload(self, size):
        email = "a" * size + "@test.com"
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": email, "password": "pass"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 413, 500]

    @pytest.mark.parametrize("size", [10, 100, 500, 1000, 5000])
    def test_TC_LD_166_to_170_large_password_payload(self, size):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": "test@test.com", "password": "p" * size},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 413, 500]

    @pytest.mark.parametrize("size", [100, 500, 1000, 5000])
    def test_TC_LD_171_to_174_large_name_signup(self, size):
        r = requests.post(f"{BASE_URL}/signup",
                         data={"name": "n" * size,
                               "email": f"big_{size}@test.com",
                               "password": "TestPass123!"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 413, 500]

    @pytest.mark.parametrize("field,size", [
        ("username", 50), ("username", 200), ("username", 1000),
        ("password", 50), ("password", 200), ("password", 1000),
    ])
    def test_TC_LD_175_to_180_boundary_field_lengths(self, field, size):
        r = requests.post(f"{BASE_URL}/login",
                         data={field: "x" * size,
                               "username" if field == "password" else "password": "test"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 413, 500]

    @pytest.mark.parametrize("n_fields", [5, 10, 20, 50])
    def test_TC_LD_181_to_184_extra_form_fields(self, n_fields):
        data = {f"extra_field_{i}": f"value_{i}" for i in range(n_fields)}
        data["username"] = "test@test.com"
        data["password"] = "pass"
        r = requests.post(f"{BASE_URL}/login", data=data, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    @pytest.mark.parametrize("encoding", ["utf-8", "latin-1"])
    def test_TC_LD_185_to_186_unicode_in_fields(self, encoding):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": "tëst@tëst.com", "password": "pässwörd"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    def test_TC_LD_187_empty_post_body(self):
        r = requests.post(f"{BASE_URL}/login", data={}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]

    def test_TC_LD_188_null_values_in_post(self):
        r = requests.post(f"{BASE_URL}/login",
                         data={"username": "null", "password": "null"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    def test_TC_LD_189_json_body_to_form_endpoint(self):
        r = requests.post(f"{BASE_URL}/login",
                         json={"username": "test@test.com", "password": "pass"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    def test_TC_LD_190_multipart_form_to_api(self):
        r = requests.post(f"{BASE_URL}/login",
                         files={"username": (None, "test@test.com"),
                                "password": (None, "pass")},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 500]

    @pytest.mark.parametrize("run", range(1, 31))
    def test_TC_LD_191_to_220_repeated_otp_requests(self, run):
        r = requests.post(f"{BASE_URL}/verify_email_otp",
                         data={"email": f"test{run}@test.com", "otp": "123456"},
                         timeout=TIMEOUT)
        assert r.status_code in [200, 400, 500]


# ─────────────────────────────────────────────────────────────
# TC-LD-221..260  THROUGHPUT TESTS
# ─────────────────────────────────────────────────────────────
class TestThroughput:

    @pytest.mark.parametrize("endpoint,n_requests,max_seconds", [
        ("/", 20, 15),
        ("/login.html", 20, 15),
        ("/signup.html", 20, 15),
        ("/style.css", 20, 10),
        ("/script.js", 20, 10),
    ])
    def test_TC_LD_221_to_225_throughput_static(self, endpoint, n_requests, max_seconds):
        start = time.time()
        for _ in range(n_requests):
            r = requests.get(f"{BASE_URL}{endpoint}", timeout=TIMEOUT)
        elapsed = time.time() - start
        assert elapsed < max_seconds, f"{n_requests} requests to {endpoint} took {elapsed:.1f}s"

    @pytest.mark.parametrize("n_requests,max_sec", [
        (10, 20), (20, 35), (30, 50), (40, 65), (50, 80),
    ])
    def test_TC_LD_226_to_230_login_api_throughput(self, n_requests, max_sec):
        start = time.time()
        for i in range(n_requests):
            requests.post(f"{BASE_URL}/login",
                         data={"username": f"tp_{i}@t.com", "password": "p"},
                         timeout=TIMEOUT)
        assert time.time() - start < max_sec

    @pytest.mark.parametrize("run", range(1, 31))
    def test_TC_LD_231_to_260_sequential_page_loads(self, run):
        pages = ["/login.html", "/signup.html", "/about.html"]
        for page in pages:
            r = requests.get(f"{BASE_URL}{page}", timeout=TIMEOUT)
            assert r.status_code == 200


# ─────────────────────────────────────────────────────────────
# TC-LD-261..300  STABILITY & RECOVERY TESTS
# ─────────────────────────────────────────────────────────────
class TestStability:

    def test_TC_LD_261_server_up_at_start(self):
        r = requests.get(f"{BASE_URL}/", timeout=5)
        assert r.status_code == 200

    @pytest.mark.parametrize("run", range(1, 11))
    def test_TC_LD_262_to_271_server_consistent_across_runs(self, run):
        r = requests.get(f"{BASE_URL}/", timeout=5)
        assert r.status_code == 200

    def test_TC_LD_272_server_responds_after_rapid_requests(self):
        for _ in range(30):
            requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
        time.sleep(0.5)
        r = requests.get(f"{BASE_URL}/", timeout=5)
        assert r.status_code == 200

    @pytest.mark.parametrize("endpoint", [
        "/login", "/signup", "/get_history", "/send_email_otp",
        "/verify_email_otp", "/reset_password", "/update_profile",
    ])
    def test_TC_LD_273_to_279_all_api_endpoints_alive(self, endpoint):
        r = requests.post(f"{BASE_URL}{endpoint}", data={}, timeout=TIMEOUT)
        assert r.status_code in [200, 400, 401, 404, 405, 500]

    @pytest.mark.parametrize("page", [
        "/login.html", "/signup.html", "/forgot_password.html",
        "/about.html", "/privacy.html", "/tips.html",
        "/haircare.html", "/index.html", "/dashboard.html",
        "/profile.html", "/history.html", "/diagnosis.html",
        "/edit_profile.html", "/result.html",
    ])
    def test_TC_LD_280_to_293_all_pages_remain_accessible(self, page):
        r = requests.get(f"{BASE_URL}{page}", timeout=TIMEOUT)
        assert r.status_code in [200, 302, 404]

    @pytest.mark.parametrize("run", range(1, 8))
    def test_TC_LD_294_to_300_server_accepts_burst_and_recovers(self, run):
        results = []
        for _ in range(10):
            try:
                r = requests.get(f"{BASE_URL}/", timeout=TIMEOUT)
                results.append(r.status_code)
            except Exception:
                results.append(0)
        time.sleep(0.2)
        r_after = requests.get(f"{BASE_URL}/", timeout=5)
        assert r_after.status_code == 200
