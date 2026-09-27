import { Redirect, useLocalSearchParams } from 'expo-router';
import { useEffect, useState } from 'react';
import { Text, TextInput, View } from 'react-native';

import { BackButton } from '@/components/back-button';
import { Button } from '@/components/ui/button';
import { Screen } from '@/components/ui/screen';
import { friendlyError } from '@/lib/errors';
import { formatIndianMobile, toIndianMobile } from '@/lib/phone';
import { parseSelfServeRole } from '@/lib/roles';
import { useAuth } from '@/providers/auth-provider';

const CODE_LENGTH = 6;
// Supabase allows one SMS per number per 60 seconds by default.
const RESEND_AFTER_SECONDS = 60;

export default function VerifyScreen() {
  const params = useLocalSearchParams<{ phone?: string; role?: string }>();
  const phone = toIndianMobile(params.phone ?? '');
  const role = parseSelfServeRole(params.role);
  const { verifyOtp, sendOtp } = useAuth();

  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [verifying, setVerifying] = useState(false);
  const [resending, setResending] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(RESEND_AFTER_SECONDS);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const timer = setTimeout(() => setSecondsLeft((s) => s - 1), 1000);
    return () => clearTimeout(timer);
  }, [secondsLeft]);

  if (!phone) return <Redirect href="/sign-in" />;

  async function verify(token: string) {
    if (token.length !== CODE_LENGTH || verifying || !phone) return;
    setError(null);
    setNotice(null);
    setVerifying(true);
    try {
      await verifyOtp(phone, token, role);
      // Success: the root navigator moves on once the account has loaded.
    } catch (e) {
      setError(friendlyError(e));
      setVerifying(false);
    }
  }

  async function resend() {
    if (!phone) return;
    setError(null);
    setNotice(null);
    setResending(true);
    try {
      await sendOtp(phone);
      setCode('');
      setSecondsLeft(RESEND_AFTER_SECONDS);
      setNotice('New code sent.');
    } catch (e) {
      setError(friendlyError(e));
    } finally {
      setResending(false);
    }
  }

  return (
    <Screen>
      <View className="gap-6">
        <BackButton label="Change number" />

        <View className="gap-2">
          <Text className="text-2xl font-bold text-ink">Enter the code</Text>
          <Text className="text-base text-ink-muted">
            We sent a {CODE_LENGTH}-digit code to{' '}
            <Text className="font-semibold text-ink">{formatIndianMobile(phone)}</Text>
          </Text>
        </View>

        <View className="gap-2">
          <TextInput
            accessibilityLabel={`${CODE_LENGTH}-digit code`}
            autoComplete="sms-otp"
            autoFocus
            className={`min-h-[64px] rounded-xl border bg-surface px-4 text-center text-3xl font-semibold tracking-[12px] text-ink ${error ? 'border-danger' : 'border-surface-border'}`}
            editable={!verifying}
            inputMode="numeric"
            keyboardType="number-pad"
            maxLength={CODE_LENGTH}
            onChangeText={(text) => {
              const digits = text.replace(/\D/g, '').slice(0, CODE_LENGTH);
              setCode(digits);
              if (error) setError(null);
              if (digits.length === CODE_LENGTH) void verify(digits);
            }}
            placeholder="••••••"
            placeholderTextColor="#c4ccc8"
            testID="code-input"
            textContentType="oneTimeCode"
            value={code}
          />
          {error ? (
            <Text accessibilityLiveRegion="polite" className="text-sm text-danger" testID="error">
              {error}
            </Text>
          ) : null}
          {notice ? (
            <Text accessibilityLiveRegion="polite" className="text-sm text-brand-700">
              {notice}
            </Text>
          ) : null}
        </View>

        <Button
          title={verifying ? 'Signing you in…' : 'Verify'}
          onPress={() => void verify(code)}
          loading={verifying}
          disabled={code.length !== CODE_LENGTH}
          testID="verify"
        />

        {secondsLeft > 0 ? (
          <Text className="text-center text-sm text-ink-muted">
            Didn&apos;t get it? You can ask for a new code in {secondsLeft}s
          </Text>
        ) : (
          <Button
            title="Send a new code"
            variant="ghost"
            onPress={() => void resend()}
            loading={resending}
            disabled={verifying}
          />
        )}
      </View>
    </Screen>
  );
}
