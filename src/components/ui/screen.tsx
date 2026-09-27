import { ScrollView, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

type ScreenProps = {
  children: React.ReactNode;
  /** Set false when the screen sits under a native header that already handles the top inset. */
  padTop?: boolean;
};

/**
 * Page wrapper: safe areas, scrolling (so small phones and open keyboards never hide
 * content), and a comfortable reading width on web.
 */
export function Screen({ children, padTop = true }: ScreenProps) {
  const insets = useSafeAreaInsets();
  return (
    <View
      className="flex-1 bg-surface"
      style={{ paddingTop: padTop ? insets.top : 0, paddingBottom: insets.bottom }}>
      <ScrollView
        contentContainerClassName="grow px-5 py-6"
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag">
        <View className="w-full max-w-md flex-1 self-center">{children}</View>
      </ScrollView>
    </View>
  );
}
