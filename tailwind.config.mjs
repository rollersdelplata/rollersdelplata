/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Open Sans"', 'sans-serif'],
        heading: ['"Roboto Condensed"', 'sans-serif'],
      },
      colors: {
        brand: {
          dark: '#212121',
          slate: '#b0bec5',
          muted: '#eceff1',
          accent: '#8096a1',
        },
      },
    },
  },
  plugins: [],
};
