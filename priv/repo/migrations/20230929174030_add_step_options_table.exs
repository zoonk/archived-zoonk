defmodule Zoonk.Repo.Migrations.AddStepOptionsTable do
  use Ecto.Migration

  def change do
    create table(:step_options) do
      add :correct?, :boolean, default: false, null: false
      add :feedback, :string
      add :image, :string
      add :lesson_step_id, references(:lesson_steps, on_delete: :delete_all), null: false
      add :title, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
