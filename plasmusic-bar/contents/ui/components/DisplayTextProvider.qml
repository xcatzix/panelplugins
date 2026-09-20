import QtQuick
import QtCore
import org.kde.plasma.plasma5support as Plasma5Support

QtObject {
    id: root

    property string configuredText: plasmoid.configuration.noMediaText
    property bool useFile: plasmoid.configuration.usePlasMtextFile
    property string fileText: ""
    readonly property string text: useFile && fileText.length > 0 ? fileText : configuredText

    property var executable: Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        function readFile() {
            if (!root.useFile) {
                root.fileText = ""
                return
            }

            // Plasma 6 disables XMLHttpRequest access to local file:// URLs.
            // Use the Plasma5Support executable data engine to read this one
            // user-controlled text file instead.
            connectSource('cat -- "$HOME/.cache/plasMusic/plasMtext.txt"')
        }

        onNewData: function(sourceName, data) {
            const stdout = data["stdout"] || ""
            const exitCode = data["exit code"]
            root.fileText = exitCode === 0 ? stdout.trim() : ""
            disconnectSource(sourceName)

            if (exitCode !== 0)
                console.warn("Unable to read plasMtext.txt, exit code:", exitCode)
        }
    }

    function reload() {
        executable.readFile()
    }

    onUseFileChanged: reload()
    onConfiguredTextChanged: {
        // Keep the binding-driven text current without touching fileText.
    }
    Component.onCompleted: reload()
}
