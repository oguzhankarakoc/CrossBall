-- Prevent starting a new daily session after today's puzzle is already completed.

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

  IF p_mode = 'daily' AND public.user_completed_daily_today(p_user_uuid) THEN
    RAISE EXCEPTION 'daily_already_completed';
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
