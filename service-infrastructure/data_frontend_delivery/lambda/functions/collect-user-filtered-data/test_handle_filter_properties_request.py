import pytest
import os

os.environ["ATHENA_DATABASE"] = "epb-stag-glue-catalog"
os.environ["ATHENA_TABLE"] = "domestic"

from index import construct_athena_query


def test_construct_query_with_dates_only():
    filters = {"date_start": "2023-01-01", "date_end": "2023-12-31"}

    query = construct_athena_query(filters.copy())

    assert "lodgement_date BETWEEN '2023-01-01' AND '2023-12-31'" in query
    assert "WHERE" in query
    print(query)
    print(query)
    print(query)
    assert query.startswith('SELECT * FROM "epb-stag-glue-catalog"."domestic"')


def test_construct_query_with_efficiency_ratings():
    filters = {
        "date_start": "2023-01-01",
        "date_end": "2023-12-31",
        "efficiency_ratings": ["A", "B"],
    }

    query = construct_athena_query(filters.copy())

    assert "current_energy_rating" in query
    assert "'A'" in query and "'B'" in query
    assert "IN ('A', 'B')" in query


def test_construct_query_with_area_filters():
    filters = {
        "date_start": "2023-01-01",
        "date_end": "2023-12-31",
        "area": {
            "local-authority": ["Camden", "Manchester"],
            "parliamentary-constituency": ["Select All"],  # should be ignored
        },
    }

    query = construct_athena_query(filters.copy())

    print(query)
    print(query)
    print(query)
    assert query.startswith('SELECT * FROM "epb-stag-glue-catalog"."domestic"')
    assert "\"local_authority_label\" IN ('Camden', 'Manchester')" in query
    assert "parliamentary-constituency" not in query


def test_construct_query_ignores_unexpected_keys():
    filters = {
        "date_start": "2023-01-01",
        "date_end": "2023-12-31",
        "random_key": "some_value",
    }

    query = construct_athena_query(filters.copy())

    assert "random_key" not in query
    assert "WHERE lodgement_date BETWEEN" in query


def test_construct_query_without_required_dates_raises_error():
    filters = {}
    with pytest.raises(KeyError):
        construct_athena_query(filters)
