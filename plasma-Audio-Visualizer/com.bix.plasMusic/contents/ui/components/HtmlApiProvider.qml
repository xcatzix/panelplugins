import QtQuick

// Region B data source.
// Downloads the configured URL with curl into ~/.cache/plasMusic/htmlAPI.html
// and exposes the file content. A failed download keeps the previous copy.
QtObject {
    id: root

    property string url: plasmoid.configuration.htmlApiUrl
    property int refreshMinutes: plasmoid.configuration.htmlApiRefreshMinutes
    property string content: ""
    property bool loading: false
    property var shell: Shell {
    }
    property var refreshTimer: Timer {
        interval: Math.max(1, root.refreshMinutes) * 60000
        running: root.refreshMinutes > 0 && root.url.length > 0
        repeat: true
        onTriggered: root.reload()
    }

    function reload() {
        const file = '"$HOME/.cache/plasMusic/htmlAPI.html"';
        let cmd = 'mkdir -p "$HOME/.cache/plasMusic"; ';
        if (root.url.length > 0)
            cmd += "curl -sfL -m 20 -A plasMusic " + shell.quote(root.url) + " -o " + file + ".tmp && mv -f " + file + ".tmp " + file + "; rm -f " + file + ".tmp; ";
        cmd += "cat " + file + " 2>/dev/null";
        root.loading = true;
        shell.run(cmd, function (out) {
            root.content = out;
            root.loading = false;
        });
    }

    onUrlChanged: reload()
    Component.onCompleted: reload()
}
