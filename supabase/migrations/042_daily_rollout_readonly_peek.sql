-- Fix daily rollout status reads failing with "cannot execute UPDATE in a read-only transaction".
-- get_daily_puzzle_rollout was STABLE but called expire_stale_daily_rollout (UPDATE).
-- status_only checks use peek_daily_puzzle_rollout (read-only).

CREATE OR REPLACE FUNCTION public.peek_daily_puzzle_rollout(
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID;
  v_elapsed_seconds INT;
BEGIN
  SELECT * INTO v_row
  FROM public.daily_puzzle_rollout
  WHERE puzzle_date = p_date;

  SELECT id INTO v_puzzle_id
  FROM public.puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_puzzle_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'puzzle_date', p_date,
      'status', 'ready',
      'puzzle_id', v_puzzle_id,
      'started_at', v_row.started_at,
      'completed_at', COALESCE(v_row.completed_at, NOW()),
      'elapsed_seconds', EXTRACT(EPOCH FROM (COALESCE(v_row.completed_at, NOW()) - COALESCE(v_row.started_at, NOW())))::INT,
      'source', COALESCE(v_row.source, 'unknown'),
      'retry_after', 0
    );
  END IF;

  IF v_row IS NULL THEN
    IF p_date = CURRENT_DATE THEN
      RETURN jsonb_build_object(
        'puzzle_date', p_date,
        'status', 'pending',
        'started_at', NULL,
        'completed_at', NULL,
        'elapsed_seconds', 0,
        'source', NULL,
        'retry_after', 30
      );
    END IF;

    RETURN jsonb_build_object(
      'puzzle_date', p_date,
      'status', 'unavailable',
      'retry_after', 60
    );
  END IF;

  v_elapsed_seconds := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - v_row.started_at))::INT
  );

  RETURN jsonb_build_object(
    'puzzle_date', p_date,
    'status', v_row.status,
    'started_at', v_row.started_at,
    'completed_at', v_row.completed_at,
    'elapsed_seconds', v_elapsed_seconds,
    'error_message', v_row.error_message,
    'source', v_row.source,
    'retry_after', CASE v_row.status
      WHEN 'generating' THEN 30
      WHEN 'failed' THEN 60
      ELSE 0
    END
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_daily_puzzle_rollout(
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID;
  v_elapsed_seconds INT;
BEGIN
  v_row := public.expire_stale_daily_rollout(p_date);

  SELECT id INTO v_puzzle_id
  FROM public.puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_puzzle_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'puzzle_date', p_date,
      'status', 'ready',
      'puzzle_id', v_puzzle_id,
      'started_at', v_row.started_at,
      'completed_at', COALESCE(v_row.completed_at, NOW()),
      'elapsed_seconds', EXTRACT(EPOCH FROM (COALESCE(v_row.completed_at, NOW()) - COALESCE(v_row.started_at, NOW())))::INT,
      'source', COALESCE(v_row.source, 'unknown'),
      'retry_after', 0
    );
  END IF;

  IF v_row IS NULL THEN
    IF p_date = CURRENT_DATE THEN
      RETURN jsonb_build_object(
        'puzzle_date', p_date,
        'status', 'pending',
        'started_at', NULL,
        'completed_at', NULL,
        'elapsed_seconds', 0,
        'source', NULL,
        'retry_after', 30
      );
    END IF;

    RETURN jsonb_build_object(
      'puzzle_date', p_date,
      'status', 'unavailable',
      'retry_after', 60
    );
  END IF;

  v_elapsed_seconds := GREATEST(
    0,
    EXTRACT(EPOCH FROM (NOW() - v_row.started_at))::INT
  );

  RETURN jsonb_build_object(
    'puzzle_date', p_date,
    'status', v_row.status,
    'started_at', v_row.started_at,
    'completed_at', v_row.completed_at,
    'elapsed_seconds', v_elapsed_seconds,
    'error_message', v_row.error_message,
    'source', v_row.source,
    'retry_after', CASE v_row.status
      WHEN 'generating' THEN 30
      WHEN 'failed' THEN 60
      ELSE 0
    END
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.peek_daily_puzzle_rollout(DATE) TO anon, authenticated, service_role;
