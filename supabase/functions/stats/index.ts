import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-user-uuid',
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

function isoWeekDaysUtc(): string[] {
  const today = new Date()
  today.setUTCHours(0, 0, 0, 0)
  const day = today.getUTCDay() // Sun=0
  const mondayOffset = day === 0 ? -6 : 1 - day
  const monday = new Date(today)
  monday.setUTCDate(today.getUTCDate() + mondayOffset)

  const days: string[] = []
  for (let i = 0; i < 7; i++) {
    const d = new Date(monday)
    d.setUTCDate(monday.getUTCDate() + i)
    days.push(isoDate(d))
  }
  return days
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const userUuid = url.searchParams.get('user_uuid') ?? req.headers.get('x-user-uuid')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const weekDays = isoWeekDaysUtc()
    const weekStart = `${weekDays[0]}T00:00:00.000Z`

    const { data: user } = await supabase
      .from('users')
      .select('id')
      .eq('user_uuid', userUuid)
      .maybeSingle()

    if (!user) {
      return new Response(
        JSON.stringify({
          games_played: 0,
          current_streak: 0,
          best_streak: 0,
          total_score: 0,
          rarity_breakdown: {},
          weekly_daily_scores: weekDays.map((date) => ({ date, score: 0 })),
          daily_completed_today: false,
          today_daily_score: 0,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const todayKey = isoDate(new Date())

    const [{ data: stats }, { data: dailySessions }, { data: completedToday }] =
      await Promise.all([
      supabase.from('user_stats').select('*').eq('user_id', user.id).maybeSingle(),
      supabase
        .from('puzzle_sessions')
        .select('final_score, completed_at, hints_used, mistakes, puzzles(puzzle_date)')
        .eq('user_id', user.id)
        .eq('mode', 'daily')
        .eq('status', 'completed')
        .gte('completed_at', weekStart)
        .order('completed_at', { ascending: true }),
      supabase.rpc('user_completed_daily_today', { p_user_uuid: userUuid }),
    ])

    const scoreByDate = new Map<string, number>()
    for (const day of weekDays) scoreByDate.set(day, 0)

    for (const row of dailySessions ?? []) {
      const puzzleDate = (row.puzzles as { puzzle_date?: string } | null)?.puzzle_date
      const completedAt = row.completed_at as string | null
      const dateKey =
        puzzleDate ??
        (completedAt ? completedAt.slice(0, 10) : null)
      if (!dateKey || !scoreByDate.has(dateKey)) continue
      scoreByDate.set(dateKey, Number(row.final_score ?? 0))
    }

    return new Response(
      JSON.stringify({
        games_played: stats?.games_played ?? 0,
        current_streak: stats?.current_streak ?? 0,
        best_streak: stats?.best_streak ?? 0,
        total_score: stats?.total_score ?? 0,
        rarity_breakdown: {
          common: stats?.common_count ?? 0,
          rare: stats?.rare_count ?? 0,
          epic: stats?.epic_count ?? 0,
          legendary: stats?.legendary_count ?? 0,
          mythic: stats?.mythic_count ?? 0,
        },
        weekly_daily_scores: weekDays.map((date) => ({
          date,
          score: scoreByDate.get(date) ?? 0,
        })),
        daily_completed_today: completedToday === true,
        today_daily_score: scoreByDate.get(todayKey) ?? 0,
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
