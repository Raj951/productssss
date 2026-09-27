/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{ts,tsx}'],
  presets: [require('nativewind/preset')],
  // Light-only for v1. 'class' (not 'media') lets NativeWind honour userInterfaceStyle: light.
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#effaf6',
          100: '#d7f2e7',
          200: '#b1e4d2',
          500: '#1f9a73',
          600: '#147d5d',
          700: '#10644b',
          900: '#0b3d2f',
        },
        ink: {
          DEFAULT: '#14201c',
          muted: '#56635e',
          subtle: '#8a9691',
        },
        surface: {
          DEFAULT: '#ffffff',
          muted: '#f4f6f5',
          border: '#dde3e0',
        },
        danger: '#b42318',
      },
    },
  },
  plugins: [],
};
