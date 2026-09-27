import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { Text, TextInput, View } from 'react-native';

import { BackButton } from '@/components/back-button';
import { Button } from '@/components/ui/button';
import { Screen } from '@/components/ui/screen';
import { friendlyError } from '@/lib/errors';
import { toIndianMobile } from '@/lib/phone';
import { parseSelfServeRole } from '@/lib/roles';
import { useAuth } from '@/providers/auth-provider';

export default function SignInScreen() {
  const params = useLocalSearchParams<{ role?: string }>();
  const role = parseSelfServeRole(params.role);
  const { sendOtp } = useAuth();

  const [input, setInput] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  const phone = toIndianMobile(input);

  async function submit() {
    if (!phone) {
      setError('Enter a 10-digit Indian mobile number.');
      return;
    }
    setError(null);
    setSending(true);
    try {
      await sendOtp(phone);
      router.push({ pathname: '/verify', params: role ? { phone, role } : { phone } });
    } catch (e) {
      setError(friendlyError(e));
    } finally {
      setSending(false);
    }
  }

  return (
    <Screen>
      <View className="gap-6">
        <BackButton />

        <View className="gap-2">
          <Text className="text-2xl font-bold text-ink">What&apos;s your mobile number?</Text>
          <Text className="text-base text-ink-muted">
            {role === 'founder'
              ? "You're joining as a founder. "
              : role === 'manufacturer'
                ? "You're joining as a manufacturer. "
                : ''}
            We&apos;ll text you a 6-digit code to sign in.
          </Text>
        </View>

        <View className="gap-2">
          <Text nativeID="phone-label" className="text-sm font-medium text-ink">
            Mobile number
          </Text>
          <View
            className={`min-h-[56px] flex-row items-center rounded-xl border bg-surface ${error ? 'border-danger' : 'border-surface-border'}`}>
            <Text className="border-r border-surface-border px-4 text-lg text-ink-muted">+91</Text>
            <TextInput
              accessibilityLabelledBy="phone-label"
              accessibilityLabel="Mobile number"
              autoComplete="tel-national"
              autoFocus
              className="flex-1 px-4 text-lg text-ink"
              inputMode="tel"
              keyboardType="phone-pad"
              maxLength={17}
              onChangeText={(text) => {
                setInput(text);
                if (error) setError(null);
              }}
              onSubmitEditing={submit}
              placeholder="98765 43210"
              placeholderTextColor="#8a9691"
              returnKeyType="send"
              testID="phone-input"
              textContentType="telephoneNumber"
              value={input}
            />
          </View>
          {error ? (
            <Text accessibilityLiveRegion="polite" className="text-sm text-danger" testID="error">
              {error}
            </Text>
          ) : null}
        </View>

        <Button
          title="Send code"
          onPress={submit}
          loading={sending}
          disabled={!phone}
          testID="send-code"
        />

        <Text className="text-xs leading-relaxed text-ink-subtle">
          By continuing you agree to receive a one-time SMS from MakerMatch. Indian mobile numbers
          only.
        </Text>
      </View>
    </Screen>
  );
}
