defmodule Uneebee.Repo.Migrations.UseTextTypeForOptionFeedback do
  use Ecto.Migration

  def change do
    alter table(:step_options) do
      modify :feedback, :text
    end
  end
end
