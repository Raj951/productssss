import { Stack } from 'expo-router';

// Admin area (web only). Later phases add: applications queue, manufacturers/[id]
// (approve / reject), CSV bulk import, reports.
export default function AdminLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
