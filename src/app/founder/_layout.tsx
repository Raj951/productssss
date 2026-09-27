import { Stack } from 'expo-router';

// Founder area. Later phases add: onboarding, briefs/new, briefs/[id], matches,
// manufacturers/[id], outreach tracker, quote comparison, sample tracker.
export default function FounderLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
