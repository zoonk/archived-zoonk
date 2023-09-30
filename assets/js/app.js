// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';
import Sortable from '../vendor/sortable';

function playSound(url) {
  new Audio(url).play();
}

let Hooks = {};

Hooks.LocaleTime = {
  mounted() {
    let dt = new Date(this.el.textContent);
    this.el.textContent = dt.toLocaleString();
  },
};

Hooks.LessonSoundEffect = {
  mounted() {
    this.handleEvent('option-selected', ({ isCorrect }) => {
      const fileName = isCorrect ? '/correct.mp3' : '/incorrect.mp3';
      playSound('/audios' + fileName);
    });
  },
};

Hooks.Sortable = {
  mounted() {
    let group = this.el.dataset.group;
    let isDragging = false;
    this.el.addEventListener(
      'focusout',
      (e) => isDragging && e.stopImmediatePropagation()
    );
    let sorter = new Sortable(this.el, {
      group: group ? { name: group, pull: true, put: true } : undefined,
      animation: 150,
      dragClass: 'drag-item',
      ghostClass: 'drag-ghost',
      onStart: (e) => (isDragging = true), // prevent phx-blur from firing while dragging
      onEnd: (e) => {
        isDragging = false;
        let params = {
          old: e.oldIndex,
          new: e.newIndex,
          to: e.to.dataset,
          ...e.item.dataset,
        };
        this.pushEventTo(
          this.el,
          this.el.dataset['drop'] || 'reposition',
          params
        );
      },
    });
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');
let liveSocket = new LiveSocket('/live', Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
