import { router } from 'expo-router';
import { Text, View } from 'react-native';

import { RoleOptions } from '@/components/role-options';
import { Button } from '@/components/ui/button';
import { Screen } from '@/components/ui/screen';
import { Wordmark } from '@/components/wordmark';

/** Welcome and role pick. The chosen role is saved after the phone number is verified. */
export default function WelcomeScreen() {
  return (
    <Screen>
      <View className="flex-1 justify-between gap-10">
        <View className="gap-4 pt-4">
          <Wordmark />
          <Text className="text-3xl font-bold leading-tight text-ink">
            Find the right manufacturer for your product
          </Text>
          <Text className="text-base leading-relaxed text-ink-muted">
            Verified food, beverage and nutrition manufacturers across India. Free for founders and
            manufacturers.
          </Text>
        </View>

        <View className="gap-4">
          <Text className="text-sm font-semibold uppercase tracking-wide text-ink-subtle">
            Continue as
          </Text>
          <RoleOptions
            onSelect={(role) => router.push({ pathname: '/sign-in', params: { role } })}
          />
          <Button
            title="Already on MakerMatch? Log in"
            variant="ghost"
            onPress={() => router.push('/sign-in')}
            testID="log-in"
          />
        </View>
      </View>
    </Screen>
  );
}
