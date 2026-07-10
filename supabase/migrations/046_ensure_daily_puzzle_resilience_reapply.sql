-- Re-apply resilient ensure_daily_puzzle (028) in case migration tracking
-- was synced without the function body reaching production.

CREATE OR REPLACE FUNCTION public.ensure_daily_puzzle(
  p_date DATE DEFAULT CURRENT_DATE,
  p_difficulty_tier TEXT DEFAULT 'hard'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_tier TEXT;
  v_tiers TEXT[] := ARRAY[
    lower(trim(COALESCE(p_difficulty_tier, 'hard'))),
    'legend',
    'hard',
    'medium',
    'easy'
  ];
  v_err TEXT;
  v_pairs INT;
BEGIN
  SELECT id INTO v_id
  FROM puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  v_pairs := public.ensure_club_relationship_graph(100);
  RAISE NOTICE 'ensure_daily_puzzle: club_relationships pairs=%', v_pairs;

  FOREACH v_tier IN ARRAY v_tiers LOOP
    BEGIN
      RETURN public.generate_puzzle(
        'daily'::puzzle_mode,
        3::SMALLINT,
        v_tier,
        p_date,
        100
      );
    EXCEPTION
      WHEN unique_violation THEN
        SELECT id INTO v_id
        FROM puzzles
        WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
        LIMIT 1;
        IF v_id IS NOT NULL THEN
          RETURN v_id;
        END IF;
      WHEN OTHERS THEN
        v_err := SQLERRM;
        RAISE NOTICE 'ensure_daily_puzzle tier % failed: %', v_tier, v_err;
    END;
  END LOOP;

  BEGIN
    RETURN public.generate_daily_puzzle_fast(p_date, 3::SMALLINT, 3, 200);
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_id
      FROM puzzles
      WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
      LIMIT 1;
      IF v_id IS NOT NULL THEN
        RETURN v_id;
      END IF;
    WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'ensure_daily_puzzle fast(3) failed: %', v_err;
  END;

  BEGIN
    RETURN public.generate_daily_puzzle_fast(p_date, 3::SMALLINT, 1, 300);
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_id
      FROM puzzles
      WHERE puzzle_date = p_date AND mode = 'daily' AND grid_size = 3
      LIMIT 1;
      IF v_id IS NOT NULL THEN
        RETURN v_id;
      END IF;
    WHEN OTHERS THEN
      v_err := SQLERRM;
      RAISE NOTICE 'ensure_daily_puzzle fast(1) failed: %', v_err;
  END;

  SELECT id INTO v_id
  FROM puzzles
  WHERE puzzle_date = p_date
    AND mode = 'daily'
    AND grid_size = 3
    AND is_published = TRUE
  LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  RAISE EXCEPTION 'ensure_daily_puzzle FAILED (pairs=%): %',
    v_pairs, COALESCE(v_err, 'no tier succeeded');
END;
$$;
