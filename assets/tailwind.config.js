// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require('tailwindcss/plugin');
const colors = require('tailwindcss/colors');
const fs = require('fs');
const path = require('path');

module.exports = {
  content: ['./js/**/*.js', '../lib/*.ex', '../lib/**/*.*ex'],
  theme: {
    extend: {
      screens: {
        '3xl': '1800px',
        '4xl': '2100px',
        '5xl': '2400px',
        '6xl': '2700px',
        '7xl': '3000px',
      },
      colors: {
        alert: {
          light3x: colors.pink[50],
          light2x: colors.pink[100],
          light: colors.pink[300],
          DEFAULT: colors.pink[500],
          dark: colors.pink[700],
          dark2x: colors.pink[900],
        },
        info: {
          light3x: colors.cyan[50],
          light2x: colors.cyan[100],
          light: colors.cyan[300],
          DEFAULT: colors.cyan[500],
          dark: colors.cyan[700],
          dark2x: colors.cyan[900],
        },
        success: {
          light3x: colors.teal[50],
          light2x: colors.teal[100],
          light: colors.teal[300],
          DEFAULT: colors.teal[500],
          dark: colors.teal[700],
          dark2x: colors.teal[900],
        },
        warning: {
          light3x: colors.amber[50],
          light2x: colors.amber[100],
          light: colors.amber[300],
          DEFAULT: colors.amber[500],
          dark: colors.amber[700],
          dark2x: colors.amber[900],
        },
        gray: {
          light3x: colors.slate[50],
          light2x: colors.slate[100],
          light: colors.slate[300],
          DEFAULT: colors.slate[500],
          dark: colors.slate[700],
          dark2x: colors.slate[900],
        },
        bronze: {
          light3x: colors.orange[50],
          light2x: colors.orange[100],
          light: colors.orange[300],
          DEFAULT: colors.orange[500],
          dark: colors.orange[700],
          dark2x: colors.orange[900],
        },
        white: {
          DEFAULT: colors.white,
          dark: colors.slate[100],
        },
      },
      boxShadow: {
        'b-gray-light': `3px 3px 0px 0px ${colors.slate[100]}`,
        'b-gray-light-pressed': `1px 1px 0px 0px ${colors.slate[100]}`,
        'b-gray': `3px 3px 0px 0px ${colors.slate[300]}`,
        'b-gray-pressed': `1px 1px 0px 0px ${colors.slate[300]}`,
        'b-gray-dark': `3px 3px 0px 0px ${colors.slate[700]}`,
        'b-gray-dark-pressed': `1px 1px 0px 0px ${colors.slate[700]}`,
        'b-info-light': `3px 3px 0px 0px ${colors.cyan[100]}`,
        'b-info-light-pressed': `1px 1px 0px 0px ${colors.cyan[100]}`,
        'b-info': `3px 3px 0px 0px ${colors.cyan[300]}`,
        'b-info-pressed': `1px 1px 0px 0px ${colors.cyan[300]}`,
        'b-info-dark': `3px 3px 0px 0px ${colors.cyan[700]}`,
        'b-info-dark-pressed': `1px 1px 0px 0px ${colors.cyan[700]}`,
        'b-success-light': `3px 3px 0px 0px ${colors.teal[100]}`,
        'b-success-light-pressed': `1px 1px 0px 0px ${colors.teal[100]}`,
        'b-success': `3px 3px 0px 0px ${colors.teal[300]}`,
        'b-success-pressed': `1px 1px 0px 0px ${colors.teal[300]}`,
        'b-success-dark': `3px 3px 0px 0px ${colors.teal[700]}`,
        'b-success-dark-pressed': `1px 1px 0px 0px ${colors.teal[700]}`,
        'b-warning-light': `3px 3px 0px 0px ${colors.amber[100]}`,
        'b-warning-light-pressed': `1px 1px 0px 0px ${colors.amber[100]}`,
        'b-warning': `3px 3px 0px 0px ${colors.amber[300]}`,
        'b-warning-pressed': `1px 1px 0px 0px ${colors.amber[300]}`,
        'b-warning-dark': `3px 3px 0px 0px ${colors.amber[700]}`,
        'b-warning-dark-pressed': `1px 1px 0px 0px ${colors.amber[700]}`,
        'b-alert-light': `3px 3px 0px 0px ${colors.pink[100]}`,
        'b-alert-light-pressed': `1px 1px 0px 0px ${colors.pink[100]}`,
        'b-alert': `3px 3px 0px 0px ${colors.pink[300]}`,
        'b-alert-pressed': `1px 1px 0px 0px ${colors.pink[300]}`,
        'b-alert-dark': `3px 3px 0px 0px ${colors.pink[700]}`,
        'b-alert-dark-pressed': `1px 1px 0px 0px ${colors.pink[700]}`,
      },
      animation: {
        'slide-up': 'slide-up 0.5s ease-out forwards',
      },
      keyframes: {
        'slide-up': {
          '0%': { transform: 'translateY(100%)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/container-queries'),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant('phx-no-feedback', ['.phx-no-feedback&', '.phx-no-feedback &'])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('drag-item', ['.drag-item&', '.drag-item &'])
    ),
    plugin(({ addVariant }) =>
      addVariant('drag-ghost', ['.drag-ghost&', '.drag-ghost &'])
    ),

    // Embeds Tabler Icons (https://tabler-icons.io/) into your app.css bundle
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, './vendor/tabler/icons');
      let values = {};
      let icons = [['', '']];

      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, '.svg') + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });

      matchComponents(
        {
          tabler: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '');
            return {
              [`--tabler-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              '-webkit-mask': `var(--tabler-${name})`,
              mask: `var(--tabler-${name})`,
              'background-color': 'currentColor',
              'vertical-align': 'middle',
              display: 'inline-block',
              width: theme('spacing.5'),
              height: theme('spacing.5'),
            };
          },
        },
        { values }
      );
    }),
  ],
};
