defmodule Uneebee.Repo.Migrations.AddValueToExistingStepIdOnUserSelections do
  use Ecto.Migration

  import Ecto.Query

  alias Uneebee.Content.UserSelection
  alias Uneebee.Repo

  def change do
    # Add a default value to the `step_id` on existing records.
    # Use the `step_id` of the current %StepOption{} record.
    selections = UserSelection |> preload(:option) |> Repo.all()

    Enum.each(selections, fn selection ->
      step_id = selection.option.lesson_step_id

      selection
      |> UserSelection.changeset(%{step_id: step_id})
      |> Repo.update!()
    end)
  end
end
