import { isAuthError, isAuthRetryableFetchError } from '@supabase/supabase-js';

const AUTH_MESSAGES: Record<string, string> = {
  otp_expired: 'That code is wrong or has expired. Check it, or ask for a new one.',
  over_sms_send_rate_limit: 'Too many codes requested. Please wait a minute and try again.',
  over_request_rate_limit: 'Too many attempts. Please wait a minute and try again.',
  sms_send_failed: "We couldn't send an SMS to this number. Check it and try again.",
  phone_provider_disabled: "Phone sign-in isn't switched on for this Supabase project yet.",
  signup_disabled: 'New sign-ups are paused right now.',
  otp_disabled: 'New sign-ups are paused right now.',
  validation_failed: "That doesn't look like a valid mobile number.",
};

/** A short, human message for anything thrown by Supabase or the network. */
export function friendlyError(error: unknown): string {
  if (isAuthRetryableFetchError(error)) {
    return "Can't reach MakerMatch. Check your internet connection and try again.";
  }
  if (isAuthError(error)) {
    if (error.code && AUTH_MESSAGES[error.code]) return AUTH_MESSAGES[error.code];
    if (error.status === 429) return AUTH_MESSAGES.over_request_rate_limit;
    return error.message;
  }
  if (error instanceof TypeError && /network|fetch/i.test(error.message)) {
    return "Can't reach MakerMatch. Check your internet connection and try again.";
  }
  if (
    error &&
    typeof error === 'object' &&
    'message' in error &&
    typeof error.message === 'string'
  ) {
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}
