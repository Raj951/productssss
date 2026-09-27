import { Text, View } from 'react-native';

import { AreaHeader } from '@/components/area-header';
import { LoadError, Loading } from '@/components/load-state';
import { NextUp } from '@/components/next-up';
import { Card } from '@/components/ui/card';
import { Screen } from '@/components/ui/screen';
import { supabase } from '@/lib/supabase';
import { useLoad } from '@/lib/use-load';
import { useAuth } from '@/providers/auth-provider';

async function loadFounderHome(userId: string) {
  const [company, briefs] = await Promise.all([
    supabase
      .from('founder_profiles')
      .select('company_name, city, state')
      .eq('user_id', userId)
      .maybeSingle(),
    // RLS returns only this founder's briefs.
    supabase.from('briefs').select('status'),
  ]);
  if (company.error) throw company.error;
  if (briefs.error) throw briefs.error;

  const counts = { draft: 0, open: 0, closed: 0 };
  for (const brief of briefs.data) counts[brief.status] += 1;
  return { company: company.data, counts };
}

export default function FounderHome() {
  const { profile } = useAuth();
  const { state, reload } = useLoad(loadFounderHome, profile?.id ?? '');
  const firstName = profile?.name?.split(' ')[0];

  return (
    <Screen>
      <View className="gap-6">
        <AreaHeader
          greeting={firstName ? `Hi ${firstName}` : 'Welcome'}
          subtitle="Your founder home"
        />

        {state.status === 'loading' ? <Loading /> : null}
        {state.status === 'error' ? <LoadError message={state.message} onRetry={reload} /> : null}
        {state.status === 'ready' ? (
          <>
            <Card title="Your company">
              {state.data.company ? (
                <Text className="text-base text-ink" testID="company">
                  {state.data.company.company_name} · {state.data.company.city},{' '}
                  {state.data.company.state}
                </Text>
              ) : (
                <Text className="text-base text-ink-muted">
                  Not set up yet. You&apos;ll add your company and city in the next build.
                </Text>
              )}
            </Card>

            <Card title="Your briefs">
              <View className="flex-row gap-3" testID="brief-counts">
                <Stat label="Draft" value={state.data.counts.draft} />
                <Stat label="Open" value={state.data.counts.open} />
                <Stat label="Closed" value={state.data.counts.closed} />
              </View>
            </Card>
          </>
        ) : null}

        <NextUp
          items={[
            'Company onboarding (name, city)',
            'Post a brief with the 4-step form',
            'Ranked matches, NDA outreach, quotes and samples',
          ]}
        />
      </View>
    </Screen>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <View className="flex-1 items-center rounded-xl bg-surface-muted py-3">
      <Text className="text-2xl font-bold text-ink">{value}</Text>
      <Text className="text-sm text-ink-muted">{label}</Text>
    </View>
  );
}
