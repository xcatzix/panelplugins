import QtQuick

// Lyrics backend.
//  * downloads lyrics with curl (lrclib.net) into ~/.cache/plasMusic/lyrics/
//  * a hand-made  ~/.cache/plasMusic/lyrics/<key>.lrc  always wins
//  * reads the cached file back and parses it (synced LRC or plain text)
QtObject {
    id: root

    // inputs (bound from main.qml)
    property string title: ""
    property string artist: ""
    property string album: ""
    property real lengthUs: 0
    property real positionUs: 0
    property int offsetMs: 0
    property bool active: true

    // outputs
    property var lines: []          // [{t: seconds, text: "..."}]
    property bool timed: false
    property string status: "idle"  // idle | loading | found | none

    readonly property int currentIndex: {
        if (!timed || lines.length === 0)
            return -1;
        const p = positionUs / 1e6 + offsetMs / 1000;
        let lo = 0, hi = lines.length - 1, ans = -1;
        while (lo <= hi) {
            const mid = (lo + hi) >> 1;
            if (lines[mid].t <= p) {
                ans = mid;
                lo = mid + 1;
            } else {
                hi = mid - 1;
            }
        }
        return ans;
    }
    readonly property string currentLine: {
        if (currentIndex < 0)
            return "";
        return lines[currentIndex].text || "♪";
    }
    readonly property string trackKey: title + "\u0001" + artist
    property int requestId: 0
    property var shell: Shell {
    }
    property var debounce: Timer {
        interval: 400
        onTriggered: root.load(false)
    }

    function hashOf(s) {
        let h = 5381;
        for (let i = 0; i < s.length; i++)
            h = ((h << 5) + h + s.charCodeAt(i)) | 0;
        return (h >>> 0).toString(16);
    }

    function fileKey() {
        const base = (artist + "-" + title).replace(/[^A-Za-z0-9\u4e00-\u9fa5\-]+/g, "_").slice(0, 80);
        return base + "_" + hashOf(artist + "\u0001" + title + "\u0001" + album);
    }

    function parseLrc(text) {
        const timedRows = [];
        const plainRows = [];
        const tagRe = /\[(\d{1,3}):(\d{1,2}(?:[.:]\d{1,3})?)\]/g;
        const rows = String(text).split(/\r?\n/);
        for (let r = 0; r < rows.length; r++) {
            const row = rows[r];
            const stamps = [];
            let m;
            tagRe.lastIndex = 0;
            while ((m = tagRe.exec(row)) !== null)
                stamps.push(parseInt(m[1]) * 60 + parseFloat(m[2].replace(":", ".")));
            const content = row.replace(/\[[^\]]*\]/g, "").trim();
            if (stamps.length > 0) {
                for (let i = 0; i < stamps.length; i++)
                    timedRows.push({ "t": stamps[i], "text": content });
            } else if (content.length > 0) {
                plainRows.push({ "t": -1, "text": content });
            }
        }
        if (timedRows.length > 0) {
            timedRows.sort(function (a, b) { return a.t - b.t; });
            return { "timed": true, "lines": timedRows };
        }
        return { "timed": false, "lines": plainRows };
    }

    // Choose the lyric text out of an lrclib JSON answer (object or array).
    function pickText(data) {
        const list = Array.isArray(data) ? data : [data];
        const wantSec = lengthUs / 1e6;
        let best = null, bestDiff = 1e9;
        for (let i = 0; i < list.length; i++) {
            const it = list[i];
            if (!it || !it.syncedLyrics)
                continue;
            const diff = wantSec > 0 && it.duration ? Math.abs(it.duration - wantSec) : 0;
            if (diff < bestDiff) {
                best = it;
                bestDiff = diff;
            }
        }
        if (best)
            return best.syncedLyrics;
        for (let j = 0; j < list.length; j++) {
            if (list[j] && list[j].plainLyrics)
                return list[j].plainLyrics;
        }
        return "";
    }

    function apply(out, id) {
        if (id !== root.requestId)
            return;
        let text = String(out).trim();
        if (text.length > 0 && (text[0] === "[" || text[0] === "{") && !/^\[\d{1,3}:\d/.test(text)) {
            try {
                text = pickText(JSON.parse(text));
            } catch (e) {
                text = "";
            }
        }
        const res = parseLrc(text);
        root.timed = res.timed;
        root.lines = res.lines;
        root.status = res.lines.length > 0 ? "found" : "none";
    }

    function clear() {
        root.lines = [];
        root.timed = false;
        root.status = "idle";
    }

    function reload(force) {
        load(force === true);
    }

    function load(force) {
        const id = ++root.requestId;
        clear();
        if (!active || title.length === 0)
            return;
        status = "loading";

        const q = function (k, v) {
            return k + "=" + encodeURIComponent(v).replace(/'/g, "%27");
        };
        const base = "https://lrclib.net/api";
        const getParams = [q("track_name", title), q("artist_name", artist), q("album_name", album)];
        if (lengthUs > 0)
            getParams.push(q("duration", Math.round(lengthUs / 1e6)));
        const getUrl = base + "/get?" + getParams.join("&");
        const searchUrl = base + "/search?" + q("q", (title + " " + artist).trim());
        const K = fileKey();
        const cmd = 'D="$HOME/.cache/plasMusic/lyrics"; K=' + shell.quote(K) + '; mkdir -p "$D"\n'
            + (force ? 'rm -f "$D/$K.json"\n' : '')
            + 'if [ -s "$D/$K.lrc" ]; then cat "$D/$K.lrc"; else\n'
            + '  if [ ! -s "$D/$K.json" ]; then\n'
            + '    curl -sfL -m 15 -A plasMusic ' + shell.quote(getUrl) + ' -o "$D/$K.json" \\\n'
            + '    || curl -sfL -m 15 -A plasMusic ' + shell.quote(searchUrl) + ' -o "$D/$K.json" \\\n'
            + '    || rm -f "$D/$K.json"\n'
            + '  fi\n'
            + '  cat "$D/$K.json" 2>/dev/null\n'
            + 'fi\n';
        shell.run(cmd, function (out) {
            root.apply(out, id);
        });
    }

    onTrackKeyChanged: debounce.restart()
    onActiveChanged: {
        if (active && status === "idle")
            debounce.restart();
    }
    Component.onCompleted: debounce.restart()
}
