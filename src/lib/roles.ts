import type { Role, SelfServeRole } from '@/providers/auth-provider';

/** Route params are untrusted strings; only accept the two self-serve roles. */
export function parseSelfServeRole(value: unknown): SelfServeRole | undefined {
  return value === 'founder' || value === 'manufacturer' ? value : undefined;
}

export const ROLE_LABELS: Record<Role, string> = {
  founder: 'Founder',
  manufacturer: 'Manufacturer',
  admin: 'Admin',
};
