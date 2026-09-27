import { Text, View } from 'react-native';

import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Screen } from '@/components/ui/screen';
import { formatIndianMobile } from '@/lib/phone';
import { ROLE_LABELS } from '@/lib/roles';
import { useAuth } from '@/providers/auth-provider';

export default function SettingsScreen() {
  const { profile, signOut } = useAuth();

  return (
    <Screen padTop={false}>
      <View className="gap-6">
        <Card title="Account">
          <Row label="Name" value={profile?.name ?? 'Not set'} />
          <Row label="Mobile" value={formatIndianMobile(profile?.phone)} />
          <Row label="Account type" value={profile?.role ? ROLE_LABELS[profile.role] : ''} />
        </Card>
        <Button
          title="Sign out"
          variant="secondary"
          onPress={() => void signOut()}
          testID="sign-out"
        />
      </View>
    </Screen>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <View className="flex-row justify-between gap-4 py-1">
      <Text className="text-base text-ink-muted">{label}</Text>
      <Text className="shrink text-right text-base text-ink">{value}</Text>
    </View>
  );
}
