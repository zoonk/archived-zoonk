# Seeding the data

## Arguments

| Argument     | Description               | Options               | Default       | Notes                           |
| ------------ | ------------------------- | --------------------- | ------------- | ------------------------------- |
| `--kind`     | The kind of data to seed. | `saas`, `white_label` | `white_label` |                                 |
| `--multiple` | Create multiple schools.  | `boolean`             | `false`       | Ignored for `white_label` kind. |

## Examples

```sh
mix seed
mix seed --kind=saas
mix seed --kind=saas --multiple
```
