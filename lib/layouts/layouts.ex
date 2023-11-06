defmodule UneebeeWeb.Layouts do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.AppMenu
  import UneebeeWeb.Components.Layouts.DashboardMenuItem
  import UneebeeWeb.Components.Layouts.GamificationMenu
  import UneebeeWeb.Components.Layouts.MenuDesktop
  import UneebeeWeb.Components.Layouts.MenuMobile
  import UneebeeWeb.Components.Layouts.UserMenu
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
end
