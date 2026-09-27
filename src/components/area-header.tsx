import Ionicons from '@expo/vector-icons/Ionicons';
import { router } from 'expo-router';
import { Pressable, Text, View } from 'react-native';

import { Wordmark } from '@/components/wordmark';
import { colors } from '@/constants/brand';

/** Top of each area's home: wordmark, settings, and a greeting. */
export function AreaHeader({ greeting, subtitle }: { greeting: string; subtitle: string }) {
  return (
    <View className="gap-4">
      <View className="flex-row items-center justify-between">
        <Wordmark />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Settings"
          hitSlop={8}
          onPress={() => router.push('/settings')}
          testID="open-settings"
          className="h-11 w-11 items-center justify-center rounded-full active:bg-surface-muted">
          <Ionicons name="settings-outline" size={24} color={colors.ink} />
        </Pressable>
      </View>
      <View className="gap-1">
        <Text className="text-2xl font-bold text-ink" testID="greeting">
          {greeting}
        </Text>
        <Text className="text-base text-ink-muted">{subtitle}</Text>
      </View>
    </View>
  );
}
