# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Avatar do
  @moduledoc """
  Image components.
  """
  use Phoenix.Component

  @doc """
  Renders an avatar element.

  ## Examples

      <.avatar alt="John Doe" />
      <.avatar alt="John Doe" src="https://example.com/image.jpg" />
  """
  attr :src, :string, default: nil, doc: "the image source"
  attr :alt, :string, required: true, doc: "the image alt text. It can be used as a fallback if the image is not available."
  attr :size, :atom, values: [:small, :medium, :large], default: :medium, doc: "the size of the avatar"
  attr :class, :string, default: nil, doc: "the class of the avatar"

  # Handle the case where the image is not available.
  def avatar(%{src: nil} = assigns) do
    ~H"""
    <div class={["bg-indigo-500", avatar_class(@size, @class)]} title={@alt}><%= avatar_label(@alt) %></div>
    """
  end

  # Handle the case where the image is available.
  def avatar(%{src: src} = assigns) when is_binary(src) do
    ~H"""
    <img src={@src} class={avatar_class(@size, @class)} alt={@alt} />
    """
  end

  defp avatar_class(size, class) do
    [
      "flex-shrink-0 rounded-full uppercase text-white text-xs object-cover flex items-center justify-center flex-column font-semibold",
      size == :small && "h-5 w-5",
      size == :medium && "h-8 w-8",
      size == :large && "w-10 h-10",
      class
    ]
  end

  defp avatar_label(label) when is_binary(label), do: String.first(label)
  defp avatar_label(label) when is_number(label), do: label
end
