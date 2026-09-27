import { useEffect, useState } from 'react';

import { friendlyError } from '@/lib/errors';

type LoadState<T> =
  { status: 'loading' } | { status: 'error'; message: string } | { status: 'ready'; data: T };

/**
 * Runs `loader(arg)` when the screen mounts and exposes loading / error / data plus
 * `reload`. Pass a module-level loader so its identity is stable.
 */
export function useLoad<A, T>(loader: (arg: A) => Promise<T>, arg: A) {
  const [state, setState] = useState<LoadState<T>>({ status: 'loading' });
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    loader(arg).then(
      (data) => {
        if (!cancelled) setState({ status: 'ready', data });
      },
      (error: unknown) => {
        if (!cancelled) setState({ status: 'error', message: friendlyError(error) });
      }
    );
    return () => {
      cancelled = true;
    };
  }, [loader, arg, attempt]);

  function reload() {
    setState({ status: 'loading' });
    setAttempt((n) => n + 1);
  }

  return { state, reload };
}
