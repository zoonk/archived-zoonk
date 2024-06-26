/**
 * Hook for reordering elements using drag and drop.
 *
 * This hook uses the Sortable library to make list elements sortable.
 *
 * @example
 * <ul phx-hook="Sortable" id="lesson-list" data-group="lesson-list">
 *  <li :for={{lesson} <- @lessons}>
 *    <%= lesson.title %>
 *  </li>
 * </ul>
 *
 * def handle_event("reposition", %{"new" => new_index, "old_index" => old_index}, socket) do
 *  # Handle the reordering of the elements here.
 * end
 */

import Sortable from "../../vendor/sortable";

export default {
  mounted() {
    let group = this.el.dataset.group;
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

        let params = {
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
