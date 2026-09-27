import '@/global.css';

import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { Text, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { Button } from '@/components/ui/button';
import { AuthProvider, useAuth } from '@/providers/auth-provider';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <StatusBar style="dark" />
        <RootNavigator />
      </AuthProvider>
    </SafeAreaProvider>
  );
}

/**
 * Who can reach what. A screen whose guard is false does not exist for that person;
 * when a guard flips (sign in, role picked, sign out) the router moves them to the
 * first screen they are allowed on.
 */
function RootNavigator() {
  const { state, profile } = useAuth();

  useEffect(() => {
    if (state.status !== 'loading') SplashScreen.hideAsync();
  }, [state.status]);

  if (state.status === 'loading') return null;
  if (state.status === 'profileError') return <ProfileError />;

  const signedIn = state.status === 'signedIn';
  const role = profile?.role ?? null;

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Protected guard={!signedIn}>
        <Stack.Screen name="(auth)" />
      </Stack.Protected>

      <Stack.Protected guard={signedIn && role === null}>
        <Stack.Screen name="choose-role" />
      </Stack.Protected>

      <Stack.Protected guard={role === 'founder'}>
        <Stack.Screen name="founder" />
      </Stack.Protected>

      <Stack.Protected guard={role === 'manufacturer'}>
        <Stack.Screen name="manufacturer" />
      </Stack.Protected>

      <Stack.Protected guard={role === 'admin'}>
        <Stack.Screen name="admin" />
      </Stack.Protected>

      <Stack.Protected guard={signedIn && role !== null}>
        <Stack.Screen
          name="settings"
          options={{ headerShown: true, title: 'Settings', headerBackTitle: 'Back' }}
        />
      </Stack.Protected>
    </Stack>
  );
}

function ProfileError() {
  const { retryProfile, signOut } = useAuth();
  const [retrying, setRetrying] = useState(false);

  async function retry() {
    setRetrying(true);
    await retryProfile();
    setRetrying(false);
  }

  return (
    <View className="flex-1 items-center justify-center gap-4 bg-surface px-6">
      <Text className="text-center text-lg font-semibold text-ink">
        We couldn&apos;t load your account
      </Text>
      <Text className="text-center text-base text-ink-muted">
        This is usually a weak connection. Check your internet and try again.
      </Text>
      <View className="w-full max-w-xs gap-2">
        <Button title="Try again" onPress={() => void retry()} loading={retrying} />
        <Button title="Sign out" variant="ghost" onPress={() => void signOut()} />
      </View>
    </View>
  );
}
