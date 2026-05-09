import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string pluginId: "dankTranslate"
    property string trigger: ">"
    property string defaultLang: "en"
    property string _lastQuery: ""
    property string _lastResult: ""
    property string _lastError: ""
    property string _stdoutBuffer: ""
    property string _stderrBuffer: ""
    property bool _translating: false
    property bool _error: false
    property bool _timedOut: false

    signal itemsChanged

    Component.onCompleted: {
        if (!pluginService)
            return;
        trigger = pluginService.loadPluginData(pluginId, "trigger", ">");
        defaultLang = pluginService.loadPluginData(pluginId, "defaultLang", "en");
    }

    property Timer debounceTimer: Timer {
        interval: 300
        onTriggered: {
            if (root._pendingQuery)
                root.startTranslation(root._pendingQuery, root._pendingLang);
        }
    }

    property string _pendingQuery: ""
    property string _pendingLang: ""

    property Timer translationTimeout: Timer {
        interval: 15000
        repeat: false
        onTriggered: {
            root._timedOut = true;
            if (transProcess.running)
                transProcess.running = false;
            root.finishTranslation("", "Translation timed out");
        }
    }

    function parseQuery(raw) {
        var trimmed = raw.trim();
        if (trimmed.length === 0)
            return { lang: defaultLang, text: "" };

        var words = trimmed.split(/\s+/);
        // If first word is a 2-3 char language code, use it as target
        if (words.length > 1 && words[0].length >= 2 && words[0].length <= 3 && /^[a-z]+$/i.test(words[0])) {
            return {
                lang: words[0].toLowerCase(),
                text: words.slice(1).join(" ")
            };
        }

        return { lang: defaultLang, text: trimmed };
    }

    function startTranslation(text, lang) {
        if (transProcess.running)
            transProcess.running = false;
        _stdoutBuffer = "";
        _stderrBuffer = "";
        _timedOut = false;
        _translating = true;
        _error = false;
        _lastError = "";
        transProcess.command = ["sh", "-c", "command -v trans >/dev/null 2>&1 || exit 127; exec trans -brief -t \"$1\" \"$2\"", "sh", lang, text];
        transProcess.running = true;
        translationTimeout.restart();
    }

    function finishTranslation(result, errorText) {
        translationTimeout.stop();
        _translating = false;
        _lastResult = result ? result.trim() : "";
        _lastError = errorText || "";
        _error = _lastError.length > 0;
        if (pluginService)
            pluginService.requestLauncherUpdate(pluginId);
    }

    property Process transProcess: Process {
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root._stdoutBuffer = text.trim();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._stderrBuffer = text.trim();
            }
        }

        onExited: exitCode => {
            if (root._timedOut)
                return;

            if (exitCode === 0) {
                if (root._stdoutBuffer.length > 0)
                    root.finishTranslation(root._stdoutBuffer, "");
                else
                    root.finishTranslation("", "No translation returned");
            } else if (exitCode === 127) {
                root.finishTranslation("", "translate-shell (trans) is not installed");
            } else {
                root.finishTranslation("", root._stderrBuffer || "Translation failed");
            }
        }
    }

    function getItems(query) {
        if (!query || query.trim().length === 0) {
            return [{
                name: "Type text to translate",
                icon: "material:translate",
                comment: "Default target: " + defaultLang + " | Prefix a language code to override (e.g. pt hello)",
                action: "none:",
                categories: ["Translate"],
                _preScored: 1000
            }];
        }

        var parsed = parseQuery(query);

        if (parsed.text.length === 0) {
            return [{
                name: "Type text after language code",
                icon: "material:translate",
                comment: "Translating to: " + parsed.lang,
                action: "none:",
                categories: ["Translate"],
                _preScored: 1000
            }];
        }

        var queryKey = parsed.lang + ":" + parsed.text;
        if (queryKey !== _lastQuery) {
            _lastQuery = queryKey;
            _lastResult = "";
            _error = false;
            _lastError = "";
            _pendingQuery = parsed.text;
            _pendingLang = parsed.lang;
            debounceTimer.restart();
        }

        if (_error) {
            return [{
                name: "Translation failed",
                icon: "material:error_outline",
                comment: _lastError || (parsed.text + " -> " + parsed.lang),
                action: "none:",
                categories: ["Translate"],
                _preScored: 1000
            }];
        }

        if (_translating || !_lastResult) {
            return [{
                name: "Translating...",
                icon: "material:hourglass_empty",
                comment: parsed.text + " -> " + parsed.lang,
                action: "none:",
                categories: ["Translate"],
                _preScored: 1000
            }];
        }

        // Split multi-line results into separate items
        var lines = _lastResult.split("\n").filter(function(l) { return l.trim().length > 0; });
        return lines.map(function(line) {
            return {
                name: line,
                icon: "material:translate",
                comment: parsed.text + " -> " + parsed.lang,
                action: "copy:" + line,
                categories: ["Translate"],
                _preScored: 1000
            };
        });
    }

    function executeItem(item) {
        if (!item?.action)
            return;
        var colonIdx = item.action.indexOf(":");
        if (colonIdx === -1)
            return;
        var actionType = item.action.substring(0, colonIdx);
        var actionData = item.action.substring(colonIdx + 1);

        if (actionType === "copy" && actionData) {
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", actionData]);
            if (typeof ToastService !== "undefined")
                ToastService.showInfo("Translate", "Copied to clipboard");
        }
    }

    onTriggerChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData(pluginId, "trigger", trigger);
    }

    onDefaultLangChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData(pluginId, "defaultLang", defaultLang);
    }
}
