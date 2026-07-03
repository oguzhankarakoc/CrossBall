-- Seed today's daily puzzle and repoint stale club references on existing puzzles.

UPDATE puzzle_row_clubs prc
SET club_id = canonical.id
FROM clubs stale
JOIN clubs canonical
  ON public.canonical_club_slug(canonical.slug) = public.canonical_club_slug(stale.slug)
WHERE prc.club_id = stale.id
  AND canonical.id <> stale.id
  AND canonical.slug = public.canonical_club_slug(stale.slug);

UPDATE puzzle_col_clubs pcc
SET club_id = canonical.id
FROM clubs stale
JOIN clubs canonical
  ON public.canonical_club_slug(canonical.slug) = public.canonical_club_slug(stale.slug)
WHERE pcc.club_id = stale.id
  AND canonical.id <> stale.id
  AND canonical.slug = public.canonical_club_slug(stale.slug);

DO $seed$
DECLARE
  v_puzzle_id UUID;
  v_slug TEXT;
  v_club_id UUID;
  row_slugs TEXT[] := ARRAY['barcelona', 'chelsea', 'real-madrid'];
  col_slugs TEXT[] := ARRAY['manchester-united', 'bayern-munich', 'juventus'];
  r INT;
  c INT;
BEGIN
  INSERT INTO puzzles (puzzle_date, mode, grid_size, difficulty, is_published)
  VALUES (CURRENT_DATE, 'daily', 3, 0.42, TRUE)
  ON CONFLICT (puzzle_date, mode, grid_size)
  DO UPDATE SET is_published = TRUE, difficulty = EXCLUDED.difficulty
  RETURNING id INTO v_puzzle_id;

  IF v_puzzle_id IS NULL THEN
    SELECT id INTO v_puzzle_id
    FROM puzzles
    WHERE puzzle_date = CURRENT_DATE AND mode = 'daily' AND grid_size = 3
    LIMIT 1;
  END IF;

  DELETE FROM puzzle_row_clubs WHERE puzzle_id = v_puzzle_id;
  DELETE FROM puzzle_col_clubs WHERE puzzle_id = v_puzzle_id;
  DELETE FROM puzzle_cells WHERE puzzle_id = v_puzzle_id;

  FOR r IN 0..2 LOOP
    v_slug := row_slugs[r + 1];
    SELECT id INTO v_club_id FROM clubs WHERE slug = v_slug LIMIT 1;
    IF v_club_id IS NOT NULL THEN
      INSERT INTO puzzle_row_clubs (puzzle_id, row_index, club_id)
      VALUES (v_puzzle_id, r, v_club_id);
    END IF;
  END LOOP;

  FOR c IN 0..2 LOOP
    v_slug := col_slugs[c + 1];
    SELECT id INTO v_club_id FROM clubs WHERE slug = v_slug LIMIT 1;
    IF v_club_id IS NOT NULL THEN
      INSERT INTO puzzle_col_clubs (puzzle_id, col_index, club_id)
      VALUES (v_puzzle_id, c, v_club_id);
    END IF;
  END LOOP;

  FOR r IN 0..2 LOOP
    FOR c IN 0..2 LOOP
      INSERT INTO puzzle_cells (puzzle_id, row_index, col_index, valid_answer_count, difficulty)
      VALUES (v_puzzle_id, r, c, 12, 0.42);
    END LOOP;
  END LOOP;
END;
$seed$;

SELECT public.refresh_player_club_intersections();
