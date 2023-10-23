defmodule UneebeeWeb.Layouts.MenuUtils do
  @moduledoc false
  @spec user_settings?(atom()) :: boolean()
  def user_settings?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("usersettings")
  end

  @spec school_edit?(atom()) :: boolean()
  def school_edit?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_schooledit")
  end

  @spec school_user_list?(atom()) :: boolean()
  def school_user_list?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_userlist")
  end

  @spec course?(atom()) :: boolean()
  def course?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_course")
  end

  @spec course_view?(atom()) :: boolean()
  def course_view?(active_page) do
    view? = active_page |> Atom.to_string() |> String.starts_with?("dashboard_courseview")
    view? or course_edit?(active_page) or course_user_list?(active_page) or course_student_view?(active_page)
  end

  @spec lesson_view?(atom()) :: boolean()
  def lesson_view?(active_page) do
    option? = active_page in [:dashboard_lessonview_option, :dashboard_lessonview_option_img, :dashboard_lessonview_step_img, :dashboard_lessonview_edit]
    lesson_view_page? = active_page |> Atom.to_string() |> String.starts_with?("dashboard_lesson")
    option? or lesson_view_page?
  end

  @spec dashboard?(atom()) :: boolean()
  def dashboard?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard")
  end

  defp course_user_list?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_courseuserlist")
  end

  defp course_student_view?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_coursestudentview")
  end

  defp course_edit?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard_courseedit")
  end
end
