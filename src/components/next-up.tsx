import { Text, View } from 'react-native';

/** Placeholder for features that arrive in later build phases. */
export function NextUp({ items }: { items: string[] }) {
  return (
    <View className="gap-2 rounded-2xl bg-brand-50 p-4">
      <Text className="text-sm font-semibold text-brand-900">Coming in the next builds</Text>
      {items.map((item) => (
        <Text key={item} className="text-sm leading-relaxed text-brand-900">
          • {item}
        </Text>
      ))}
    </View>
  );
}
