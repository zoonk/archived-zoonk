defmodule Zoonk.Repo.Migrations.AllowNullOptionIdOnUserSelections do
  use Ecto.Migration

  def change do
    drop constraint(:user_selections, "user_selections_option_id_fkey")

    alter table(:user_selections) do
      modify :option_id, references(:step_options, on_delete: :delete_all), null: true
    end
  end
end
