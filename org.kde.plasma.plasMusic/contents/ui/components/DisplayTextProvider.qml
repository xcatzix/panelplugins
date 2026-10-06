import QtQuick

// Text shown when no media is playing (and optionally while playing).
// Either the configured string, or the content of ~/.cache/plasMusic/plasMtext.txt
QtObject {
    id: root

    property string configuredText: plasmoid.configuration.noMediaText
    property bool useFile: plasmoid.configuration.usePlasMtextFile
    property string fileText: ""
    readonly property string text: useFile && fileText.length > 0 ? fileText : configuredText
    property var shell: Shell {
    }

    function reload() {
        if (!root.useFile) {
            root.fileText = "";
            return;
        }
        shell.run('cat -- "$HOME/.cache/plasMusic/plasMtext.txt" 2>/dev/null', function (out, code) {
            root.fileText = code === 0 ? out.replace(/\r\n?/g, "\n").trim() : "";
        });
    }

    onUseFileChanged: reload()
    Component.onCompleted: reload()
}
