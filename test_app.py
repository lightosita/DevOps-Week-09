from app import app


def test_home():
    r = app.test_client().get("/")
    assert r.status_code == 200
    assert b"DevOps Week 09" in r.data


def test_health():
    r = app.test_client().get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"
