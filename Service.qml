import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool installed: false
  property bool installing: false
  property bool running: false
  property string statusText: "checking..."

  Component.onCompleted: checkInstalled()

  function checkInstalled() {
    probeProc.command = ["sh", "-c", "command -v nostr-station >/dev/null 2>&1 && echo yes || echo no"]
    probeProc.running = true
  }

  function start() {
    if (installing) return "installing"
    if (running) return "already running"
    if (!installed) {
      install()
      return "installing"
    }
    // Prefer the explicit install path so we don't depend on PATH/nvm being
    // inherited exactly the same way by every Quickshell Process spawn.
    serverProc.command = [
      "sh", "-c",
      "exec \"$HOME/nostr-station/bin/nostr-station.sh\" serve 2>/dev/null || exec nostr-station serve"
    ]
    serverProc.running = true
    running = true
    statusText = "starting..."
    return "starting"
  }

  function stop() {
    if (!running) return "not running"
    stopProc.command = [
      "sh", "-c",
      "\"$HOME/nostr-station/bin/nostr-station.sh\" stop 2>/dev/null || nostr-station stop"
    ]
    stopProc.running = true
    statusText = "stopping..."
    return "stopping"
  }

  function restart() {
    if (running) {
      restartPending = true
      return stop()
    }
    return start()
  }

  function open() {
    Quickshell.execDetached(["omarchy-launch-webapp", "http://localhost:3000"])
    return "opened"
  }

  function install() {
    installing = true
    statusText = "installing nostr-station..."
    installProc.command = [
      "sh", "-c",
      "curl -fsSL https://raw.githubusercontent.com/jared-logan/nostr-station/main/install.sh | bash"
    ]
    installProc.running = true
  }

  property bool restartPending: false

  Process {
    id: probeProc
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        root.installed = (line.trim() === "yes")
        root.statusText = root.installed ? "installed, stopped" : "not installed"
      }
    }
  }

  Process {
    id: installProc
    running: false
    stdout: SplitParser {
      onRead: (line) => { console.log("[nostr-station install]", line) }
    }
    stderr: SplitParser {
      onRead: (line) => { console.warn("[nostr-station install]", line) }
    }
    onExited: (code, status) => {
      root.installing = false
      if (code === 0) {
        root.installed = true
        root.statusText = "installed, starting..."
        root.start()
      } else {
        root.statusText = "install failed"
        root.running = false
      }
    }
  }

  Process {
    id: serverProc
    running: false
    stdout: SplitParser {
      onRead: (line) => { console.log("[nostr-station]", line) }
    }
    stderr: SplitParser {
      onRead: (line) => { console.warn("[nostr-station]", line) }
    }
    onExited: (code, status) => {
      root.running = false
      root.statusText = root.installed ? "installed, stopped" : "not installed"
      if (root.restartPending) {
        root.restartPending = false
        root.start()
      }
    }
  }

  Process {
    id: stopProc
    running: false
    onExited: (code, status) => {
      // serverProc.onExited will set running = false
    }
  }

  IpcHandler {
    target: "nostr.station"

    function start(): string { return root.start() }
    function stop(): string { return root.stop() }
    function restart(): string { return root.restart() }
    function open(): string { return root.open() }
    function status(): string {
      return JSON.stringify({
        installed: root.installed,
        running: root.running,
        installing: root.installing,
        statusText: root.statusText
      })
    }
  }
}
