import Ionicons from '@expo/vector-icons/Ionicons';
import { ActivityIndicator, Pressable, Text, View } from 'react-native';

import { colors } from '@/constants/brand';
import type { SelfServeRole } from '@/providers/auth-provider';

const OPTIONS: {
  role: SelfServeRole;
  title: string;
  body: string;
  icon: keyof typeof Ionicons.glyphMap;
}[] = [
  {
    role: 'founder',
    title: "I'm a founder",
    body: 'Post one brief and hear back from verified manufacturers.',
    icon: 'rocket-outline',
  },
  {
    role: 'manufacturer',
    title: "I'm a manufacturer",
    body: 'Receive structured briefs from serious D2C and FMCG brands.',
    icon: 'business-outline',
  },
];

type RoleOptionsProps = {
  onSelect: (role: SelfServeRole) => void;
  /** Shows a spinner on this option and disables the others. */
  busyRole?: SelfServeRole | null;
};

export function RoleOptions({ onSelect, busyRole = null }: RoleOptionsProps) {
  return (
    <View className="gap-3">
      {OPTIONS.map((option) => (
        <Pressable
          key={option.role}
          accessibilityRole="button"
          accessibilityLabel={option.title}
          accessibilityHint={option.body}
          disabled={busyRole !== null}
          onPress={() => onSelect(option.role)}
          testID={`role-${option.role}`}
          className="min-h-[88px] flex-row items-center gap-4 rounded-2xl border border-surface-border bg-surface p-4 active:border-brand-500 active:bg-brand-50">
          <View className="h-12 w-12 items-center justify-center rounded-full bg-brand-50">
            <Ionicons name={option.icon} size={24} color={colors.brand} />
          </View>
          <View className="flex-1 gap-1">
            <Text className="text-lg font-semibold text-ink">{option.title}</Text>
            <Text className="text-sm text-ink-muted">{option.body}</Text>
          </View>
          {busyRole === option.role ? (
            <ActivityIndicator color={colors.brand} />
          ) : (
            <Ionicons name="chevron-forward" size={20} color={colors.inkMuted} />
          )}
        </Pressable>
      ))}
    </View>
  );
}
