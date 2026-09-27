import type { Session } from '@supabase/supabase-js';
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';

import { supabase } from '@/lib/supabase';
import type { Database } from '@/types/database';

export type Role = Database['public']['Enums']['user_role'];
/** The roles a person can pick for themselves. Admin is assigned internally. */
export type SelfServeRole = Exclude<Role, 'admin'>;
export type UserProfile = Database['public']['Tables']['users']['Row'];

type AuthState =
  | { status: 'loading' }
  | { status: 'signedOut' }
  | { status: 'signedIn'; session: Session; profile: UserProfile | null }
  | { status: 'profileError'; session: Session; message: string };

type AuthContextValue = {
  state: AuthState;
  /** The signed-in person's profile, once loaded. */
  profile: UserProfile | null;
  sendOtp: (phone: string) => Promise<void>;
  /** Verifies the code. `intendedRole` is saved if this is a brand-new account. */
  verifyOtp: (phone: string, token: string, intendedRole?: SelfServeRole) => Promise<void>;
  chooseRole: (role: SelfServeRole) => Promise<void>;
  /** After a failed account load: try again (resolves when it has succeeded or failed again). */
  retryProfile: () => Promise<void>;
  signOut: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

async function loadProfile(userId: string, intendedRole: SelfServeRole | null) {
  const { data, error } = await supabase.from('users').select('*').eq('id', userId).maybeSingle();
  if (error) throw error;

  if (!data?.role && intendedRole) {
    const { data: updated, error: roleError } = await supabase.rpc('set_my_role', {
      p_role: intendedRole,
    });
    if (roleError) throw roleError;
    return updated;
  }
  return data;
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: 'loading' });
  // The role picked on the welcome screen, applied once the OTP is verified.
  const intendedRole = useRef<SelfServeRole | null>(null);
  const loadedUserId = useRef<string | null>(null);

  const applySession = useCallback(async (session: Session | null) => {
    if (!session) {
      loadedUserId.current = null;
      setState({ status: 'signedOut' });
      return;
    }

    // Token refresh for the same person: keep the profile we already have.
    if (session.user.id === loadedUserId.current) {
      setState((prev) => (prev.status === 'signedIn' ? { ...prev, session } : prev));
      return;
    }

    const userId = session.user.id;
    loadedUserId.current = userId;
    try {
      const profile = await loadProfile(userId, intendedRole.current);
      intendedRole.current = null;
      if (loadedUserId.current === userId) setState({ status: 'signedIn', session, profile });
    } catch (error) {
      // Don't guess a role on a failed load (patchy data is common); let them retry.
      loadedUserId.current = null;
      const message = error instanceof Error ? error.message : String(error);
      setState({ status: 'profileError', session, message });
    }
  }, []);

  useEffect(() => {
    // Fires INITIAL_SESSION on start, then SIGNED_IN / TOKEN_REFRESHED / SIGNED_OUT.
    const { data } = supabase.auth.onAuthStateChange((_event, session) => {
      // Calling Supabase from inside this callback can deadlock, so defer the work.
      setTimeout(() => void applySession(session), 0);
    });
    return () => data.subscription.unsubscribe();
  }, [applySession]);

  const sendOtp = useCallback(async (phone: string) => {
    const { error } = await supabase.auth.signInWithOtp({ phone });
    if (error) throw error;
  }, []);

  const verifyOtp = useCallback(async (phone: string, token: string, role?: SelfServeRole) => {
    intendedRole.current = role ?? null;
    const { error } = await supabase.auth.verifyOtp({ phone, token, type: 'sms' });
    if (error) {
      intendedRole.current = null;
      throw error;
    }
  }, []);

  const chooseRole = useCallback(async (role: SelfServeRole) => {
    const { data, error } = await supabase.rpc('set_my_role', { p_role: role });
    if (error) throw error;
    setState((prev) => (prev.status === 'signedIn' ? { ...prev, profile: data } : prev));
  }, []);

  const retryProfile = useCallback(async () => {
    if (state.status !== 'profileError') return;
    await applySession(state.session);
  }, [state, applySession]);

  const signOut = useCallback(async () => {
    const { error } = await supabase.auth.signOut();
    // Even if the server call fails (offline), the local session is cleared.
    if (error) setState({ status: 'signedOut' });
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      state,
      profile: state.status === 'signedIn' ? state.profile : null,
      sendOtp,
      verifyOtp,
      chooseRole,
      retryProfile,
      signOut,
    }),
    [state, sendOtp, verifyOtp, chooseRole, retryProfile, signOut]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error('useAuth must be used inside <AuthProvider>');
  return value;
}
