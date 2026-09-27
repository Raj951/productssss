import { Text, View } from 'react-native';

import { AreaHeader } from '@/components/area-header';
import { LoadError, Loading } from '@/components/load-state';
import { NextUp } from '@/components/next-up';
import { Card } from '@/components/ui/card';
import { Screen } from '@/components/ui/screen';
import { supabase } from '@/lib/supabase';
import { useLoad } from '@/lib/use-load';
import { useAuth } from '@/providers/auth-provider';
import type { Database } from '@/types/database';

type ManufacturerStatus = Database['public']['Enums']['manufacturer_status'];

const STATUS: Record<ManufacturerStatus, { label: string; className: string }> = {
  verified: { label: 'Verified', className: 'bg-brand-100 text-brand-900' },
  pending: { label: 'Under review', className: 'bg-amber-100 text-amber-900' },
  rejected: { label: 'Not approved', className: 'bg-red-100 text-red-900' },
  paused: { label: 'Paused', className: 'bg-surface-muted text-ink-muted' },
};

const MEMBER_ROLE = { owner: 'Owner', sales: 'Sales', rnd: 'R&D' } as const;

async function loadManufacturerHome(userId: string) {
  const [membership, inbox] = await Promise.all([
    supabase
      .from('manufacturer_members')
      .select('role, manufacturer:manufacturers (legal_name, city, state, status)')
      .eq('user_id', userId)
      .maybeSingle(),
    // RLS returns only outreach addressed to this person's company.
    supabase.from('outreach').select('id', { count: 'exact', head: true }),
  ]);
  if (membership.error) throw membership.error;
  if (inbox.error) throw inbox.error;
  return { membership: membership.data, briefCount: inbox.count ?? 0 };
}

export default function ManufacturerHome() {
  const { profile } = useAuth();
  const { state, reload } = useLoad(loadManufacturerHome, profile?.id ?? '');
  const firstName = profile?.name?.split(' ')[0];

  return (
    <Screen>
      <View className="gap-6">
        <AreaHeader
          greeting={firstName ? `Hi ${firstName}` : 'Welcome'}
          subtitle="Your manufacturer home"
        />

        {state.status === 'loading' ? <Loading /> : null}
        {state.status === 'error' ? <LoadError message={state.message} onRetry={reload} /> : null}
        {state.status === 'ready' ? (
          <>
            <Card title="Your company">
              {state.data.membership?.manufacturer ? (
                <View className="gap-2" testID="company">
                  <Text className="text-base font-semibold text-ink">
                    {state.data.membership.manufacturer.legal_name}
                  </Text>
                  <Text className="text-sm text-ink-muted">
                    {state.data.membership.manufacturer.city},{' '}
                    {state.data.membership.manufacturer.state} · You are{' '}
                    {MEMBER_ROLE[state.data.membership.role]}
                  </Text>
                  <Text
                    className={`self-start rounded-full px-3 py-1 text-sm font-medium ${STATUS[state.data.membership.manufacturer.status].className}`}>
                    {STATUS[state.data.membership.manufacturer.status].label}
                  </Text>
                </View>
              ) : (
                <Text className="text-base text-ink-muted">
                  Not set up yet. The application (GST, licences, factory photos) arrives in the
                  next build.
                </Text>
              )}
            </Card>

            <Card title="Incoming briefs">
              <Text className="text-base text-ink" testID="brief-count">
                {state.data.briefCount === 0
                  ? 'No briefs yet.'
                  : `${state.data.briefCount} brief${state.data.briefCount === 1 ? '' : 's'}`}
              </Text>
            </Card>
          </>
        ) : null}

        <NextUp
          items={[
            'Company application with GST and licence upload',
            'Admin verification and your "Verified" badge',
            'Inbox of matching briefs, NDA, accept or decline, quotes and chat',
          ]}
        />
      </View>
    </Screen>
  );
}
