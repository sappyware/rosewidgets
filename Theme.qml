import QtQuick
import Quickshell
import Quickshell.Io
import "md3.js" as Md3
import "toml.js" as Toml
pragma Singleton

Singleton {
    id: root

    readonly property var shapeScale: ({
        "none": 0,
        "xs": 4,
        "sm": 8,
        "md": 12,
        "lg": 16,
        "lgi": 20,
        "xl": 28,
        "xli": 32,
        "xxl": 48,
        "full": 9999
    })
    readonly property var typeScale: ({
        "displayLarge": {
            "size": 57,
            "weight": Font.Normal,
            "ls": -0.25
        },
        "displayMedium": {
            "size": 45,
            "weight": Font.Normal,
            "ls": 0
        },
        "displaySmall": {
            "size": 36,
            "weight": Font.Normal,
            "ls": 0
        },
        "headlineLarge": {
            "size": 32,
            "weight": Font.Normal,
            "ls": 0
        },
        "headlineMedium": {
            "size": 28,
            "weight": Font.Normal,
            "ls": 0
        },
        "headlineSmall": {
            "size": 24,
            "weight": Font.Normal,
            "ls": 0
        },
        "titleLarge": {
            "size": 22,
            "weight": Font.Normal,
            "ls": 0
        },
        "titleMedium": {
            "size": 16,
            "weight": Font.Medium,
            "ls": 0.15
        },
        "titleSmall": {
            "size": 14,
            "weight": Font.Medium,
            "ls": 0.1
        },
        "bodyLarge": {
            "size": 16,
            "weight": Font.Normal,
            "ls": 0.5
        },
        "bodyMedium": {
            "size": 14,
            "weight": Font.Normal,
            "ls": 0.25
        },
        "bodySmall": {
            "size": 12,
            "weight": Font.Normal,
            "ls": 0.4
        },
        "labelLarge": {
            "size": 14,
            "weight": Font.Medium,
            "ls": 0.1
        },
        "labelMedium": {
            "size": 12,
            "weight": Font.Medium,
            "ls": 0.5
        },
        "labelSmall": {
            "size": 11,
            "weight": Font.Medium,
            "ls": 0.5
        }
    })
    readonly property var fallback: ({
        "bg": "#1e1e2e",
        "surface": "#313244",
        "border": "#45475a",
        "text": "#cdd6f4",
        "subtext": "#a6adc8",
        "accent": "#f5c2e7",
        "accent_fg": "#11111b",
        "green": "#a6e3a1",
        "yellow": "#f9e2af",
        "red": "#f38ba8",
        "blue": "#89b4fa",
        "purple": "#cba6f7",
        "peach": "#fab387",
        "teal": "#94e2d5",
        "shadow": "#80000000",
        "radius": 22,
        "font": "Inter",
        "md3": false,
        "borderW": 1,
        "shadowBlur": 32,
        "shadowY": 10,
        "type": typeScale,
        "shape": shapeScale
    })
    property var custom: ({
    })
    readonly property var customCur: {
        var o = Object.assign({
        }, fallback, custom);
        if (Config.fontName !== "")
            o.font = Config.fontName;

        o.tonal = o.tonal || o.surface;
        o.tonalFg = o.tonalFg || o.text;
        o.accentC = o.accentC || o.accent;
        o.accentCfg = o.accentCfg || o.accent_fg;
        return o;
    }
    property string wallSeed: ""
    property string wallKey: ""
    readonly property string seed: Config.md3Seed !== "wallpaper" ? Config.md3Seed : (wallSeed !== "" ? wallSeed : "#6750A4")
    readonly property bool dark: Config.md3Mode !== "light"
    readonly property var scheme: Config.isMd3 ? Md3.scheme(seed, dark) : ({
    })
    readonly property var md3Cur: Config.isMd3 ? buildMd3(scheme, Config.md3Card, Config.fontName !== "" ? Config.fontName : Config.md3Font) : ({
    })
    readonly property var cur: Config.isMd3 ? md3Cur : customCur

    function buildMd3(s, card, font) {
        var bg = card === "elevated" ? s.surfaceContainerLow : (card === "outlined" ? s.surface : s.surfaceContainerHigh);
        var outlined = card === "outlined", elevated = card === "elevated";
        return {
            "md3": true,
            "m": s,
            "dark": s.dark,
            "bg": bg,
            "surface": s.surfaceContainerHighest,
            "border": outlined ? s.outline : "transparent",
            "borderW": outlined ? 1 : 0,
            "text": s.onSurface,
            "subtext": s.onSurfaceVariant,
            "accent": s.primary,
            "accent_fg": s.onPrimary,
            "accentC": s.primaryContainer,
            "accentCfg": s.onPrimaryContainer,
            "tonal": s.secondaryContainer,
            "tonalFg": s.onSecondaryContainer,
            "blue": s.primary,
            "green": s.secondary,
            "teal": s.secondary,
            "purple": s.tertiary,
            "yellow": s.tertiary,
            "peach": s.tertiary,
            "red": s.error,
            "shadow": elevated ? "#59000000" : (outlined ? "#00000000" : "#26000000"),
            "shadowBlur": elevated ? 14 : 18,
            "shadowY": elevated ? 4 : 5,
            "radius": shapeScale.xl,
            "font": font,
            "type": typeScale,
            "shape": shapeScale
        };
    }

    function forWidget(cfg) {
        var base = cur;
        if (!Config.isMd3 || !cfg)
            return base;

        var c = String(cfg.color || "");
        if (["primary", "secondary", "tertiary"].indexOf(c) < 0)
            return base;

        var s = scheme, K = c.charAt(0).toUpperCase() + c.slice(1);
        var X = s[c], oX = s["on" + K], C = s[c + "Container"], oC = s["on" + K + "Container"];
        return Object.assign({
        }, base, {
            "bg": C,
            "text": oC,
            "subtext": Md3.mix(oC, C, 0.28),
            "accent": X,
            "accent_fg": oX,
            "accentC": X,
            "accentCfg": oX,
            "surface": Md3.mix(C, oC, 0.1),
            "tonal": Md3.mix(C, oC, 0.16),
            "tonalFg": oC,
            "border": base.borderW > 0 ? Md3.mix(C, oC, 0.35) : "transparent",
            "blue": X,
            "purple": Md3.mix(X, oC, 0.45),
            "green": Md3.mix(X, oC, 0.75),
            "teal": Md3.mix(X, oC, 0.6),
            "peach": Md3.mix(X, oC, 0.3),
            "yellow": Md3.mix(X, oC, 0.5)
        });
    }

    FileView {
        path: Config.ready ? Config.dir + "/themes/" + Config.themeName + ".toml" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.custom = Toml.parse(text())
        onLoadFailed: root.custom = ({
        })
    }

    Process {
        id: seedProc

        command: ["python3", Quickshell.shellPath("seed.py"), Config.md3Wallpaper, Config.md3WallpaperCmd, root.wallKey]

        stdout: StdioCollector {
            onStreamFinished: {
                var L = text.split("\n");
                if (L.length > 1 && L[0] !== "" && L[1].trim() !== "") {
                    root.wallSeed = L[1].trim();
                    root.wallKey = L[0];
                }
            }
        }

    }

    Timer {
        interval: 10000
        repeat: true
        triggeredOnStart: true
        running: Config.ready && Config.isMd3 && Config.md3Seed === "wallpaper"
        onTriggered: {
            if (!seedProc.running) {
                seedProc.running = true;
            }
        }
    }

}
