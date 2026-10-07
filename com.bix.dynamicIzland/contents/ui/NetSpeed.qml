import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

// Network throughput, sampled from /proc/net/dev once per second.
// Ported from the standalone netspeedmonitor plasmoid. Sampling only runs while
// `active` is true, so an idle/hidden island does not spawn a process every second.
Item {
    id: net

    property bool active: true

    property real rxSpeed: 0   // bytes/s
    property real txSpeed: 0   // bytes/s
    readonly property string text: "↓ " + formatSpeed(rxSpeed) + "  ↑ " + formatSpeed(txSpeed)

    property real _prevRx: -1
    property real _prevTx: -1

    function formatSpeed(bytes) {
        if (bytes >= 1048576)
            return (bytes / 1048576).toFixed(1) + " MB/s";
        if (bytes >= 1024)
            return Math.round(bytes / 1024) + " KB/s";
        return Math.round(bytes) + " B/s";
    }

    // Skip loopback and virtual bridges/containers so traffic isn't counted twice.
    function isRealInterface(name) {
        return name !== "lo"
            && name.indexOf("docker") !== 0
            && name.indexOf("veth") !== 0
            && name.indexOf("br-") !== 0
            && name.indexOf("virbr") !== 0;
    }

    function parse(text) {
        const lines = text.split("\n");
        let totalRx = 0;
        let totalTx = 0;
        for (let i = 2; i < lines.length; i++) {
            const line = lines[i].trim();
            const colon = line.indexOf(":");
            if (colon < 0 || !isRealInterface(line.substring(0, colon).trim()))
                continue;
            const parts = line.substring(colon + 1).trim().split(/\s+/);
            if (parts.length < 9)
                continue;
            totalRx += parseInt(parts[0], 10) || 0;
            totalTx += parseInt(parts[8], 10) || 0;
        }
        // The timer fires every second, so the counter delta is already bytes/s.
        if (_prevRx >= 0) {
            rxSpeed = Math.max(0, totalRx - _prevRx);
            txSpeed = Math.max(0, totalTx - _prevTx);
        }
        _prevRx = totalRx;
        _prevTx = totalTx;
    }

    onActiveChanged: {
        if (!active) {
            // Drop stale counters so the first sample after resuming isn't a huge delta.
            _prevRx = -1;
            _prevTx = -1;
            rxSpeed = 0;
            txSpeed = 0;
        }
    }

    Plasma5Support.DataSource {
        id: source

        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            if (data["exit code"] === 0 && net.active)
                net.parse(data["stdout"]);
        }
    }

    Timer {
        interval: 1000
        running: net.active
        repeat: true
        triggeredOnStart: true
        onTriggered: source.connectSource("cat /proc/net/dev")
    }
}
