import { Stack } from 'expo-router';

// Manufacturer area. Later phases add: application, awaiting-verification, inbox,
// briefs/[id] (summary before NDA, full after), quote form, profile editing, team.
export default function ManufacturerLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
