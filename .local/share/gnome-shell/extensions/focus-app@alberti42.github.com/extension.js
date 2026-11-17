// Focus App: let a command-line launcher hand focus to the window it opens.
//
// On Wayland a program started from a terminal has no activation token, so when
// it opens or raises a window, GNOME refuses the focus and shows "<App> is
// ready" instead. Code inside GNOME Shell may activate windows, so this
// extension does it on request:
//
//   gdbus call --session --dest org.gnome.Shell \
//     --object-path /org/gnome/Shell/Extensions/FocusApp \
//     --method org.gnome.Shell.Extensions.FocusApp.Arm sublime_merge.desktop 5000
//
// Arm(appId, timeoutMs): for the next timeoutMs, the first window of appId that
// demands attention is activated; then the request is done. Call it BEFORE
// launching the app, so the request is in place when the window shows up.
// Only windows of appId are touched, and only once per call.

import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const IFACE = `
<node>
  <interface name="org.gnome.Shell.Extensions.FocusApp">
    <method name="Arm">
      <arg type="s" direction="in" name="appId"/>
      <arg type="u" direction="in" name="timeoutMs"/>
    </method>
  </interface>
</node>`;

const OBJECT_PATH = '/org/gnome/Shell/Extensions/FocusApp';
const MAX_TIMEOUT_MS = 60000;

export default class FocusAppExtension extends Extension {
    enable() {
        this._requests = new Map(); // appId -> GLib source id of its timeout
        this._dbus = Gio.DBusExportedObject.wrapJSObject(IFACE, this);
        this._dbus.export(Gio.DBus.session, OBJECT_PATH);

        // Wayland windows "demand attention"; X11 ones may be "marked urgent".
        this._signals = ['window-demands-attention', 'window-marked-urgent'].map(
            name => global.display.connect(name, (_display, win) => this._onAttention(win)));
    }

    disable() {
        this._signals.forEach(id => global.display.disconnect(id));
        this._signals = null;
        this._dbus.unexport();
        this._dbus = null;
        this._requests.forEach(source => GLib.source_remove(source));
        this._requests = null;
    }

    Arm(appId, timeoutMs) {
        this._disarm(appId);
        const ms = Math.min(Math.max(timeoutMs, 1), MAX_TIMEOUT_MS);
        const source = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
            this._requests.delete(appId);
            return GLib.SOURCE_REMOVE;
        });
        this._requests.set(appId, source);
    }

    _disarm(appId) {
        const source = this._requests.get(appId);
        if (source !== undefined) {
            GLib.source_remove(source);
            this._requests.delete(appId);
        }
    }

    _onAttention(win) {
        if (this._requests.size === 0)
            return;
        const app = Shell.WindowTracker.get_default().get_window_app(win);
        const appId = app?.get_id();
        if (!appId || !this._requests.has(appId))
            return;
        this._disarm(appId);
        Main.activateWindow(win);
    }
}
