-- Competitive integrity: cell binding, server timing, atomic completion, suspicion heuristics.

-- =============================================================================
-- 1. Validate puzzle cell belongs to session + row/col clubs match
-- =============================================================================

CREATE OR REPLACE FUNCTION public.assert_puzzle_cell_context(
  p_session_id UUID,
  p_user_uuid TEXT,
  p_puzzle_cell_id UUID,
  p_row_club_ref TEXT,
  p_col_club_ref TEXT
)
RETURNS public.puzzle_cells
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session public.puzzle_sessions;
  v_cell public.puzzle_cells;
  v_row_club_id UUID;
  v_col_club_id UUID;
BEGIN
  v_session := public.assert_active_session(p_session_id, p_user_uuid);

  SELECT pc.* INTO v_cell
  FROM public.puzzle_cells pc
  WHERE pc.id = p_puzzle_cell_id;

  IF v_cell.id IS NULL THEN
    RAISE EXCEPTION 'cell_not_found';
  END IF;

  IF v_cell.puzzle_id <> v_session.puzzle_id THEN
    RAISE EXCEPTION 'cell_puzzle_mismatch';
  END IF;

  SELECT prc.club_id INTO v_row_club_id
  FROM public.puzzle_row_clubs prc
  WHERE prc.puzzle_id = v_session.puzzle_id
    AND prc.row_index = v_cell.row_index;

  SELECT pcc.club_id INTO v_col_club_id
  FROM public.puzzle_col_clubs pcc
  WHERE pcc.puzzle_id = v_session.puzzle_id
    AND pcc.col_index = v_cell.col_index;

  IF v_row_club_id IS NULL OR v_col_club_id IS NULL THEN
    RAISE EXCEPTION 'cell_clubs_missing';
  END IF;

  IF NOT (v_row_club_id = ANY(public.club_ids_equivalent_to(p_row_club_ref))) THEN
    RAISE EXCEPTION 'row_club_mismatch';
  END IF;

  IF NOT (v_col_club_id = ANY(public.club_ids_equivalent_to(p_col_club_ref))) THEN
    RAISE EXCEPTION 'col_club_mismatch';
  END IF;

  RETURN v_cell;
END;
$$;

-- =============================================================================
-- 2. Server-authoritative per-answer response time
-- =============================================================================

CREATE OR REPLACE FUNCTION public.compute_answer_response_time_ms(
  p_session_id UUID,
  p_puzzle_cell_id UUID DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_started_at TIMESTAMPTZ;
  v_anchor TIMESTAMPTZ;
  v_ms BIGINT;
BEGIN
  SELECT ps.started_at INTO v_started_at
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  IF v_started_at IS NULL THEN
    RETURN 60000;
  END IF;

  SELECT GREATEST(
    v_started_at,
    COALESCE(
      (
        SELECT MAX(ts)
        FROM (
          SELECT a.created_at AS ts
          FROM public.answers a
          WHERE a.session_id = p_session_id
          UNION ALL
          SELECT sh.created_at
          FROM public.session_hints sh
          WHERE sh.session_id = p_session_id
        ) events
      ),
      v_started_at
    )
  ) INTO v_anchor;

  v_ms := (EXTRACT(EPOCH FROM (NOW() - v_anchor)) * 1000)::BIGINT;
  RETURN GREATEST(1000, LEAST(v_ms, 300000))::INT;
END;
$$;

-- =============================================================================
-- 3. Track wrong answers server-side
-- =============================================================================

CREATE OR REPLACE FUNCTION public.increment_session_mistakes(
  p_session_id UUID,
  p_user_uuid TEXT
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_mistakes INT;
BEGIN
  PERFORM public.assert_active_session(p_session_id, p_user_uuid);

  UPDATE public.puzzle_sessions ps
  SET mistakes = COALESCE(ps.mistakes, 0) + 1
  WHERE ps.id = p_session_id
  RETURNING ps.mistakes INTO v_mistakes;

  RETURN COALESCE(v_mistakes, 0);
END;
$$;

-- =============================================================================
-- 4. Server-side integrity evaluation (never trust client flags)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.evaluate_session_integrity(p_session_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session public.puzzle_sessions;
  v_duration_ms BIGINT;
  v_correct INT;
  v_expected INT;
  v_fast_answers INT;
  v_hints INT;
  v_reasons TEXT[] := ARRAY[]::TEXT[];
  v_suspicious BOOLEAN := FALSE;
BEGIN
  SELECT ps.* INTO v_session
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id;

  IF v_session.id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  v_expected := v_session.grid_size * v_session.grid_size;
  v_duration_ms := (EXTRACT(EPOCH FROM (NOW() - v_session.started_at)) * 1000)::BIGINT;

  SELECT COUNT(*)::INT INTO v_correct
  FROM public.answers a
  WHERE a.session_id = p_session_id AND a.is_correct = TRUE;

  SELECT COUNT(*)::INT INTO v_fast_answers
  FROM public.answers a
  WHERE a.session_id = p_session_id
    AND a.is_correct = TRUE
    AND COALESCE(a.response_time_ms, 60000) < 800;

  SELECT COUNT(*)::INT INTO v_hints
  FROM public.session_hints sh
  WHERE sh.session_id = p_session_id;

  IF v_correct > 0 AND v_duration_ms < (v_correct * 2000) THEN
    v_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'impossibly_fast_session');
  END IF;

  IF v_fast_answers >= GREATEST(2, v_correct) AND v_correct >= 2 THEN
    v_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'impossibly_fast_answers');
  END IF;

  IF v_correct > v_expected THEN
    v_suspicious := TRUE;
    v_reasons := array_append(v_reasons, 'too_many_correct');
  END IF;

  RETURN jsonb_build_object(
    'is_suspicious', v_suspicious,
    'reasons', to_jsonb(v_reasons),
    'server_duration_ms', v_duration_ms,
    'server_mistakes', COALESCE(v_session.mistakes, 0),
    'correct_count', v_correct,
    'expected_cells', v_expected,
    'hints_used', v_hints,
    'grid_size', v_session.grid_size,
    'mode', v_session.mode
  );
END;
$$;

-- =============================================================================
-- 5. Atomic session finalization (prevents double-reward races)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.finalize_puzzle_session(
  p_session_id UUID,
  p_user_uuid TEXT,
  p_finished_early BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session public.puzzle_sessions;
  v_user_id UUID;
  v_metrics JSONB;
  v_integrity JSONB;
  v_final_score NUMERIC;
  v_hints INT;
  v_correct INT;
  v_expected INT;
  v_rare INT;
  v_legendary INT;
  v_mythic INT;
  v_is_perfect BOOLEAN;
  v_suspicious BOOLEAN;
  v_duration_ms BIGINT;
  v_mistakes INT;
  v_status public.session_status;
  v_updated INT;
BEGIN
  SELECT u.id INTO v_user_id
  FROM public.users u
  WHERE u.user_uuid = p_user_uuid
  LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  SELECT ps.* INTO v_session
  FROM public.puzzle_sessions ps
  WHERE ps.id = p_session_id
  FOR UPDATE;

  IF v_session.id IS NULL THEN
    RAISE EXCEPTION 'session_not_found';
  END IF;

  IF v_session.user_id <> v_user_id THEN
    RAISE EXCEPTION 'session_forbidden';
  END IF;

  IF v_session.status = 'completed' OR v_session.status = 'suspicious' THEN
    RETURN jsonb_build_object(
      'ok', TRUE,
      'already_completed', TRUE,
      'session_id', p_session_id,
      'final_score', v_session.final_score,
      'status', v_session.status
    );
  END IF;

  IF v_session.status <> 'active' THEN
    RAISE EXCEPTION 'session_not_active';
  END IF;

  v_metrics := public.compute_session_score(p_session_id);
  v_integrity := public.evaluate_session_integrity(p_session_id);

  v_final_score := COALESCE((v_metrics->>'final_score')::NUMERIC, 0);
  v_hints := COALESCE((v_metrics->>'hints_used')::INT, 0);
  v_correct := COALESCE((v_metrics->>'correct_count')::INT, 0);
  v_rare := COALESCE((v_metrics->>'rare_count')::INT, 0);
  v_legendary := COALESCE((v_metrics->>'legendary_count')::INT, 0);
  v_mythic := COALESCE((v_metrics->>'mythic_count')::INT, 0);
  v_expected := v_session.grid_size * v_session.grid_size;
  v_duration_ms := COALESCE((v_integrity->>'server_duration_ms')::BIGINT, 0);
  v_mistakes := COALESCE((v_integrity->>'server_mistakes')::INT, 0);
  v_suspicious := COALESCE((v_integrity->>'is_suspicious')::BOOLEAN, FALSE);

  IF v_session.mode IN ('daily', 'challenge') AND v_correct < v_expected THEN
    RAISE EXCEPTION 'incomplete_session';
  END IF;

  IF v_session.mode IN ('practice', 'timeline') AND NOT p_finished_early AND v_correct < v_expected THEN
    RAISE EXCEPTION 'incomplete_session';
  END IF;

  v_is_perfect := (v_hints = 0 AND v_mistakes = 0 AND v_correct = v_expected);
  v_status := CASE WHEN v_suspicious THEN 'suspicious'::public.session_status ELSE 'completed'::public.session_status END;

  UPDATE public.puzzle_sessions ps
  SET final_score = v_final_score,
      hints_used = v_hints,
      mistakes = v_mistakes,
      total_duration_ms = v_duration_ms,
      is_suspicious = v_suspicious,
      status = v_status,
      completed_at = NOW()
  WHERE ps.id = p_session_id
    AND ps.status = 'active';

  GET DIAGNOSTICS v_updated = ROW_COUNT;

  IF v_updated = 0 THEN
    SELECT ps.* INTO v_session
    FROM public.puzzle_sessions ps
    WHERE ps.id = p_session_id;

    RETURN jsonb_build_object(
      'ok', TRUE,
      'already_completed', TRUE,
      'session_id', p_session_id,
      'final_score', v_session.final_score,
      'status', v_session.status
    );
  END IF;

  RETURN jsonb_build_object(
    'ok', TRUE,
    'already_completed', FALSE,
    'session_id', p_session_id,
    'final_score', v_final_score,
    'hints_used', v_hints,
    'mistakes', v_mistakes,
    'correct_count', v_correct,
    'rare_count', v_rare,
    'legendary_count', v_legendary,
    'mythic_count', v_mythic,
    'is_perfect', v_is_perfect,
    'is_suspicious', v_suspicious,
    'integrity', v_integrity,
    'server_duration_ms', v_duration_ms,
    'mode', v_session.mode,
    'status', v_status
  );
END;
$$;

-- =============================================================================
-- 6. Session TTL + daily expiry on resume
-- =============================================================================

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
  v_puzzle_date DATE;
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

  SELECT p.puzzle_date INTO v_puzzle_date
  FROM public.puzzles p
  WHERE p.id = p_puzzle_id;

  -- Expire stale actives (>24h) and daily sessions from previous dates.
  UPDATE public.puzzle_sessions ps
  SET status = 'abandoned',
      completed_at = NOW()
  WHERE ps.user_id = v_user_id
    AND ps.status = 'active'
    AND (
      ps.started_at < NOW() - INTERVAL '24 hours'
      OR (ps.mode = 'daily' AND v_puzzle_date IS NOT NULL AND v_puzzle_date <> (NOW() AT TIME ZONE 'UTC')::DATE)
    );

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

-- Include response_time_ms in progress snapshot
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
    'mistakes', COALESCE(v_row.mistakes, 0),
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
            'response_time_ms', a.response_time_ms,
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

-- =============================================================================
-- 7. Close player oracle RPC from direct client access
-- =============================================================================

REVOKE EXECUTE ON FUNCTION public.get_intersection_players(TEXT, TEXT) FROM anon, authenticated;

-- =============================================================================
-- Grants
-- =============================================================================

REVOKE ALL ON FUNCTION public.assert_puzzle_cell_context(UUID, TEXT, UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.compute_answer_response_time_ms(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.increment_session_mistakes(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.evaluate_session_integrity(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.finalize_puzzle_session(UUID, TEXT, BOOLEAN) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.assert_puzzle_cell_context(UUID, TEXT, UUID, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.compute_answer_response_time_ms(UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.increment_session_mistakes(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.evaluate_session_integrity(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.finalize_puzzle_session(UUID, TEXT, BOOLEAN) TO service_role;
