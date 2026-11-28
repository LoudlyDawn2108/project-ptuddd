from scripts.load_content import DATA_DIR, load_content, read_lesson_files


def test_list_lessons_returns_contract_and_filters_since_version(client, db_session):
    expected_count = len(read_lesson_files(DATA_DIR))
    lessons = load_content(db_session)
    db_session.commit()
    changed = lessons[0]
    changed.content_version = 2
    db_session.commit()

    all_response = client.get("/api/lessons")
    assert all_response.status_code == 200, all_response.text
    all_lessons = all_response.json()
    assert len(all_lessons) == expected_count

    first = all_lessons[0]
    assert first["serverId"] == lessons[0].id
    assert first["id"] == "hsk1-greetings-01"
    assert first["level"] == "HSK1"
    assert first["schemaVersion"] == 1
    assert first["vocabulary"][0]["id"] == "ni-hao"
    assert first["grammarPoints"]
    assert first["aiScenario"]["openingLine"]

    changed_response = client.get("/api/lessons?since_version=1")
    assert changed_response.status_code == 200, changed_response.text
    assert [item["id"] for item in changed_response.json()] == [changed.code]

    no_changes = client.get("/api/lessons?since_version=2")
    assert no_changes.status_code == 200
    assert no_changes.json() == []


def test_get_lesson_by_server_id_and_404(client, db_session):
    lesson = load_content(db_session)[0]
    db_session.commit()

    response = client.get(f"/api/lessons/{lesson.id}")
    assert response.status_code == 200, response.text
    payload = response.json()
    assert payload["serverId"] == lesson.id
    assert payload["id"] == lesson.code

    missing = client.get("/api/lessons/99999")
    assert missing.status_code == 404
    assert missing.json()["detail"] == "Không tìm thấy bài học"


def test_since_version_must_be_nonnegative(client):
    response = client.get("/api/lessons?since_version=-1")
    assert response.status_code == 422
