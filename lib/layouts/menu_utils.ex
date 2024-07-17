defmodule ZoonkWeb.Layouts.MenuUtils do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.Course
  alias Zoonk.Organizations.School
  alias Zoonk.Storage

  @spec school_name(School.t() | nil) :: String.t()
  def school_name(nil), do: "Zoonk"
  def school_name(%School{} = school), do: school.name

  @spec school_logo(School.t() | nil, School.t() | nil) :: String.t()
  def school_logo(nil, _app), do: ~p"/images/logo.svg"
  def school_logo(%School{logo: nil}, nil), do: school_logo(nil, nil)
  def school_logo(%School{logo: nil}, %School{logo: nil}), do: school_logo(nil, nil)
  def school_logo(%School{logo: nil}, %School{logo: logo}), do: Storage.get_url(logo)
  def school_logo(%School{} = school, _app), do: Storage.get_url(school.logo)

  @spec school_icon(School.t() | nil, School.t() | nil, non_neg_integer()) :: String.t()
  def school_icon(nil, _app, size), do: "/favicon/#{size}.png"
  def school_icon(%School{icon: nil}, nil, size), do: school_icon(nil, nil, size)
  def school_icon(%School{icon: nil}, %School{icon: nil}, size), do: school_icon(nil, nil, size)
  def school_icon(%School{icon: nil}, %School{icon: icon}, _size), do: Storage.get_url(icon)
  def school_icon(%School{} = school, _app, _size), do: Storage.get_url(school.icon)

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
        :dashboard_lessoneditor_option,
        :dashboard_lessoneditor_option_img,
        :dashboard_lessoneditor_step_img,
        :dashboard_lessoneditor_edit,
        :dashboard_lessoneditor_edit_step,
        :dashboard_lessoneditor_cover
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

  @spec dashboard_school_menu(School.t()) :: list()
  def dashboard_school_menu(%School{school_id: school_id}) do
    [
      %{link: ~p"/dashboard", view: [:dashboard_home], title: gettext("Overview"), visible?: true},
      %{link: ~p"/dashboard/schools", view: [:dashboard_schoollist, :dashboard_schoolview], title: gettext("Schools"), visible?: is_nil(school_id)},
      %{link: ~p"/dashboard/users", view: [:dashboard_schooluserlist, :dashboard_schooluserview], title: dgettext("orgs", "Users"), visible?: true},
      %{link: ~p"/dashboard/edit/logo", view: [:dashboard_schooledit_logo], title: gettext("Logo"), visible?: true},
      %{link: ~p"/dashboard/edit/icon", view: [:dashboard_schooledit_icon], title: gettext("Icon"), visible?: true},
      %{link: ~p"/dashboard/edit/settings", view: [:dashboard_schooledit_settings], title: gettext("Settings"), visible?: true},
      %{link: ~p"/dashboard/edit/delete", view: [:dashboard_schooledit_delete], title: gettext("Delete"), visible?: !is_nil(school_id)}
    ]
  end
end
