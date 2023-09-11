// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require('tailwindcss/plugin');
const fs = require('fs');
const path = require('path');

module.exports = {
  content: ['./js/**/*.js', '../lib/*_web.ex', '../lib/*_web/**/*.*ex'],
  theme: {},
  plugins: [
    require('@tailwindcss/forms'),
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
