-- ============================================================
-- KEY COMMAND CONFIGURATION
-- Verify these match your Logic Pro key assignments:
-- Logic Pro menu > Key Commands > Edit Assignments...
-- ============================================================

-- Standard Logic key commands (defaults shown):
property kcToggleHideView      : {key:"h", mods:{}}
property kcSetLocatorsByMarker : {key:"c", mods:{"control", "option"}}
property kcUnhideAllTracks     : {key:"h", mods:{"control", "shift"}}
property kcHideShowTracks      : {key:"h", mods:{"control"}}
property kcSelectInLocators    : {key:"l", mods:{"shift"}}
property kcToggleCycle         : {key:"c", mods:{}}
property kcZoomToLocators      : {key:"z", mods:{"control", "shift"}}
property kcDeselectAll         : {key:"d", mods:{"shift"}}

-- Custom key commands (you must assign these in Logic Pro):
property kcSelectAllTracks     : {key:"a", mods:{"control", "shift"}}

-- ============================================================
-- INTERNAL STATE (do not modify)
-- ============================================================

property hideTracksBtn : missing value
property cycleBtn : missing value
property timingMode : false
property stepTimings : {}

-- ============================================================
-- HANDLERS
-- ============================================================

on validateAllKC()
    set kcNames to {"kcToggleHideView", "kcSetLocatorsByMarker", "kcUnhideAllTracks", "kcHideShowTracks", "kcSelectInLocators", "kcToggleCycle", "kcZoomToLocators", "kcDeselectAll", "kcSelectAllTracks"}
    set kcValues to {kcToggleHideView, kcSetLocatorsByMarker, kcUnhideAllTracks, kcHideShowTracks, kcSelectInLocators, kcToggleCycle, kcZoomToLocators, kcDeselectAll, kcSelectAllTracks}
    set errorList to {}
    repeat with i from 1 to count of kcValues
        set kc to item i of kcValues
        set k to ""
        try
            set k to kc's key
            if k is missing value then set k to ""
        end try
        if k is "" then
            set end of errorList to (item i of kcNames) & ": key must be a non-empty string"
        end if
    end repeat
    if (count of errorList) > 0 then
        set msg to "Key command configuration errors:" & return
        repeat with e in errorList
            set msg to msg & "  • " & e & return
        end repeat
        display dialog msg buttons {"OK"} default button "OK" with icon stop
        error "Invalid key command configuration"
    end if
end validateAllKC

on buildModList(modStrings)
    set modList to {}
    repeat with m in modStrings
        set mStr to contents of m
        if mStr is "command" then set end of modList to command down
        if mStr is "shift"   then set end of modList to shift down
        if mStr is "control" then set end of modList to control down
        if mStr is "option"  then set end of modList to option down
    end repeat
    return modList
end buildModList

on sendKeystroke(kc)
    set modList to my buildModList(kc's mods)
    tell application "System Events"
        tell process "Logic Pro"
            if (count of modList) > 0 then
                keystroke (kc's key) using modList
            else
                keystroke (kc's key)
            end if
        end tell
    end tell
end sendKeystroke

on waitForLogicToRespond()
    tell application "System Events"
        repeat
            try
                value of hideTracksBtn
                exit repeat
            end try
        end repeat
    end tell
end waitForLogicToRespond

on milliseconds()
    return (do shell script "python3 -c 'import time; print(int(time.time() * 1000 % 10000000))'") as integer
end milliseconds

on doStep(kc, stepName)
    if timingMode then
        set t to my milliseconds()
        my sendKeystroke(kc)
        my waitForLogicToRespond()
        set end of stepTimings to stepName & ": " & (my milliseconds() - t) & "ms"
    else
        my sendKeystroke(kc)
        my waitForLogicToRespond()
    end if
end doStep

-- ============================================================
-- MAIN
-- ============================================================

my validateAllKC()
set stepTimings to {}

tell application "Logic Pro" to activate
tell application "System Events"
    tell process "Logic Pro"
        repeat until frontmost is true
        end repeat
    end tell
end tell

tell application "System Events"
    tell process "Logic Pro"
        set cycleBtn to checkbox "Cycle" of group 1 of window 1
        set hideTracksBtn to first checkbox of group 1 of UI element 1 of UI element 1 of group 2 of group 3 of window 1 whose description starts with "Show/Hide Hidden Tracks"
    end tell
end tell

tell application "System Events"
    tell process "Logic Pro"
        -- (*) If tracks are currently hidden, show them first so we can work with them
        if value of hideTracksBtn is 0 then
            my doStep(kcToggleHideView, "Unhide tracks")
        end if

        my doStep(kcUnhideAllTracks,     "Unhide all tracks")      -- Make all tracks visible
        my doStep(kcSelectAllTracks,     "Select all tracks")      -- Select all tracks
        my doStep(kcHideShowTracks,      "Hide all tracks")        -- Mark all tracks as hidden
        my doStep(kcSelectInLocators,    "Select within locators") -- Select regions within locator range
        my doStep(kcDeselectAll,         "Deselect all")           -- Deselect (avoid pre-selection artifact)
        my doStep(kcSelectInLocators,    "Select within locators") -- Select regions within locator range
        my doStep(kcHideShowTracks,      "Unhide selected tracks") -- Unhide tracks that have content
        my doStep(kcToggleHideView,      "Toggle hide view")       -- Hide hidden tracks
        my doStep(kcZoomToLocators,      "Zoom to locators")       -- Zoom Tracks area to locator range
        my doStep(kcDeselectAll,         "Deselect all")           -- Clean up selection
    end tell
end tell

if timingMode then
    set report to ""
    repeat with entry in stepTimings
        set report to report & entry & return
    end repeat
    display dialog report
end if
