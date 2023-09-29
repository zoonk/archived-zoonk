defmodule UneebeeWeb.PermissionError do
  @moduledoc """
  Raises a permission error with a 403 status code.
  """
  import UneebeeWeb.Gettext

  defexception [:message, :code, plug_status: 403]

  @impl Exception
  def exception(code: :school_already_configured),
    do: %__MODULE__{message: dgettext("errors", "School already configured")}

  def exception(code: :require_manager),
    do: %__MODULE__{message: dgettext("errors", "Only managers can view this page")}

  def exception(code: :require_manager_or_teacher),
    do: %__MODULE__{message: dgettext("errors", "Only managers and teachers can view this page")}

  def exception(code: :not_enrolled),
    do: %__MODULE__{message: dgettext("errors", "You are not enrolled in this course")}

  def exception(code: :pending_approval),
    do: %__MODULE__{message: dgettext("errors", "Your enrollment is pending approval")}

  def exception(message: message), do: %__MODULE__{message: message}
end
