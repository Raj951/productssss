import { Platform, Text, View } from 'react-native';

import { AreaHeader } from '@/components/area-header';
import { LoadError, Loading } from '@/components/load-state';
import { NextUp } from '@/components/next-up';
import { Card } from '@/components/ui/card';
import { Screen } from '@/components/ui/screen';
import { supabase } from '@/lib/supabase';
import { useLoad } from '@/lib/use-load';

async function loadAdminHome() {
  const head = { count: 'exact', head: true } as const;
  const [pending, verified, openReports] = await Promise.all([
    supabase.from('manufacturers').select('id', head).eq('status', 'pending'),
    supabase.from('manufacturers').select('id', head).eq('status', 'verified'),
    supabase.from('reports').select('id', head).eq('status', 'open'),
  ]);
  for (const result of [pending, verified, openReports]) {
    if (result.error) throw result.error;
  }
  return {
    pending: pending.count ?? 0,
    verified: verified.count ?? 0,
    openReports: openReports.count ?? 0,
  };
}

export default function AdminHome() {
  if (Platform.OS !== 'web') return <WebOnly />;
  return <AdminDashboard />;
}

function AdminDashboard() {
  const { state, reload } = useLoad(loadAdminHome, null);

  return (
    <Screen>
      <View className="gap-6">
        <AreaHeader greeting="Admin" subtitle="Manufacturer verification and moderation" />

        {state.status === 'loading' ? <Loading /> : null}
        {state.status === 'error' ? <LoadError message={state.message} onRetry={reload} /> : null}
        {state.status === 'ready' ? (
          <Card title="At a glance">
            <Text className="text-base text-ink" testID="admin-counts">
              {state.data.pending} awaiting review · {state.data.verified} verified ·{' '}
              {state.data.openReports} open reports
            </Text>
          </Card>
        ) : null}

        <NextUp
          items={['Applications queue with approve / reject', 'CSV bulk import', 'Reports']}
        />
      </View>
    </Screen>
  );
}

function WebOnly() {
  return (
    <Screen>
      <View className="gap-6">
        <AreaHeader greeting="Admin" subtitle="The admin panel is web only" />
        <Text className="text-base text-ink-muted">
          Open the web app on a computer and sign in with this number to review manufacturers.
        </Text>
      </View>
    </Screen>
  );
}
