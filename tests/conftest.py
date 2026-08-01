import os
import pytest

# Ensure reports directory exists
@pytest.fixture(autouse=True, scope="session")
def ensure_reports_dir():
    os.makedirs("reports", exist_ok=True)
