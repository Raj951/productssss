import { ActivityIndicator, Pressable, Text } from 'react-native';

import { colors } from '@/constants/brand';

type ButtonProps = {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'ghost';
  loading?: boolean;
  disabled?: boolean;
  testID?: string;
};

const containerClass = {
  primary: 'bg-brand-700 active:bg-brand-900',
  secondary: 'border border-surface-border bg-surface active:bg-surface-muted',
  ghost: 'active:bg-surface-muted',
} as const;

const labelClass = {
  primary: 'text-white',
  secondary: 'text-ink',
  ghost: 'text-brand-700',
} as const;

export function Button({
  title,
  onPress,
  variant = 'primary',
  loading = false,
  disabled = false,
  testID,
}: ButtonProps) {
  const inactive = disabled || loading;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: inactive, busy: loading }}
      disabled={inactive}
      onPress={onPress}
      testID={testID}
      className={`min-h-[52px] flex-row items-center justify-center rounded-xl px-5 ${containerClass[variant]} ${inactive ? 'opacity-50' : ''}`}>
      {loading ? (
        <ActivityIndicator color={variant === 'primary' ? colors.white : colors.brand} />
      ) : (
        <Text className={`text-base font-semibold ${labelClass[variant]}`}>{title}</Text>
      )}
    </Pressable>
  );
}
