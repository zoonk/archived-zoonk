defmodule UneebeeWeb.Layouts.MenuUtils do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.Course
  alias Uneebee.Organizations.School

  @spec school_name(School.t() | nil) :: String.t()
  def school_name(nil), do: "UneeBee"
  def school_name(%School{} = school), do: school.name

  @spec school_logo(School.t() | nil) :: String.t()
  def school_logo(nil), do: ~p"/images/logo.svg"
  def school_logo(%School{logo: nil}), do: school_logo(nil)
  def school_logo(%School{} = school), do: school.logo

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
    course?(active_page) and active_page != :dashboard_coursenew
  end

  @spec lesson_view?(atom()) :: boolean()
  def lesson_view?(active_page) do
    option? =
      active_page in [
        :dashboard_lessonview_option,
        :dashboard_lessonview_option_img,
        :dashboard_lessonview_step_img,
        :dashboard_lessonview_edit,
        :dashboard_lessonview_edit_step,
        :dashboard_lessonview_cover
      ]

    lesson_view_page? = active_page |> Atom.to_string() |> String.starts_with?("dashboard_lesson")
    option? or lesson_view_page?
  end

  @spec dashboard?(atom()) :: boolean()
  def dashboard?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("dashboard")
  end

  @spec dashboard_school?(atom()) :: boolean()
  def dashboard_school?(active_page) do
    dashboard?(active_page) and not course?(active_page) and not lesson_view?(active_page)
  end

  @spec dashboard_course?(atom()) :: boolean()
  def dashboard_course?(active_page) do
    course_view? = active_page |> Atom.to_string() |> String.starts_with?("dashboard_course")
    course_view? or lesson_view?(active_page)
  end

  @spec show_menu?(atom()) :: boolean()
  def show_menu?(active_page) do
    active_page not in [:lessonplay, :lessoncompleted, :schoolnew]
  end

  @spec home_page?(atom(), Course.t(), String.t()) :: boolean()
  def home_page?(:courseview, %Course{slug: slug}, last_course_slug), do: slug == last_course_slug
  def home_page?(_active_page, _course, _last_course_slug), do: false

  @spec dashboard_school_menu(atom()) :: list()
  def dashboard_school_menu(kind) do
    [
      %{link: ~p"/dashboard", view: :dashboard_home, title: gettext("Overview"), visible?: true},
      %{link: ~p"/dashboard/schools", view: :dashboard_schoollist, title: gettext("Schools"), visible?: kind != :white_label},
      %{link: ~p"/dashboard/managers", view: :dashboard_userlist_manager, title: gettext("Managers"), visible?: true},
      %{link: ~p"/dashboard/teachers", view: :dashboard_userlist_teacher, title: gettext("Teachers"), visible?: true},
      %{link: ~p"/dashboard/students", view: :dashboard_userlist_student, title: gettext("Students"), visible?: true},
      %{link: ~p"/dashboard/edit/logo", view: :dashboard_schooledit_logo, title: gettext("Logo"), visible?: true},
      %{link: ~p"/dashboard/edit/settings", view: :dashboard_schooledit_settings, title: gettext("Settings"), visible?: true}
    ]
  end
end
