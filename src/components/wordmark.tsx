import { Text } from 'react-native';

import { APP_NAME } from '@/constants/brand';

export function Wordmark() {
  return (
    <Text
      accessibilityRole="header"
      className="text-xl font-extrabold tracking-tight text-brand-700">
      {APP_NAME}
    </Text>
  );
}
