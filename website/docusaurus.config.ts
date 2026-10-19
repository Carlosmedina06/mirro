import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const GITHUB = 'https://github.com/carlosmedina06/mirro';

const config: Config = {
  title: 'Mirro',
  tagline: 'Duplica y controla tus teléfonos Android desde la barra de estado de tu Mac.',
  favicon: 'img/favicon.png',

  future: {
    v4: true,
  },

  // GitHub Pages: https://carlosmedina06.github.io/mirro/
  url: 'https://carlosmedina06.github.io',
  baseUrl: '/mirro/',
  organizationName: 'carlosmedina06',
  projectName: 'mirro',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'es',
    locales: ['es'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: `${GITHUB}/tree/main/website/`,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/icon.png',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Mirro',
      logo: {
        alt: 'Mirro',
        src: 'img/icon.png',
      },
      items: [
        {type: 'docSidebar', sidebarId: 'docs', position: 'left', label: 'Documentación'},
        {to: '/docs/instalacion', label: 'Instalar', position: 'left'},
        {href: GITHUB, label: 'GitHub', position: 'right'},
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentación',
          items: [
            {label: 'Instalación', to: '/docs/instalacion'},
            {label: 'Preparar el teléfono', to: '/docs/preparar-telefono'},
            {label: 'Solución de problemas', to: '/docs/problemas'},
          ],
        },
        {
          title: 'Proyecto',
          items: [
            {label: 'GitHub', href: GITHUB},
            {label: 'Releases', href: `${GITHUB}/releases`},
            {label: 'Reportar un problema', href: `${GITHUB}/issues`},
          ],
        },
        {
          title: 'Créditos',
          items: [
            {label: 'scrcpy', href: 'https://github.com/Genymobile/scrcpy'},
            {label: 'Android Platform Tools', href: 'https://developer.android.com/tools/releases/platform-tools'},
          ],
        },
      ],
      copyright: `© ${new Date().getFullYear()} Carlos Medina · MIT · Mirro no está afiliada a Genymobile ni a Google.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
