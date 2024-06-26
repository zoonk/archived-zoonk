/**
 * Clears a Phoenix Flash message after a certain period of time.
 *
 * This is useful when we don't want to keep the flash message around for too long
 * or when we don't want to annoy the user with a message that doesn't disappear.
 *
 * ## Usage
 *
 * - Add `phx-hook="ClearFlash"` to the element that contains the flash message.
 * - Add a `data-kind` attribute to the element. This is used to identify the flash message.
 *
 * ```html
 * <div phx-hook="ClearFlash" data-kind={:info}>Your changes have been saved.</div>
 * ```
 */
export default {
  mounted() {
    const kind = this.el.dataset.kind;

    /** delay in ms */
    const delay = 5000;

    // Make the element invisible after the delay.
    setTimeout(() => this.el.classList.add("opacity-0"), delay);

    // Make sure we also clear the flash. Otherwise, it will be displayed for other items too.
    // We clear it 1s after the element is hidden.
    setTimeout(() => this.pushEventTo("#" + this.el.id, "lv:clear-flash", { key: kind }), delay + 1000);
  },
};
