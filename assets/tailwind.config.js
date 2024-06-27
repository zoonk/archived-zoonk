// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const colors = require("tailwindcss/colors");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*.ex", "../lib/**/*.*ex"],
  theme: {
    extend: {
      screens: {
        "3xl": "1800px",
        "4xl": "2100px",
        "5xl": "2400px",
        "6xl": "2700px",
        "7xl": "3000px",
      },
      boxShadow: {
        "b-gray": `3px 3px 0px 0px ${colors.gray[300]}`,
        "b-gray-pressed": `1px 1px 0px 0px ${colors.gray[300]}`,
        "b-cyan": `3px 3px 0px 0px ${colors.cyan[300]}`,
        "b-cyan-pressed": `1px 1px 0px 0px ${colors.cyan[300]}`,
        "b-teal": `3px 3px 0px 0px ${colors.teal[300]}`,
        "b-teal-pressed": `1px 1px 0px 0px ${colors.teal[300]}`,
        "b-pink": `3px 3px 0px 0px ${colors.pink[300]}`,
        "b-pink-pressed": `1px 1px 0px 0px ${colors.pink[300]}`,
        "b-indigo": `3px 3px 0px 0px ${colors.indigo[300]}`,
        "b-indigo-pressed": `1px 1px 0px 0px ${colors.indigo[300]}`,
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/container-queries"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
    plugin(({ addVariant }) => addVariant("drag-item", [".drag-item&", ".drag-item &"])),
    plugin(({ addVariant }) => addVariant("drag-ghost", [".drag-ghost&", ".drag-ghost &"])),

    // Embeds Tabler Icons (https://tabler-icons.io/) into your app.css bundle
    plugin(function ({ matchComponents, theme }) {
      const iconsDir = path.join(__dirname, "./vendor/tabler/icons");
      const values = {};
      const icons = [["", ""]];

      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          const name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });

      matchComponents(
        {
          tabler: ({ name, fullPath }) => {
            const content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");

            return {
              [`--tabler-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--tabler-${name})`,
              mask: `var(--tabler-${name})`,
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
