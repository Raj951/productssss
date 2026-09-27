import { ActivityIndicator, Text, View } from 'react-native';

import { Button } from '@/components/ui/button';
import { colors } from '@/constants/brand';

export function Loading() {
  return (
    <View className="items-center py-10">
      <ActivityIndicator color={colors.brand} />
    </View>
  );
}

export function LoadError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <View className="gap-3 rounded-2xl bg-surface-muted p-4">
      <Text className="text-base text-ink">{message}</Text>
      <Button title="Try again" variant="secondary" onPress={onRetry} />
    </View>
  );
}
