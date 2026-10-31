from datetime import date
from unittest.mock import MagicMock, patch

from app.data.extractor import _connect, extract_fee_rows, extract_performance_rows


@patch("app.data.extractor.psycopg.connect")
def test_prisma_schema_url_is_translated_to_search_path(connect):
    _connect("postgresql://ml:private@localhost:5432/taleemplus?schema=public&sslmode=require")
    args, kwargs = connect.call_args
    assert args[0] == "postgresql://ml:private@localhost:5432/taleemplus?sslmode=require"
    assert kwargs["options"] == "-c search_path=public"


@patch("app.data.extractor.psycopg.connect")
def test_fee_extract_is_academy_scoped_and_does_not_return_identifiers(connect):
    cursor = MagicMock()
    cursor.fetchall.return_value = [{
        "id": "internal-row", "student_id": "internal-student",
        "issue_date": date(2025, 1, 1), "due_date": date(2025, 1, 10),
        "amount": 100.0, "outstanding_snapshot": 100.0, "status": "PAID", "paid_date": date(2025, 1, 15),
        "prior_late_count": 1, "prior_paid_count": 2, "prior_ontime_count": 1,
        "prior_delay_avg": 2.0, "att_count": 10, "att_present": 8,
    }]
    connection = MagicMock()
    connection.cursor.return_value.__enter__.return_value = cursor
    connect.return_value.__enter__.return_value = connection

    rows = extract_fee_rows("postgresql://unused", "academy-test", date(2025, 2, 1))

    assert cursor.execute.call_args.args[1] == ("academy-test",)
    sql = cursor.execute.call_args.args[0]
    assert 'f."academyId"=%s' in sql
    assert 'p."issueDate" < f."issueDate"' in sql
    assert 'p."paidAt" < f."issueDate"' in sql
    assert 'a."recordedAt" < f."issueDate"' in sql
    assert len(rows) == 1
    assert rows[0]["label"] == 1
    assert rows[0]["attendance_pct"] == 80
    assert rows[0]["consistency"] == 0.5
    assert rows[0]["outstanding"] == 100.0
    assert "student_id" not in rows[0] and "id" not in rows[0]


@patch("app.data.extractor.psycopg.connect")
def test_fee_rows_without_reliable_payment_date_are_excluded(connect):
    cursor = MagicMock()
    cursor.fetchall.return_value = [{
        "id": "row", "student_id": "student", "issue_date": date(2025, 1, 1),
        "due_date": date(2025, 1, 10), "amount": 100.0, "outstanding_snapshot": 100.0, "status": "PAID",
        "paid_date": None, "prior_late_count": 0, "prior_paid_count": 0,
        "prior_ontime_count": 0, "prior_delay_avg": None, "att_count": 0,
        "att_present": 0,
    }]
    connection = MagicMock()
    connection.cursor.return_value.__enter__.return_value = cursor
    connect.return_value.__enter__.return_value = connection
    assert extract_fee_rows("postgresql://unused", "academy-test", date(2025, 2, 1)) == []


@patch("app.data.extractor.psycopg.connect")
def test_performance_query_uses_only_prior_marks_and_strips_student_id(connect):
    cursor = MagicMock()
    cursor.fetchall.return_value = [{
        "student_id": "private-id", "target_date": date(2025, 2, 1),
        "target": 75, "prior_avg": 70, "prior_count": 2, "attendance_pct": 90,
    }]
    connection = MagicMock()
    connection.cursor.return_value.__enter__.return_value = cursor
    connect.return_value.__enter__.return_value = connection
    rows = extract_performance_rows("postgresql://unused", "academy-test")
    sql = cursor.execute.call_args.args[0]
    assert 'pq."testDate" < q."testDate"' in sql
    assert 'p."updatedAt" < q."testDate"' in sql
    assert 'a."recordedAt" < q."testDate"' in sql
    assert 'm."academyId"=%s' in sql
    assert "student_id" not in rows[0]
    assert rows[0]["target"] == 75.0
