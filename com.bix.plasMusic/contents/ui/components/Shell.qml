import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

// Small helper around the "executable" data engine.
// Plasma 6 forbids XMLHttpRequest on file:// and has no process API in QML,
// so curl / cat / launching programs all go through here.
//   shell.run("some command", function (stdout, exitCode, stderr) { ... })
Plasma5Support.DataSource {
    id: root

    property var callbacks: ({})
    property int seq: 0

    function quote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    function run(cmd, callback) {
        // The unique trailing comment keeps every source name distinct so the
        // engine never serves a cached result.
        const key = cmd + " #" + (++seq);
        if (callback)
            callbacks[key] = callback;
        connectSource(key);
    }

    engine: "executable"
    connectedSources: []
    onNewData: function (sourceName, data) {
        const cb = callbacks[sourceName];
        delete callbacks[sourceName];
        disconnectSource(sourceName);
        if (cb)
            cb(data["stdout"] || "", data["exit code"], data["stderr"] || "");
    }
}
