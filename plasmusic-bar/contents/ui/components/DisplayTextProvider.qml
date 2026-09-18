import QtQuick
import QtCore

QtObject {
    id: root

    property string configuredText: plasmoid.configuration.noMediaText
    property bool useFile: plasmoid.configuration.usePlasMtextFile
    readonly property string filePath: StandardPaths.writableLocation(StandardPaths.HomeLocation)
                                   + "/.cache/plasMusic/plasMtext.txt"
    property string fileText: ""
    property string text: useFile && fileText.length > 0 ? fileText : configuredText

    function reload() {
        fileText = ""
        if (!useFile)
            return

        const xhr = new XMLHttpRequest()
        try {
            xhr.open("GET", "file://" + encodeURI(filePath), false)
            xhr.send()
            if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 300))
                fileText = xhr.responseText.trim()
        } catch (e) {
            console.warn("Unable to read plasMtext.txt:", e)
        }
    }

    onUseFileChanged: reload()
    Component.onCompleted: reload()
}