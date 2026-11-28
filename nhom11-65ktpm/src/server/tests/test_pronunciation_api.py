import httpx
from sqlalchemy import select
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.api.routes import pronunciation as pron_route

from app.core.config import settings
from app.models.pronunciation import Attempt, PronunciationRequest, SyllableResult

def test_health_check(client):
    resp = client.get("/api/health")
    assert resp.status_code == 200

def test_pronunciation_assess_unauthorized(client):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
    )
    assert resp.status_code == 401

def test_pronunciation_assess_rejects_non_wav(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.mp3", b"fake audio content", "audio/mpeg")},
        headers=auth_headers,
    )
    assert resp.status_code == 400
    assert "WAV" in resp.json()["detail"]

def test_pronunciation_assess_rejects_ogg(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("audio.ogg", b"OggS...", "audio/ogg")},
        headers=auth_headers,
    )
    assert resp.status_code == 400

def test_pronunciation_assess_rejects_m4a(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("audio.m4a", b"ftypM4A ....", "audio/m4a")},
        headers=auth_headers,
    )
    assert resp.status_code == 400

def test_pronunciation_assess_empty_text(client, auth_headers):
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": ""},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    # FastAPI tra ve 422 Unprocessable Entity khi min_length validation fail
    assert resp.status_code == 422

def test_pronunciation_assess_without_azure_key_returns_503(client, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "")
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    # Khi chua co key Azure that, server tra ve 503 de mobile tu fallback ve offline
    assert resp.status_code == 503
    assert "chua duoc cau hinh" in resp.json()["detail"]

def test_pronunciation_assess_success_mock_azure(client, auth_headers, monkeypatch):
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "test_mock_key_123")
    monkeypatch.setattr(settings, "AZURE_SPEECH_REGION", "eastasia")

    fake_azure_response = {
        "RecognitionStatus": "Success",
        "NBest": [
            {
                "Display": "你好",
                "PronunciationAssessment": {
                    "AccuracyScore": 92.0,
                    "FluencyScore": 88.0,
                    "CompletenessScore": 100.0,
                    "PronScore": 90.0,
                },
                "Words": [
                    {
                        "Word": "你好",
                        "PronunciationAssessment": {
                            "AccuracyScore": 92.0,
                            "ErrorType": "None",
                        },
                        "Syllables": [
                            {
                                "Syllable": "nǐ",
                                "PronunciationAssessment": {"AccuracyScore": 95.0},
                                "Phonemes": [
                                    {"Phoneme": "n", "PronunciationAssessment": {"AccuracyScore": 96.0}},
                                    {"Phoneme": "i", "PronunciationAssessment": {"AccuracyScore": 94.0}},
                                ],
                            },
                            {
                                "Syllable": "hǎo",
                                "PronunciationAssessment": {"AccuracyScore": 89.0},
                                "Phonemes": [
                                    {"Phoneme": "h", "PronunciationAssessment": {"AccuracyScore": 90.0}},
                                    {"Phoneme": "ao", "PronunciationAssessment": {"AccuracyScore": 88.0}},
                                ],
                            },
                        ],
                    }
                ],
            }
        ],
    }

    class MockResponse:
        status_code = 200

        def json(self):
            return fake_azure_response

    async def mock_post(*args, **kwargs):
        return MockResponse()

    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)

    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好", "reference_pinyin": "nǐ hǎo"},
        files={"audio_file": ("test.wav", b"RIFF....WAVEfmt ....data....", "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["source"] == "online"
    assert data["overall"] == 90.0
    assert data["accuracy"] == 92.0
    assert data["fluency"] == 88.0
    assert data["completeness"] == 100.0
    assert len(data["syllables"]) == 2

    # Syllable 1: 你
    syl1 = data["syllables"][0]
    assert syl1["hanzi"] == "你"
    assert syl1["expected"] == {"initial": "n", "final": "i", "tone": 3}
    assert syl1["actual"] == {"initial": "n", "final": "i", "tone": 3}
    assert syl1["status"] == "ok"
    assert syl1["errors"] == []

    # Syllable 2: 好
    syl2 = data["syllables"][1]
    assert syl2["hanzi"] == "好"
    assert syl2["expected"] == {"initial": "h", "final": "ao", "tone": 3}
    assert syl2["status"] == "ok"


def _wav_bytes(duration_ms: int = 1000) -> bytes:
    """WAV PCM 16 kHz mono 16-bit toi gian (header 44 byte + du lieu im lang)."""
    byte_rate = 16000 * 2
    data = bytes(byte_rate * duration_ms // 1000)
    header = (
        b"RIFF" + (36 + len(data)).to_bytes(4, "little") + b"WAVE"
        + b"fmt " + (16).to_bytes(4, "little") + (1).to_bytes(2, "little") + (1).to_bytes(2, "little")
        + (16000).to_bytes(4, "little") + byte_rate.to_bytes(4, "little")
        + (2).to_bytes(2, "little") + (16).to_bytes(2, "little")
        + b"data" + len(data).to_bytes(4, "little")
    )
    return header + data


def _mock_azure(monkeypatch, status_code=200, payload=None, exc=None, text=None):
    """text != None: Azure tra body khong phai JSON (resp.json() raise)."""
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "test_mock_key_123")
    monkeypatch.setattr(settings, "AZURE_SPEECH_REGION", "eastasia")

    class MockResponse:
        def __init__(self):
            self.status_code = status_code
            self.text = text or ""

        def json(self):
            if text is not None:
                raise ValueError("not json")
            return payload

    async def mock_post(*args, **kwargs):
        if exc is not None:
            raise exc
        return MockResponse()

    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)


_AZURE_NI_HAO_TONE_ERROR = {
    "RecognitionStatus": "Success",
    "NBest": [
        {
            "Display": "你好",
            "PronunciationAssessment": {
                "AccuracyScore": 80.0, "FluencyScore": 85.0, "CompletenessScore": 100.0, "PronScore": 82.0,
            },
            "Words": [
                {
                    "Word": "你好",
                    "PronunciationAssessment": {"AccuracyScore": 80.0, "ErrorType": "None"},
                    "Syllables": [
                        {"Syllable": "nǐ", "PronunciationAssessment": {"AccuracyScore": 95.0}},
                        {"Syllable": "hào", "PronunciationAssessment": {"AccuracyScore": 65.0}},
                    ],
                }
            ],
        }
    ],
}


def test_assess_success_saves_attempt_syllables_and_request_log(client, auth_headers, db_session, monkeypatch):
    """#14 buoc 3: cham online thanh cong thi luu attempts + syllable_results + pronunciation_requests."""
    _mock_azure(monkeypatch, payload=_AZURE_NI_HAO_TONE_ERROR)

    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好", "reference_pinyin": "nǐ hǎo"},
        files={"audio_file": ("test.wav", _wav_bytes(1200), "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()

    attempts = db_session.scalars(select(Attempt)).all()
    assert len(attempts) == 1
    a = attempts[0]
    assert a.mode == "online"
    assert a.reference_text == "你好"
    assert a.reference_pinyin == "nǐ hǎo"
    assert a.overall_score == body["overall"] == 82.0
    assert a.tone_score == body["tone"]
    assert a.duration_ms == 1200

    syls = db_session.scalars(select(SyllableResult).order_by(SyllableResult.position)).all()
    assert [s.hanzi for s in syls] == ["你", "好"]
    assert all(s.attempt_id == a.id for s in syls)
    assert (syls[0].expected_tone, syls[0].actual_tone, syls[0].tone_correct) == (3, 3, True)
    # 好: doc thanh 4 thay vi thanh 3
    assert (syls[1].expected_tone, syls[1].actual_tone, syls[1].tone_correct) == (3, 4, False)
    assert syls[1].initial_correct and syls[1].final_correct

    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert len(logs) == 1
    assert logs[0].status == "success"
    assert logs[0].attempt_id == a.id
    assert logs[0].user_id == a.user_id
    assert logs[0].audio_duration_ms == 1200
    assert logs[0].raw_result["NBest"][0]["Display"] == "你好"


def test_assess_omitted_syllable_saved_as_not_correct(client, auth_headers, db_session, monkeypatch):
    payload = {
        "NBest": [{
            "Display": "你",
            "PronunciationAssessment": {"AccuracyScore": 50.0, "FluencyScore": 60.0,
                                        "CompletenessScore": 50.0, "PronScore": 50.0},
            "Words": [
                {"Word": "你", "PronunciationAssessment": {"AccuracyScore": 95.0, "ErrorType": "None"}},
                {"Word": "好", "PronunciationAssessment": {"AccuracyScore": 0.0, "ErrorType": "Omission"}},
            ],
        }],
    }
    _mock_azure(monkeypatch, payload=payload)
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好", "reference_pinyin": "nǐ hǎo"},
        files={"audio_file": ("test.wav", _wav_bytes(), "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 200, resp.text
    syls = db_session.scalars(select(SyllableResult).order_by(SyllableResult.position)).all()
    assert syls[1].actual_tone is None
    assert not (syls[1].initial_correct or syls[1].final_correct or syls[1].tone_correct)


def test_assess_azure_error_logs_failed_request_without_attempt(client, auth_headers, db_session, monkeypatch):
    _mock_azure(monkeypatch, status_code=401, payload={})
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", _wav_bytes(), "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 502
    assert db_session.scalars(select(Attempt)).all() == []
    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert [(l.status, l.attempt_id) for l in logs] == [("failed", None)]
    assert "401" in logs[0].error_message


def test_assess_azure_timeout_returns_504_and_logs(client, auth_headers, db_session, monkeypatch):
    _mock_azure(monkeypatch, exc=httpx.ReadTimeout("slow"))
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", _wav_bytes(), "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 504
    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert [l.status for l in logs] == ["timeout"]


def test_assess_without_key_does_not_write_db(client, auth_headers, db_session, monkeypatch):
    monkeypatch.setattr(settings, "AZURE_SPEECH_KEY", "")
    resp = client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好"},
        files={"audio_file": ("test.wav", _wav_bytes(), "audio/wav")},
        headers=auth_headers,
    )
    assert resp.status_code == 503
    assert db_session.scalars(select(PronunciationRequest)).all() == []


def _post_ni_hao(client, auth_headers, wav=None):
    return client.post(
        "/api/pronunciation/assess",
        data={"reference_text": "你好", "reference_pinyin": "nǐ hǎo"},
        files={"audio_file": ("test.wav", wav or _wav_bytes(), "audio/wav")},
        headers=auth_headers,
    )


def test_assess_non_json_body_returns_502_and_logs_failed(client, auth_headers, db_session, monkeypatch):
    """Review #73 muc 2: Azure tra 200 nhung body khong phai JSON."""
    _mock_azure(monkeypatch, text="<html>gateway</html>")
    resp = _post_ni_hao(client, auth_headers)
    assert resp.status_code == 502
    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert [l.status for l in logs] == ["failed"]
    assert "JSON" in logs[0].error_message


def test_assess_malformed_payload_returns_502_and_logs_failed(client, auth_headers, db_session, monkeypatch):
    """Review #73 muc 2: KeyError/TypeError khi dung syllables cung phai duoc log."""
    payload = {"NBest": [{"PronunciationAssessment": {"AccuracyScore": "abc"}, "Words": []}]}
    _mock_azure(monkeypatch, payload=payload)
    resp = _post_ni_hao(client, auth_headers)
    assert resp.status_code == 502
    assert db_session.scalars(select(Attempt)).all() == []
    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert [l.status for l in logs] == ["failed"]


def test_assess_db_error_on_save_still_returns_score(client, auth_headers, db_session, monkeypatch):
    """Review #73 muc 1: loi luu attempt khong lam mat diem; request van duoc log kem loi."""
    _mock_azure(monkeypatch, payload=_AZURE_NI_HAO_TONE_ERROR)

    def boom(*args, **kwargs):
        raise OperationalError("INSERT attempts", {}, Exception("disk full"))

    monkeypatch.setattr(pron_route, "_save_attempt", boom)
    resp = _post_ni_hao(client, auth_headers)
    assert resp.status_code == 200, resp.text
    assert resp.json()["overall"] == 82.0
    assert db_session.scalars(select(Attempt)).all() == []
    logs = db_session.scalars(select(PronunciationRequest)).all()
    assert [(l.status, l.attempt_id) for l in logs] == [("success", None)]
    assert "Khong luu duoc attempt" in logs[0].error_message


def test_assess_commit_error_does_not_hide_score_or_error_code(client, auth_headers, monkeypatch):
    """Review #73 muc 1-2: commit loi trong _log_request khong che ket qua (200) hay ma loi (504)."""

    def broken_commit(self):
        raise OperationalError("COMMIT", {}, Exception("db down"))

    monkeypatch.setattr(Session, "commit", broken_commit)

    _mock_azure(monkeypatch, payload=_AZURE_NI_HAO_TONE_ERROR)
    resp = _post_ni_hao(client, auth_headers)
    assert resp.status_code == 200, resp.text
    assert resp.json()["overall"] == 82.0

    _mock_azure(monkeypatch, exc=httpx.ReadTimeout("slow"))
    assert _post_ni_hao(client, auth_headers).status_code == 504


def test_wav_duration_skips_extra_chunks():
    """Review #73: WAV co chunk LIST truoc data van tinh dung thoi luong."""
    wav = _wav_bytes(1000)
    fmt_end = 12 + 8 + 16
    list_chunk = b"LIST" + (26).to_bytes(4, "little") + b"INFOISFT" + (14).to_bytes(4, "little") + b"Lavf60.3.100" + bytes(2)
    assert len(list_chunk) == 8 + 26
    with_list = wav[:fmt_end] + list_chunk + wav[fmt_end:]
    assert pron_route._wav_duration_ms(wav) == 1000
    assert pron_route._wav_duration_ms(with_list) == 1000
    assert pron_route._wav_duration_ms(b"not a wav file at all") is None
