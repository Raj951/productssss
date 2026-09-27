import { useState } from 'react';
import { Text, View } from 'react-native';

import { RoleOptions } from '@/components/role-options';
import { Button } from '@/components/ui/button';
import { Screen } from '@/components/ui/screen';
import { Wordmark } from '@/components/wordmark';
import { friendlyError } from '@/lib/errors';
import type { SelfServeRole } from '@/providers/auth-provider';
import { useAuth } from '@/providers/auth-provider';

/** Shown to a signed-in person whose account has no role yet (e.g. they tapped "Log in" as a new user). */
export default function ChooseRoleScreen() {
  const { chooseRole, signOut } = useAuth();
  const [busyRole, setBusyRole] = useState<SelfServeRole | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function select(role: SelfServeRole) {
    setError(null);
    setBusyRole(role);
    try {
      await chooseRole(role);
    } catch (e) {
      setError(friendlyError(e));
      setBusyRole(null);
    }
  }

  return (
    <Screen>
      <View className="flex-1 gap-8">
        <View className="gap-3 pt-4">
          <Wordmark />
          <Text className="text-2xl font-bold text-ink">How will you use MakerMatch?</Text>
          <Text className="text-base text-ink-muted">
            Pick one. Your account stays a founder or a manufacturer account. Manufacturer teams can
            add colleagues later.
          </Text>
        </View>

        <RoleOptions onSelect={select} busyRole={busyRole} />

        {error ? (
          <Text accessibilityLiveRegion="polite" className="text-sm text-danger" testID="error">
            {error}
          </Text>
        ) : null}

        <Button title="Sign out" variant="ghost" onPress={() => void signOut()} />
      </View>
    </Screen>
  );
}
