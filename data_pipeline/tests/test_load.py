from pipeline.load import normalize_database_url


def test_normalize_database_url_strips_pgbouncer_param():
    url = (
        'postgresql://postgres.ref:secret@aws-0-ap-south-1.pooler.supabase.com:6543/postgres'
        '?pgbouncer=true'
    )
    assert normalize_database_url(url) == (
        'postgresql://postgres.ref:secret@aws-0-ap-south-1.pooler.supabase.com:6543/postgres'
    )


def test_normalize_database_url_keeps_other_params():
    url = 'postgresql://postgres:secret@localhost:5432/postgres?connect_timeout=10'
    assert normalize_database_url(url) == url
