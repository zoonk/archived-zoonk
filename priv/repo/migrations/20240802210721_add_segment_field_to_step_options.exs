defmodule Zoonk.Repo.Migrations.AddSegmentFieldToStepOptions do
  use Ecto.Migration

  def change do
    alter table(:step_options) do
      add :segment, :integer
    end
  end
end
