defmodule UneebeeWeb.Layouts do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.AppMenu
  import UneebeeWeb.Components.Layouts.DashboardMenuItem
  import UneebeeWeb.Components.Layouts.GamificationMenu
  import UneebeeWeb.Components.Layouts.MenuDesktop
  import UneebeeWeb.Components.Layouts.MenuMobile
  import UneebeeWeb.Layouts.MenuUtils

  alias Uneebee.Organizations.School
  alias UneebeeWeb.Components.Layouts.CourseSelect
  alias UneebeeWeb.Components.Layouts.LessonSelect

  embed_templates "templates/*"

  @spec social_image(String.t() | nil, School.t() | nil) :: String.t()
  def social_image(nil, school), do: school_logo(school)
  def social_image(img, _school), do: img

  @spec page_title(String.t() | nil, School.t() | nil) :: String.t()
  def page_title(nil, school), do: school_name(school)
  def page_title(title, _school), do: title

  @spec plausible_domain() :: String.t() | nil
  def plausible_domain do
    Application.get_env(:uneebee, :plausible)[:domain]
  end

  @spec enable_plausible?(map()) :: boolean()
  def enable_plausible?(assigns) do
    manager? = assigns[:user_role] == :manager

    # Only the main school doesn't belong to another school and, therefore, doesn't have a school_id.
    main_school? = is_nil(school_id(assigns[:school]))

    # We shouldn't track managers from the main school to avoid skewing the data.
    track_user? = not main_school? or not manager?

    track_user? and not is_nil(plausible_domain())
  end

  defp school_id(nil), do: nil
  defp school_id(%School{} = school), do: school.school_id
end
