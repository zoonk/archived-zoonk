# Seeding the data

## Arguments

| Argument     | Description                                                        | Options               | Default       |
| ------------ | ------------------------------------------------------------------ | --------------------- | ------------- |
| `--kind`     | The kind of data to seed.                                          | `saas`, `white_label` | `white_label` |
| `--multiple` | Create multiple items. This is ideal when testing infinite scroll. | `boolean`             | `false`       |

## Examples

```sh
mix seed
mix seed --kind=saas
mix seed --kind=saas --multiple
```
