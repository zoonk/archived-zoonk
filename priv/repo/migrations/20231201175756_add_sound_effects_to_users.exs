defmodule Uneebee.Repo.Migrations.AddSoundEffectsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :sound_effects?, :boolean, default: false, null: false
    end
  end
end
