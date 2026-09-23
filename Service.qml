import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property bool installed: false
  property bool installing: false
  property bool running: false
  property bool stopping: false
  property string statusText: "checking..."

  Component.onCompleted: {
    checkInstalled()
    checkRunning()
  }

  function checkInstalled() {
    probeProc.command = ["sh", "-c", "command -v nostr-station >/dev/null 2>&1 && echo yes || echo no"]
    probeProc.running = true
  }

  function checkRunning() {
    var cmd = "if [ -f \"$HOME/.config/nostr-station/chat.pid\" ]; then PID=$(cat \"$HOME/.config/nostr-station/chat.pid\"); if kill -0 \"$PID\" 2>/dev/null; then echo running; else echo stopped; fi; else echo stopped; fi"
    runningProbeProc.command = ["sh", "-c", cmd]
    runningProbeProc.running = true
  }

  function start() {
    if (installing) return "installing"
    if (stopping) return "stopping"
    if (running) return "already running"
    if (!installed) {
      install()
      return "installing"
    }
    // Prefer the explicit install path so we don't depend on PATH/nvm being
    // inherited exactly the same way by every Quickshell Process spawn.
    serverProc.command = [
      "sh", "-c",
      "NODE22=$(mise where node@22 2>/dev/null || true); " +
      "if [ -n \"$NODE22\" ] && [ -x \"$NODE22/bin/node\" ]; then export PATH=\"$NODE22/bin:$PATH\"; fi; " +
      "exec \"$HOME/nostr-station/bin/nostr-station.sh\" serve 2>/dev/null || exec nostr-station serve"
    ]
    serverProc.running = true
    running = true
    statusText = "starting..."
    runningTimer.start()
    return "starting"
  }

  function stop() {
    if (!running) return "not running"
    stopping = true
    statusText = "stopping..."
    stopProc.command = [
      "sh", "-c",
      "\"$HOME/nostr-station/bin/nostr-station.sh\" stop 2>/dev/null || nostr-station stop"
    ]
    stopProc.running = true
    return "stopping"
  }

  function restart() {
    if (running || stopping) {
      restartPending = true
      return stop()
    }
    return start()
  }

  function open() {
    Quickshell.execDetached(["omarchy-launch-webapp", "http://localhost:3000"])
    return "opened"
  }

  function openSetup() {
    Quickshell.execDetached(["omarchy-launch-webapp", "http://localhost:3000/setup"])
    return "opened setup"
  }

  function install() {
    installing = true
    statusText = "installing nostr-station..."
    installProc.command = [
      "sh", "-c",
      "curl -fsSL https://raw.githubusercontent.com/jared-logan/omarchy-nostr-station/main/install.sh | bash"
    ]
    installProc.running = true
  }

  property bool restartPending: false

  Timer {
    id: runningTimer
    interval: 3000
    repeat: false
    onTriggered: {
      if (root.running) root.statusText = "running"
    }
  }

  Process {
    id: probeProc
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        root.installed = (line.trim() === "yes")
        if (!root.running) {
          root.statusText = root.installed ? "installed, stopped" : "not installed"
        }
      }
    }
  }

  Process {
    id: runningProbeProc
    running: false
    stdout: SplitParser {
      onRead: (line) => {
        var wasRunning = (line.trim() === "running")
        if (wasRunning && !root.running) {
          root.running = true
          root.statusText = "running"
        }
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
      root.stopping = false
      runningTimer.stop()
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
    function openSetup(): string { return root.openSetup() }
    function status(): string {
      return JSON.stringify({
        installed: root.installed,
        running: root.running,
        stopping: root.stopping,
        installing: root.installing,
        statusText: root.statusText
      })
    }
  }
}
