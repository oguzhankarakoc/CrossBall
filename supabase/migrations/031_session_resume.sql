-- Resume in-progress puzzle sessions instead of creating duplicates.
-- Provides authoritative progress snapshot for client rehydration.

CREATE OR REPLACE FUNCTION public.start_puzzle_session(
  p_user_uuid TEXT,
  p_puzzle_id UUID,
  p_mode puzzle_mode,
  p_grid_size SMALLINT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_session_id UUID;
BEGIN
  SELECT id INTO v_user_id
  FROM public.users
  WHERE user_uuid = p_user_uuid
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.puzzles p WHERE p.id = p_puzzle_id AND p.is_published = TRUE
  ) THEN
    RAISE EXCEPTION 'puzzle_not_found';
  END IF;

  -- Resume the latest active session for this user, puzzle, and mode.
  SELECT ps.id INTO v_session_id
  FROM public.puzzle_sessions ps
  WHERE ps.user_id = v_user_id
    AND ps.puzzle_id = p_puzzle_id
    AND ps.mode = p_mode
    AND ps.status = 'active'
  ORDER BY ps.started_at DESC
  LIMIT 1;

  IF v_session_id IS NOT NULL THEN
    RETURN v_session_id;
  END IF;

  -- Abandon stale active sessions for the same mode on a different puzzle.
  UPDATE public.puzzle_sessions ps
  SET status = 'abandoned',
      completed_at = NOW()
  WHERE ps.user_id = v_user_id
    AND ps.mode = p_mode
    AND ps.status = 'active'
    AND ps.puzzle_id <> p_puzzle_id;

  v_session_id := gen_random_uuid();

  INSERT INTO public.puzzle_sessions (
    id, user_id, puzzle_id, mode, grid_size, status
  )
  VALUES (v_session_id, v_user_id, p_puzzle_id, p_mode, p_grid_size, 'active');

  RETURN v_session_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_session_progress(
  p_session_id UUID,
  p_user_uuid TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.puzzle_sessions;
  v_user_id UUID;
BEGIN
  SELECT ps.* INTO v_row
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  IF v_row.id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  IF p_user_uuid IS NOT NULL THEN
    SELECT u.id INTO v_user_id
    FROM public.users u
    WHERE u.user_uuid = p_user_uuid
    LIMIT 1;

    IF v_user_id IS NULL OR v_user_id <> v_row.user_id THEN
      RAISE EXCEPTION 'session_forbidden';
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'session_id', v_row.id,
    'puzzle_id', v_row.puzzle_id,
    'mode', v_row.mode,
    'status', v_row.status,
    'started_at', v_row.started_at,
    'answers', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'puzzle_cell_id', a.puzzle_cell_id,
            'row_index', pc.row_index,
            'col_index', pc.col_index,
            'player_id', a.player_id,
            'player_name', p.name,
            'usage_percentage', a.usage_percentage,
            'rarity_score', a.rarity_score,
            'is_correct', a.is_correct
          )
          ORDER BY pc.row_index, pc.col_index
        )
        FROM public.answers a
        JOIN public.puzzle_cells pc ON pc.id = a.puzzle_cell_id
        JOIN public.players p ON p.id = a.player_id
        WHERE a.session_id = v_row.id
          AND a.is_correct = TRUE
      ),
      '[]'::jsonb
    ),
    'hints', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'puzzle_cell_id', sh.puzzle_cell_id,
            'row_index', pc.row_index,
            'col_index', pc.col_index,
            'hint_type', sh.hint_type,
            'hint_value', sh.hint_value
          )
          ORDER BY sh.created_at
        )
        FROM public.session_hints sh
        JOIN public.puzzle_cells pc ON pc.id = sh.puzzle_cell_id
        WHERE sh.session_id = v_row.id
      ),
      '[]'::jsonb
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_session_progress(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_session_progress(UUID, TEXT) TO service_role;
