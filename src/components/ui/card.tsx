import { Text, View } from 'react-native';

type CardProps = {
  title: string;
  children: React.ReactNode;
};

export function Card({ title, children }: CardProps) {
  return (
    <View className="gap-2 rounded-2xl border border-surface-border bg-surface p-4">
      <Text className="text-sm font-semibold uppercase tracking-wide text-ink-subtle">{title}</Text>
      {children}
    </View>
  );
}
