import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://www.rollersdelplata.com.ar',
  integrations: [tailwind()],
  output: 'static',
});
