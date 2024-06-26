const correctSound = new Audio("/audios/correct.mp3");
const incorrectSound = new Audio("/audios/incorrect.mp3");

function playSound(isCorrect) {
  const sound = isCorrect ? correctSound : incorrectSound;
  sound.play();
}

/**
 * Play sound effect when an option is selected.
 *
 * When a user has enabled sound effects in the settings, this hook will play a
 * feedback sound when an option is selected. It plays different sounds for
 * correct and incorrect answers.
 *
 * ## Usage
 * Add `phx-hook="LessonSoundEffect"` to the form element.
 *
 * ```html
 * <form phx-hook="LessonSoundEffect"></form>
 * ```
 *
 * Then, you'll need to push an `option-selected` event whenever an option is selected.
 * We usually run this on the submit event of the form.
 *
 * ```elixir
 * import Phoenix.LiveView
 *
 * push_event(socket, "option-selected", %{isCorrect: true})
 * push_event(socket, "option-selected", %{isCorrect: false})
 * ```
 */
export default {
  mounted() {
    this.handleEvent("option-selected", ({ isCorrect }) => playSound(isCorrect));
  },
};
