import asyncio

import httpx

from app import config
from app.main import app


def _request(method, path, **kwargs):
    async def send():
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
            return await client.request(method, path, **kwargs)
    return asyncio.run(send())


def test_internal_api_requires_bearer_token(monkeypatch):
    monkeypatch.setattr(config, "INTERNAL_TOKEN", "internal-test-token-1234567890123456")
    response = _request("GET", "/models/status", params={"academy_id": "academy-test"})
    assert response.status_code == 401


def test_status_does_not_claim_training_when_database_is_unconfigured(monkeypatch, tmp_path):
    monkeypatch.setattr(config, "INTERNAL_TOKEN", "internal-test-token-1234567890123456")
    monkeypatch.setattr(config, "DATABASE_URL", "")
    monkeypatch.setattr(config, "ARTIFACT_DIR", tmp_path)
    response = _request("GET", "/models/status", params={"academy_id": "academy-test"},
                        headers={"Authorization": "Bearer internal-test-token-1234567890123456"})
    assert response.status_code == 200
    assert response.json()["fee_risk"]["status"] == "NOT_READY"
    assert response.json()["performance"]["status"] == "NOT_READY"


def test_prediction_refuses_unavailable_model(monkeypatch, tmp_path):
    monkeypatch.setattr(config, "INTERNAL_TOKEN", "internal-test-token-1234567890123456")
    monkeypatch.setattr(config, "ARTIFACT_DIR", tmp_path)
    response = _request("POST", "/predict/fee-risk", headers={"Authorization": "Bearer internal-test-token-1234567890123456"},
                        json={"academy_id": "academy-test", "features": {}})
    assert response.status_code == 409
    assert response.json()["detail"]["status"] == "NOT_READY"


def test_rollback_rejects_unavailable_version(monkeypatch, tmp_path):
    monkeypatch.setattr(config, "INTERNAL_TOKEN", "internal-test-token-1234567890123456")
    monkeypatch.setattr(config, "ARTIFACT_DIR", tmp_path)
    response = _request("POST", "/models/rollback", headers={"Authorization": "Bearer internal-test-token-1234567890123456"},
                        json={"academy_id": "academy-test", "model": "fee-risk", "version": "unknown"})
    assert response.status_code == 404
