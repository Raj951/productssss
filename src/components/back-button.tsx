import Ionicons from '@expo/vector-icons/Ionicons';
import { router } from 'expo-router';
import { Pressable, Text } from 'react-native';

import { colors } from '@/constants/brand';

export function BackButton({ label = 'Back' }: { label?: string }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={12}
      onPress={() => (router.canGoBack() ? router.back() : router.replace('/'))}
      className="-ml-1 min-h-[44px] flex-row items-center gap-1 self-start">
      <Ionicons name="chevron-back" size={22} color={colors.brand} />
      <Text className="text-base font-medium text-brand-700">{label}</Text>
    </Pressable>
  );
}
