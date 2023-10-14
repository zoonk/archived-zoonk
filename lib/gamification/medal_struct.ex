defmodule Uneebee.Gamification.Medal do
  @moduledoc """
  Struct for defining a medal.

  This is used to track supported medals.
  """
  @type t :: %__MODULE__{key: atom(), medal: atom(), label: String.t(), description: String.t()}

  defstruct key: nil, medal: :bronze, label: "", description: ""
end
