import Sortable from "../../vendor/sortable";

/**
 * Hook for reordering elements using drag and drop.
 *
 * This hook uses the Sortable library to make list elements sortable.
 *
 * ## Usage
 *
 * Add `phx-hook="Sortable"` to the element you want to make sortable.
 * You'll also need to add a `data-group` attribute to the element.
 *
 * ```eex
 * <ul phx-hook="Sortable" id="lesson-list" data-group="lesson-list">
 *  <li :for={{lesson} <- lessons}>
 *    <%= lesson.title %>
 *  </li>
 * </ul>
 * ```
 *
 * Then, you'll need to handle the reposition event in your LiveView
 * using the `reposition` event.
 *
 * ```elixir
 * def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) do
 *  # Handle the reordering of the elements here.
 * end
 * ```
 */
export default {
  mounted() {
    const group = this.el.dataset.group;
    let isDragging = false;

    this.el.addEventListener("focusout", (e) => isDragging && e.stopImmediatePropagation());

    new Sortable(this.el, {
      group: group ? { name: group, pull: true, put: true } : undefined,
      animation: 150,
      filter: ".filtered",
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      onStart: (e) => (isDragging = true), // prevent phx-blur from firing while dragging
      onEnd: (e) => {
        isDragging = false;

        const params = {
          old: e.oldIndex,
          new: e.newIndex,
          to: e.to.dataset,
          ...e.item.dataset,
        };

        this.pushEventTo(this.el, this.el.dataset["drop"] || "reposition", params);
      },
    });
  },
};
