import { createClient } from 'npm:@supabase/supabase-js@2'
import {
  checkRateLimit,
  clientIp,
  rateLimitKey,
  rateLimitResponse,
} from '../_shared/rate_limit.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

async function bestEffortRpc(
  supabase: ReturnType<typeof createClient>,
  fn: string,
  args: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase.rpc(fn, args)
  if (error) {
    console.warn(`${fn} best-effort failed:`, error.message)
  }
}

function tierFromUsage(pct: number): string {
  if (pct > 50) return 'common'
  if (pct > 25) return 'rare'
  if (pct > 10) return 'epic'
  if (pct > 3) return 'legendary'
  return 'mythic'
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json()
    const {
      row_club_id,
      col_club_id,
      player_id,
      puzzle_cell_id,
      session_id,
    } = body
    const userUuid = req.headers.get('x-user-uuid') ?? body.user_uuid ?? ''

    if (!userUuid) {
      return new Response(JSON.stringify({ error: 'user_uuid_required' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const rl = checkRateLimit(
      rateLimitKey(userUuid, clientIp(req), 'validate-answer'),
      120,
      60_000,
    )
    if (!rl.allowed) {
      return rateLimitResponse(rl.retryAfterSec!, corsHeaders)
    }

    if (
      !session_id ||
      !UUID_RE.test(String(session_id)) ||
      !puzzle_cell_id ||
      !UUID_RE.test(String(puzzle_cell_id)) ||
      !player_id ||
      !UUID_RE.test(String(player_id)) ||
      !row_club_id ||
      !col_club_id
    ) {
      return new Response(JSON.stringify({ error: 'invalid_request' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { error: cellError } = await supabase.rpc('assert_puzzle_cell_context', {
      p_session_id: session_id,
      p_user_uuid: userUuid,
      p_puzzle_cell_id: puzzle_cell_id,
      p_row_club_ref: String(row_club_id),
      p_col_club_ref: String(col_club_id),
    })

    if (cellError) {
      const msg = cellError.message ?? String(cellError)
      const status = msg.includes('forbidden') || msg.includes('mismatch') ? 403 : 409
      return new Response(JSON.stringify({ error: msg }), {
        status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: existing } = await supabase
      .from('answers')
      .select('id, is_correct, player_id')
      .eq('session_id', session_id)
      .eq('puzzle_cell_id', puzzle_cell_id)
      .maybeSingle()

    if (existing?.is_correct) {
      const { data: player } = await supabase
        .from('players')
        .select('name')
        .eq('id', existing.player_id)
        .maybeSingle()

      return new Response(
        JSON.stringify({
          correct: true,
          player_name: player?.name ?? '',
          usage_percentage: 0,
          rarity_tier: 'common',
          rarity_score: 0,
          already_used_in_session: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const [{ data: correct, error: validateError }, playerResult] = await Promise.all([
      supabase.rpc('validate_player_intersection', {
        p_player_id: player_id,
        p_row_club_ref: String(row_club_id),
        p_col_club_ref: String(col_club_id),
      }),
      supabase.from('players').select('name').eq('id', player_id).maybeSingle(),
    ])

    if (validateError) {
      console.error('validate_player_intersection failed:', validateError.message)
    }

    const isCorrect = !validateError && correct === true
    const playerName = playerResult.data?.name ?? ''

    let usagePercentage = 0
    let rarityScore = 0

    if (!isCorrect) {
      await bestEffortRpc(supabase, 'increment_session_mistakes', {
        p_session_id: session_id,
        p_user_uuid: userUuid,
      })
    } else {
      const [{ data: rarity }, { data: serverResponseMs, error: timingError }] =
        await Promise.all([
          supabase
            .from('rarity_stats')
            .select('usage_percentage')
            .eq('puzzle_cell_id', puzzle_cell_id)
            .eq('player_id', player_id)
            .maybeSingle(),
          supabase.rpc('compute_answer_response_time_ms', {
            p_session_id: session_id,
            p_puzzle_cell_id: puzzle_cell_id,
          }),
        ])

      if (timingError) {
        console.error('compute_answer_response_time_ms failed:', timingError.message)
      }

      usagePercentage = rarity?.usage_percentage ?? 100
      rarityScore = Math.max(0, 100 - usagePercentage)
      const tier = tierFromUsage(usagePercentage)

      const { error: upsertError } = await supabase.from('answers').upsert(
        {
          session_id,
          puzzle_cell_id,
          player_id,
          is_correct: true,
          usage_percentage: usagePercentage,
          rarity_tier: tier,
          rarity_score: rarityScore,
          response_time_ms: Number(serverResponseMs ?? 60000),
        },
        { onConflict: 'session_id,puzzle_cell_id' },
      )

      await bestEffortRpc(supabase, 'increment_rarity_stat', {
        p_cell_id: puzzle_cell_id,
        p_player_id: player_id,
      })

      if (upsertError) {
        console.error('answer upsert failed:', upsertError.message)
        return new Response(
          JSON.stringify({ error: 'answer_persist_failed', message: upsertError.message }),
          {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          },
        )
      }

      return new Response(
        JSON.stringify({
          correct: true,
          player_name: playerName,
          usage_percentage: usagePercentage,
          rarity_tier: tier,
          rarity_score: rarityScore,
          already_used_in_session: false,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    return new Response(
      JSON.stringify({
        correct: false,
        player_name: playerName,
        usage_percentage: 0,
        rarity_tier: 'common',
        rarity_score: 0,
        already_used_in_session: false,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
