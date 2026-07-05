-- Daily puzzle rollout lifecycle: explicit generating/ready/failed states for UTC midnight refresh.

CREATE TABLE IF NOT EXISTS public.daily_puzzle_rollout (
  puzzle_date DATE PRIMARY KEY,
  status TEXT NOT NULL CHECK (status IN ('generating', 'ready', 'failed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  puzzle_id UUID REFERENCES public.puzzles(id) ON DELETE SET NULL,
  error_message TEXT,
  source TEXT NOT NULL DEFAULT 'pipeline',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_puzzle_rollout_status
  ON public.daily_puzzle_rollout (status, puzzle_date DESC);

ALTER TABLE public.daily_puzzle_rollout ENABLE ROW LEVEL SECURITY;

CREATE POLICY daily_puzzle_rollout_read ON public.daily_puzzle_rollout
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE OR REPLACE FUNCTION public.expire_stale_daily_rollout(
  p_date DATE DEFAULT CURRENT_DATE,
  p_max_generating_minutes INT DEFAULT 90
)
RETURNS public.daily_puzzle_rollout
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID;
BEGIN
  SELECT * INTO v_row
  FROM public.daily_puzzle_rollout
  WHERE puzzle_date = p_date;

  IF v_row IS NULL THEN
    RETURN NULL;
  END IF;

  IF v_row.status = 'generating'
     AND v_row.started_at < NOW() - (p_max_generating_minutes || ' minutes')::INTERVAL THEN
    UPDATE public.daily_puzzle_rollout
    SET status = 'failed',
        error_message = COALESCE(
          v_row.error_message,
          'Generation timed out after ' || p_max_generating_minutes || ' minutes'
        ),
        updated_at = NOW()
    WHERE puzzle_date = p_date
    RETURNING * INTO v_row;
  END IF;

  IF v_row.status IN ('generating', 'failed') THEN
    SELECT id INTO v_puzzle_id
    FROM public.puzzles
    WHERE puzzle_date = p_date
      AND mode = 'daily'
      AND grid_size = 3
      AND is_published = TRUE
    LIMIT 1;

    IF v_puzzle_id IS NOT NULL THEN
      RETURN public.complete_daily_puzzle_rollout(p_date, v_puzzle_id);
    END IF;
  END IF;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.begin_daily_puzzle_rollout(
  p_date DATE DEFAULT CURRENT_DATE,
  p_source TEXT DEFAULT 'pipeline'
)
RETURNS public.daily_puzzle_rollout
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID;
BEGIN
  SELECT id INTO v_puzzle_id
  FROM public.puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_puzzle_id IS NOT NULL THEN
    RETURN public.complete_daily_puzzle_rollout(p_date, v_puzzle_id, p_source);
  END IF;

  SELECT * INTO v_row
  FROM public.daily_puzzle_rollout
  WHERE puzzle_date = p_date;

  IF v_row IS NOT NULL AND v_row.status = 'ready' THEN
    RETURN v_row;
  END IF;

  IF v_row IS NOT NULL AND v_row.status = 'generating' THEN
    v_row := public.expire_stale_daily_rollout(p_date);
    IF v_row.status = 'generating' THEN
      RETURN v_row;
    END IF;
  END IF;

  INSERT INTO public.daily_puzzle_rollout (
    puzzle_date, status, started_at, completed_at, puzzle_id, error_message, source, updated_at
  )
  VALUES (p_date, 'generating', NOW(), NULL, NULL, NULL, COALESCE(p_source, 'pipeline'), NOW())
  ON CONFLICT (puzzle_date) DO UPDATE
  SET status = 'generating',
      started_at = NOW(),
      completed_at = NULL,
      puzzle_id = NULL,
      error_message = NULL,
      source = EXCLUDED.source,
      updated_at = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_daily_puzzle_rollout(
  p_date DATE DEFAULT CURRENT_DATE,
  p_puzzle_id UUID DEFAULT NULL,
  p_source TEXT DEFAULT NULL
)
RETURNS public.daily_puzzle_rollout
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID := p_puzzle_id;
BEGIN
  IF v_puzzle_id IS NULL THEN
    SELECT id INTO v_puzzle_id
    FROM public.puzzles
    WHERE puzzle_date = p_date
      AND mode = 'daily'
      AND grid_size = 3
      AND is_published = TRUE
    LIMIT 1;
  END IF;

  IF v_puzzle_id IS NULL THEN
    RAISE EXCEPTION 'complete_daily_puzzle_rollout: no published puzzle for %', p_date;
  END IF;

  INSERT INTO public.daily_puzzle_rollout (
    puzzle_date, status, started_at, completed_at, puzzle_id, error_message, source, updated_at
  )
  VALUES (
    p_date,
    'ready',
    COALESCE((SELECT started_at FROM public.daily_puzzle_rollout WHERE puzzle_date = p_date), NOW()),
    NOW(),
    v_puzzle_id,
    NULL,
    COALESCE(p_source, 'pipeline'),
    NOW()
  )
  ON CONFLICT (puzzle_date) DO UPDATE
  SET status = 'ready',
      completed_at = NOW(),
      puzzle_id = EXCLUDED.puzzle_id,
      error_message = NULL,
      source = COALESCE(EXCLUDED.source, daily_puzzle_rollout.source),
      updated_at = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.fail_daily_puzzle_rollout(
  p_date DATE DEFAULT CURRENT_DATE,
  p_error_message TEXT DEFAULT 'Daily puzzle generation failed',
  p_source TEXT DEFAULT 'pipeline'
)
RETURNS public.daily_puzzle_rollout
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.daily_puzzle_rollout;
  v_puzzle_id UUID;
BEGIN
  SELECT id INTO v_puzzle_id
  FROM public.puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_puzzle_id IS NOT NULL THEN
    RETURN public.complete_daily_puzzle_rollout(p_date, v_puzzle_id, p_source);
  END IF;

  INSERT INTO public.daily_puzzle_rollout (
    puzzle_date, status, started_at, completed_at, puzzle_id, error_message, source, updated_at
  )
  VALUES (
    p_date,
    'failed',
    COALESCE((SELECT started_at FROM public.daily_puzzle_rollout WHERE puzzle_date = p_date), NOW()),
    NOW(),
    NULL,
    LEFT(COALESCE(p_error_message, 'Daily puzzle generation failed'), 500),
    COALESCE(p_source, 'pipeline'),
    NOW()
  )
  ON CONFLICT (puzzle_date) DO UPDATE
  SET status = 'failed',
      completed_at = NOW(),
      error_message = EXCLUDED.error_message,
      source = COALESCE(EXCLUDED.source, daily_puzzle_rollout.source),
      updated_at = NOW()
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_daily_puzzle_rollout(
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

GRANT EXECUTE ON FUNCTION public.begin_daily_puzzle_rollout(DATE, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.complete_daily_puzzle_rollout(DATE, UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fail_daily_puzzle_rollout(DATE, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_daily_puzzle_rollout(DATE) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.expire_stale_daily_rollout(DATE, INT) TO service_role;
