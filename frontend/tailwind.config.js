/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        zavy: {
          50: '#f5f5ff',
          100: '#ebedff',
          200: '#d7dbff',
          300: '#b4bcff',
          400: '#8993ff',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4035cd',
          800: '#352ba8',
          900: '#2f2789',
          950: '#1c1753',
        },
      },
    },
  },
  plugins: [],
}
