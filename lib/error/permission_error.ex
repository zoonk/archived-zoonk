defmodule UneebeeWeb.PermissionError do
  @moduledoc """
  Raises a permission error with a 403 status code.
  """
  defexception [:message, :code, plug_status: 403]

  @impl Exception
  def exception(code: :school_already_configured), do: %__MODULE__{message: "School already configured"}
  def exception(code: :require_manager), do: %__MODULE__{message: "Only managers can view this page"}
  def exception(message: message), do: %__MODULE__{message: message}
end
