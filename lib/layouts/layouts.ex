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
  alias Uneebee.Organizations.SchoolUser
  alias UneebeeWeb.Components.Layouts.CourseSelect
  alias UneebeeWeb.Components.Layouts.LessonSelect

  embed_templates "templates/*"

  @spec social_image(String.t() | nil, School.t() | nil) :: String.t()
  def social_image(nil, school), do: school_logo(school)
  def social_image(img, _school), do: img

  @spec page_title(String.t() | nil, School.t() | nil) :: String.t()
  def page_title(nil, school), do: school_name(school)
  def page_title(title, _school), do: title

  @spec plausible_domain(School.t()) :: String.t() | nil
  def plausible_domain(%School{} = app), do: app.custom_domain
  def plausible_domain(_school), do: nil

  @spec enable_plausible?(SchoolUser.t() | nil) :: boolean()
  def enable_plausible?(%SchoolUser{} = school_user), do: school_user.analytics?
  def enable_plausible?(nil), do: false
end
