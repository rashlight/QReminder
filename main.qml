import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Universal
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import QtMultimedia

Window {
    id: window
    width: 800
    height: 600
    visible: true
    visibility: isFullScreen ? Window.FullScreen : Window.AutomaticVisibility
    title: qsTr("QReminder")
    color: Universal.background

    // Properties
    readonly property int secondsPerMinute: 60
    readonly property int secondsPerHour: 3600
    readonly property int secondsPerDay: 86400

    property int selectedIndex: -1
    property real alertVolume: 0.5
    property bool isFullScreen: false
    property bool isDefaultColor: true
    property bool isSkipNotHeld: false
    property bool isWindowLocked: false
    property string selectedColor: "default"
    property string uiTheme: "system" // system, dark, light
    property string uiLanguage: "system"
    property string defaultLanguage: undefined
    property string alertMood: "neutral" // dynamic, happy, neutral, sad
    property string errMsg: qsTr("Unknown Error has occurred.")
    property string errStack: qsTr("Stack not available.")
    property double currentTimestamp: -1 // number type is floating-point
    property color hoverColor: "gray"

    property int veryLargeFontSize: 34
    property int largeFontSize: 17
    property int normalFontSize: 16
    property int smallFontSize: 14
    property int verySmallFontSize: 11

    Universal.theme: Application.styleHints.colorScheme, getTheme()

    // Data Items
    ListModel {
        id: reminders
        /*
          {
            name: "something"
            time: unix stamp in milliseconds
            labelColor: "black"
          }
        */
    }
    ListModel {
        id: pendingReminders
        /*
          {
            name: "something"
            time: unix stamp in milliseconds
            labelColor: "black"
          }
        */
    }
    ListModel {
        id: moods
        ListElement {
            name: "happy"
        }
        ListElement {
            name: "neutral"
        }
        ListElement {
            name: "sad"
        }
    }

    // Components
    ColorDialog {
        id: colorDialog
        modality: Qt.ApplicationModal
        selectedColor: "black"
        onAccepted: {
            window.selectedColor = selectedColor
        }
    }
    MediaPlayer {
        id: alertPlayer
        source: "" // Manual add
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            volume: alertVolume
        }

        onErrorOccurred: function (error, errorString) {
            console.error("Media player error: ", error, errorString)
        }
    }
    Timer {
        id: scheduleTimer

        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            // Cố lên!
            // Youu can do it!
            // あなたならできる！
            currentTimestamp = Date.now()
            let deleteIndexes = []

            // Get the list of reminders that are triggered
            for (var i = 0; i < reminders.count; i++) {
                if (currentTimestamp >= reminders.get(i).time) {
                    // console.log(`Reminder ${i} triggered: ${reminders.get(i).name}`);
                    deleteIndexes.push(i)
                    // Add item to pending reminders (which will trigger alarm)
                    pendingReminders.append(reminders.get(i))
                }
            }

            // Are there any reminders to be blasted?
            if (deleteIndexes.length > 0) {
                // Disable delete buttons
                deleteButton.enabled = false

                // Delete them
                deleteIndexes.sort((a, b) => b - a);
                for (let index of deleteIndexes) {
                    reminders.remove(index, 1)
                }

                // Enable delete button only if its viable
                if (reminders.count > 0 && selectedIndex < reminders.count) {
                    deleteButton.enabled = true
                } else {
                    // Reset the index
                    selectedIndex = -1
                }

                // Blast strawberry sound into the atmosphere
                let trueMood = alertMood === "dynamic"
                    ? moods.get(Math.floor(Math.random() * moods.count)).name
                    : alertMood
                let musicPath;
                if (Qt.platform.os !== "android" && Qt.platform.os !== "ios") {
                    musicPath = "file:///" + applicationDirPath + "/music/" + trueMood + ".wav"
                } else {
                    musicPath = "qrc:/music/" + trueMood
                }

                alertPlayer.stop()
                if (alertPlayer.source.toString() !== musicPath) {
                    alertPlayer.source = musicPath;
                }
                alertPlayer.play()

                // Open the popup only if its not opened yet
                if (!remindersAlertPopup.isOpened) {
                    remindersAlertPopup.open()
                }
            }
        }
    }

    // Reusable UI
    Component {
        id: createNewComponent

        Dialog {
            id: createNewDialog
            anchors.centerIn: parent

            title: qsTr("New Reminder")
            standardButtons: Dialog.Ok | Dialog.Cancel
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                anchors.centerIn: parent

                spacing: 10

                Label {
                    id: whatIsTheTaskLabel
                    text: qsTr("What is the task?")
                    font.pixelSize: largeFontSize
                }
                TextEdit {
                    id: taskName
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true

                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.tab: colorSelectButton
                    activeFocusOnTab: true
                    font.weight: 600
                    font.pixelSize: 16
                    color: Universal.foreground

                    property string placeholderText: qsTr("Untitled")

                    Text {
                        text: parent.placeholderText
                        color: hoverColor
                        opacity: 0.5
                        font.pixelSize: parent.font.pixelSize
                        visible: !parent.text
                    }
                }
                Label {
                    id: wantToChangeColorLabel
                    text: qsTr("Want to change color?")
                    font.pixelSize: largeFontSize
                }
                RowLayout {
                    id: colorBoxLayout
                    spacing: 15

                    RowLayout {
                        spacing: 0

                        Rectangle {
                            id: colorSelectRect
                            Layout.preferredWidth: selectedColor === "default" ? 0 : colorSelectButton.height
                            Layout.preferredHeight: colorSelectButton.height
                            color: selectedColor === "default" ? "#434343" : selectedColor
                            radius: width / 2
                        }
                        Item {
                            Layout.preferredWidth: colorSelectImage.width
                            Layout.preferredHeight: colorSelectImage.height

                            Image {
                                id: colorSelectImage

                                width: selectedColor === "default" ? colorSelectButton.height : 0
                                height: colorSelectButton.height

                                source: "qrc:/images/constrast"
                                opacity: 0
                            }
                            ColorOverlay {
                                anchors.fill: parent
                                source: colorSelectImage

                                visible: selectedColor === "default"
                                color: wantToChangeColorLabel.color
                            }
                        }
                    }
                    Button {
                        id: colorSelectButton
                        text: qsTr("Choose...")
                        font.pixelSize: normalFontSize
                        activeFocusOnTab: true

                        onClicked: {
                            colorDialog.open()
                        }
                    }
                    Button {
                        id: colorResetButton
                        text: qsTr("Reset...")
                        font.pixelSize: normalFontSize
                        activeFocusOnTab: true

                        onClicked: {
                            selectedColor = "default"
                        }
                    }
                }
                Label {
                    id: howLongFromNowLabel
                    text: qsTr("How long from now?")
                    font.pixelSize: largeFontSize
                }
                RowLayout {
                    id: timePickerLayout
                    spacing: 0

                    Component {
                        id: numberDelegate

                        Label {
                            text: qsTr("%1").arg(modelData)
                            opacity: 1.0 - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 2)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: normalFontSize
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: qsTr("day")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }

                        Tumbler {
                            id: daysTumbler

                            Layout.preferredHeight: 125

                            model: 100
                            visibleItemCount: 3
                            delegate: numberDelegate
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Item {
                            Layout.preferredHeight: normalFontSize
                        }

                        Text {
                            text: qsTr(":")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: qsTr("hour")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }

                        Tumbler {
                            id: hoursTumbler
                            Layout.preferredHeight: 125

                            model: 24
                            visibleItemCount: 3
                            delegate: numberDelegate
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Item {
                            Layout.preferredHeight: normalFontSize
                        }

                        Text {
                            text: qsTr(":")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: qsTr("min")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }

                        Tumbler {
                            id: minutesTumbler
                            Layout.preferredHeight: 125

                            model: 60
                            visibleItemCount: 3
                            delegate: numberDelegate
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Item {
                            Layout.preferredHeight: normalFontSize
                        }

                        Text {
                            text: qsTr(":")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }
                    }

                    ColumnLayout {
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignHCenter

                            text: qsTr("sec")
                            color: Universal.foreground
                            font.pixelSize: normalFontSize
                        }

                        Tumbler {
                            id: secondsTumbler
                            Layout.preferredHeight: 125

                            model: 60
                            visibleItemCount: 3
                            delegate: numberDelegate
                        }
                    }
                }
                Label {
                    id: helpLabel
                    Layout.fillWidth: true

                    text: qsTr("Help?")
                    font.pixelSize: largeFontSize
                    font.underline: true

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            subDialogLoader.sourceComponent = conversionComponent
                            subDialogLoader.item.open()
                        }
                    }
                }
            }

            onOpened: {
                taskName.focus = true
            }

            onAccepted: {
                function isValidUnixTimestamp(timestamp) {
                    if (!Number(timestamp)) {
                        return false;
                    }

                    // Check if it's positive
                    if (timestamp < 0) {
                        return false;
                    }

                    // Check if it's not more than (100 days - 1 second) from now
                    const maxAllowedTimestamp = 8639999000;
                    if (timestamp > maxAllowedTimestamp) {
                        return false;
                    }

                    // Note: if tumbler.currentIndex = -1, behavior is undefined
                    return true;
                }

                let time = Number(daysTumbler.currentIndex) * 86400000 +
                    Number(hoursTumbler.currentIndex) * 3600000 +
                    Number(minutesTumbler.currentIndex) * 60000 +
                    Number(secondsTumbler.currentIndex) * 1000

                if (!isValidUnixTimestamp(time)) {
                    subDialogLoader.sourceComponent = valueFailComponent
                    subDialogLoader.item.open()
                } else {
                    // magic happen here
                    reminders.append({
                        name: taskName.text ? taskName.text : qsTr("Untitled"),
                        time: Date.now() + time,
                        labelColor: selectedColor
                    })
                }
            }
        }
    }
    Component {
        id: valueFailComponent

        Dialog {
            id: valueFailDialog
            anchors.centerIn: parent
            closePolicy: Dialog.NoAutoClose
            modal: true

            standardButtons: Dialog.Ok
            title: qsTr("You have chosen something wrong!")

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    text: qsTr("Either time length is zero seconds, or values are invalid.")
                    color: Universal.foreground
                    font.pixelSize: normalFontSize
                }
            }
        }
    }
    Component {
        id: conversionComponent

        Dialog {
            id: conversionDialog
            anchors.centerIn: parent

            closePolicy: Dialog.NoAutoClose
            modal: true

            standardButtons: Dialog.Ok
            title: qsTr("Help")
            font.pixelSize: normalFontSize

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Label {
                    text: qsTr("Time picker format:
 - day : hour : minutes : seconds

Common time conversions:
 - 1 minute = 60 seconds
 - 1 hour = 60 minutes
 - 1 day = 24 hours
 - 1 week = 7 days
 - 1 month = 30 days
 - 3 months = 90 days")
                }
            }
        }
    }
    Component {
        id: settingsComponent

        Dialog {
            id: settingsDialog
            anchors.centerIn: parent

            standardButtons: Dialog.Ok
            title: qsTr("Settings")
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                id: settingsColumnLayout
                anchors.centerIn: parent

                spacing: 10

                Label {
                    text: qsTr("Volume")
                    font.pixelSize: normalFontSize
                }
                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: parent.width

                    from: 0
                    to: 1
                    snapMode: Slider.SnapAlways
                    stepSize: 0.05
                    value: alertVolume

                    onValueChanged: {
                        alertVolume = value
                    }
                }
                RowLayout {
                    id: isWindowLockedLayout
                    spacing: 0

                    height: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? 0 : height
                    visible: (Qt.platform.os === "android" || Qt.platform.os === "ios") ? false : true

                    Label {
                        text: qsTr("Lock app from closing")

                        font.pixelSize: normalFontSize
                    }

                    Switch {
                        id: isWindowLockedSwitch
                        Layout.alignment: Qt.AlignLeft

                        checked: isWindowLocked
                        font.pixelSize: normalFontSize

                        onClicked: {
                            isWindowLocked = !isWindowLocked
                        }
                    }
                }
                Label {
                    id: alertMoodLabel
                    text: qsTr("Alert Mood")
                    font.pixelSize: normalFontSize
                }
                ComboBox {
                    id: alertMoodComboBox
                    Layout.preferredWidth: parent.width

                    currentIndex: alertMood === "dynamic"
                        ? 0
                        : alertMood === "happy"
                            ? 1
                            : alertMood === "neutral"
                                ? 2
                                : 3
                    model: ["dynamic", "happy", "neutral", "sad"]
                    delegate: ItemDelegate {
                        implicitWidth: parent.width
                        implicitHeight: moodImage.height
                        spacing: 20

                        RowLayout {
                            id: alertMoodLayout
                            spacing: 5

                            Item {}

                            Item {
                                Layout.preferredWidth: moodImage.width
                                Layout.preferredHeight: moodImage.height

                                Image {
                                    id: moodImage
                                    width: 24
                                    height: 24
                                    source: "qrc:/images/" + alertMoodComboBox.model[index] + "Mood"
                                    opacity: 0
                                }
                                ColorOverlay {
                                    anchors.fill: moodImage

                                    source: moodImage
                                    color: Universal.foreground
                                }
                            }

                            Label {
                                id: moodDescriptorText
                                text: alertMoodComboBox.model[index] === "dynamic"
                                    ? qsTr("Dynamic")
                                    : alertMoodComboBox.model[index] === "happy"
                                        ? qsTr("Happy")
                                        : alertMoodComboBox.model[index] === "neutral"
                                            ? qsTr("Neutral")
                                            : qsTr("Sad")
                                font.pixelSize: normalFontSize
                            }
                        }

                        onClicked: {
                            alertMoodComboBox.currentIndex = index
                        }
                    }

                    onCurrentIndexChanged: {
                        alertMood = alertMoodComboBox.model[currentIndex]
                    }
                }
                Label {
                    text: qsTr("Interface Theme")
                    font.pixelSize: normalFontSize
                }
                ComboBox {
                    id: uiThemeComboBox
                    Layout.preferredWidth: parent.width

                    currentIndex: uiTheme === "dark"
                        ? 1
                        : uiTheme === "light"
                            ? 2
                            : 0
                    model: ["system", "dark", "light"]
                    delegate: ItemDelegate {
                        implicitWidth: parent.width
                        implicitHeight: descriptorText.font.pixelSize + 7
                        spacing: 20

                        RowLayout {
                            spacing: 5

                            Item {}

                            Item {
                                Layout.preferredWidth: uiThemeImage.width
                                Layout.preferredHeight: uiThemeImage.height

                                Image {
                                    id: uiThemeImage
                                    width: 24
                                    height: 24
                                    source: "qrc:/images/" + uiThemeComboBox.model[index]
                                    opacity: 0
                                }
                                ColorOverlay {
                                    anchors.fill: uiThemeImage

                                    source: uiThemeImage
                                    color: Universal.foreground
                                }
                            }

                            Label {
                                id: descriptorText
                                text: uiThemeComboBox.model[index] === "system"
                                      ? qsTr("Follow System Theme")
                                      : uiThemeComboBox.model[index] === "dark"
                                          ? qsTr("Dark")
                                          : qsTr("Light")
                                font.pixelSize: normalFontSize
                            }
                        }

                        onClicked: {
                            uiThemeComboBox.currentIndex = index
                        }
                    }

                    onCurrentIndexChanged: {
                        switch (currentIndex) {
                        case 0: // system
                            uiTheme = "system"
                            break
                        case 1: // dark
                            uiTheme = "dark"
                            break
                        case 2: // light
                            uiTheme = "light"
                            break
                        default:
                            console.error("Cannot determine uiTheme from: ", currentIndex)
                            return
                        }
                    }
                }
                ColumnLayout {
                    spacing: 5

                    Label {
                        text: qsTr("Language")
                        font.pixelSize: normalFontSize
                    }
                    Label {
                        text: qsTr("'*' items are machine-translated")
                        font.pixelSize: smallFontSize
                        font.italic: true
                    }
                }
                ComboBox {
                    id: languageComboBox
                    Layout.preferredWidth: parent.width

                    currentIndex: uiLanguage === "en"
                        ? 1
                        : uiLanguage === "ja"
                            ? 2
                            : uiLanguage === "vi"
                                ? 3
                                : 0
                    model: ["system", "en", "ja", "vi"]
                    delegate: ItemDelegate {
                        implicitWidth: parent.width
                        implicitHeight: descriptorText.font.pixelSize + 7
                        spacing: 20

                        RowLayout {
                            spacing: 5

                            Item {}

                            Label {
                                id: descriptorText
                                text: languageComboBox.model[index] === "en"
                                      ? qsTr("English (US/UK)")
                                      : languageComboBox.model[index] === "ja"
                                          ? qsTr("Japanese (日本語) *")
                                          : languageComboBox.model[index] === "vi"
                                              ? qsTr("Vietnamese (Tiếng Việt)")
                                              : qsTr("Follow System Language")
                                font.pixelSize: normalFontSize
                            }
                        }

                        onClicked: {
                            languageComboBox.currentIndex = index
                        }
                    }

                    onCurrentIndexChanged: {
                        switch (currentIndex) {
                        case 0: // system
                            uiLanguage = "system"
                            Qt.uiLanguage = defaultLanguage
                            break
                        case 1: // english
                            uiLanguage = "en"
                            Qt.uiLanguage = uiLanguage
                            break
                        case 2: // japanese
                            uiLanguage = "ja"
                            Qt.uiLanguage = uiLanguage
                            break
                        case 3: // vietnamese
                            uiLanguage = "vi"
                            Qt.uiLanguage = uiLanguage
                            break
                        default:
                            console.error("Cannot determine uiLanguage from: ", currentIndex)
                            return
                        }
                    }
                }
                Item {}
                RowLayout {
                    spacing: 10
                    Layout.alignment: Qt.AlignHCenter

                    Button {
                        id: aboutButton
                        Layout.alignment: Qt.AlignCenter

                        icon {
                            source: "qrc:/images/info"
                            color: Universal.foreground
                        }

                        text: qsTr("About")
                        font.pixelSize: normalFontSize

                        onClicked: {
                            subDialogLoader.sourceComponent = infoComponent
                            subDialogLoader.item.open()
                        }
                    }

                    Button {
                        id: kioskButton
                        Layout.alignment: Qt.AlignCenter

                        icon {
                            source: "qrc:/images/kiosk"
                            color: Universal.foreground
                        }

                        text: qsTr("Kiosk Mode")
                        font.pixelSize: normalFontSize

                        onClicked: {
                            subDialogLoader.sourceComponent = kioskComponent
                            subDialogLoader.item.open()
                        }
                    }
                }
                Button {
                    id: windowModeButton
                    Layout.alignment: Qt.AlignCenter

                    icon {
                        source: "qrc:/images/" + (isFullScreen ? "windowed" : "fullScreen")
                        color: Universal.foreground
                    }

                    text: qsTr("%1 %2").arg(qsTr("Go")).arg(isFullScreen ? qsTr("Windowed") : qsTr("Fullscreen"))
                    font.pixelSize: normalFontSize

                    onClicked: {
                        isFullScreen = !isFullScreen
                    }
                }
            }
        }
    }
    Component {
        id: saveLoadComponent

        Dialog {
            id: saveLoadDialog
            anchors.centerIn: parent

            title: qsTr("Save / Load")
            standardButtons: Dialog.Ok | Dialog.Cancel
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                id: saveLoadLayout
                Layout.maximumWidth: window.width
                Layout.maximumHeight: window.height

                spacing: 10

                Item {
                    Layout.preferredWidth: saveLoadEditActionsLayout.width
                    Layout.preferredHeight: saveLoadEditActionsLayout.height

                    RowLayout {
                        id: saveLoadEditActionsLayout
                        spacing: 5

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

                            source: "qrc:/images/undo"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    saveLoadTextInput.undo()
                                }
                            }

                            ColorOverlay {
                                source: parent
                                anchors.fill: parent
                                color: saveLoadTextInput.canUndo ? Universal.foreground : hoverColor
                            }
                        }

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

                            source: "qrc:/images/copy"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    saveLoadTextInput.selectAll()
                                    saveLoadTextInput.copy()
                                    saveLoadEditActionsLabel.text = qsTr("Copied!")
                                    saveLoadEditActionsAnimation.restart()
                                }
                            }

                            ColorOverlay {
                                source: parent
                                anchors.fill: parent
                                color: Universal.foreground
                            }
                        }

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

                            source: "qrc:/images/paste"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    saveLoadTextInput.clear()
                                    saveLoadTextInput.paste()
                                    saveLoadEditActionsLabel.text = qsTr("Pasted!")
                                    saveLoadEditActionsAnimation.restart()
                                }
                            }

                            ColorOverlay {
                                source: parent
                                anchors.fill: parent
                                color: Universal.foreground
                            }
                        }

                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32

                            source: "qrc:/images/delete"

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    saveLoadTextInput.clear()
                                    saveLoadEditActionsLabel.text = qsTr("Deleted!")
                                    saveLoadEditActionsAnimation.restart()
                                }
                            }

                            ColorOverlay {
                                source: parent
                                anchors.fill: parent
                                color: Universal.foreground
                            }
                        }

                        Label {
                            id: saveLoadEditActionsLabel
                            font.pixelSize: normalFontSize

                            NumberAnimation on opacity {
                                id: saveLoadEditActionsAnimation
                                running: false
                                from: 1.0
                                to: 0.0
                                duration: 1500
                            }
                        }
                    }
                }

                ScrollView {
                    Layout.preferredWidth: saveLoadTextInput.contentWidth + 20
                    Layout.preferredHeight: saveLoadTextInput.contentHeight + 20
                    Layout.maximumWidth: window.width
                    Layout.maximumHeight: window.height
                    Layout.minimumWidth: saveLoadEditActionsLayout.width
                    Layout.minimumHeight: normalFontSize + 5

                    TextArea {
                        id: saveLoadTextInput

                        clip: true
                        focus: true
                        font.pixelSize: normalFontSize

                        placeholderText: qsTr("Enter save content here...")
                        placeholderTextColor: hoverColor
                    }
                }
            }

            onOpened: {
                function listModelToJson(model) {
                    let jsonObj = []
                    for (let i = 0; i < model.count; i++) {
                        jsonObj.push(model.get(i))
                    }
                    return jsonObj
                }

                saveLoadTextInput.text = JSON.stringify({
                    alertVolume: window.alertVolume,
                    isFullScreen: window.isFullScreen,
                    isWindowLocked: window.isWindowLocked,
                    alertMood: window.alertMood,
                    uiTheme: window.uiTheme,
                    uiLanguage: window.uiLanguage,

                    reminders: listModelToJson(reminders).concat(listModelToJson(pendingReminders))
                }, null, 4)
            }

            onAccepted: {
                /* Transaction schema:
                {
                    alertVolume: Number
                    isFullScreen: Boolean
                    isWindowLocked: Boolean
                    alertMood: String
                    uiMode: String
                    uiLanguage: String

                    reminders: [
                        {
                            // This includes both normal and pending reminders
                            name: "something"
                            time: unix stamp in milliseconds
                            labelColor: "black"
                        },
                        ...
                    ]
                }
                */

                function listModelToJson(model) {
                    let jsonObj = []
                    for (let i = 0; i < model.count; i++) {
                        jsonObj.push(model.get(i))
                    }
                    return jsonObj
                }

                function appendJsonToListModel(model, jsonStr) {
                    let jsonObj = JSON.stringify(jsonStr);
                    model.append(jsonObj)
                }

                // Reset the select index, or else out of range errors
                selectedIndex = -1

                // Stop the timer because we dont want alert in loading
                scheduleTimer.stop()

                // Make a copy of the current configuration
                // This is not property binding btw :)
                var backupSave = {
                    alertVolume: window.alertVolume,
                    isFullScreen: window.isFullScreen,
                    isWindowLocked: window.isWindowLocked,
                    alertMood: window.alertMood,
                    uiTheme: window.uiTheme,
                    uiLanguage: window.uiLanguage,

                    reminders: JSON.parse(JSON.stringify(listModelToJson(reminders).concat(listModelToJson(pendingReminders))))
                }

                try {
                    // Perform transaction
                    let potentialSave = JSON.parse(saveLoadTextInput.text)

                    for (let i = 0; i < potentialSave.reminders.length; i++) {
                        if ((typeof potentialSave.reminders[i].name !== 'string') ||
                            (typeof potentialSave.reminders[i].time !== 'number') ||
                            (typeof potentialSave.reminders[i].labelColor !== 'string')) {
                            throw `Invalid reminders data from index ${i}: ${JSON.stringify(potentialSave.reminders[i])}`
                        }
                    }

                    alertVolume = potentialSave.alertVolume
                    isFullScreen = potentialSave.isFullScreen
                    isWindowLocked = potentialSave.isWindowLocked
                    alertMood = potentialSave.alertMood
                    uiTheme = potentialSave.uiTheme
                    uiLanguage = potentialSave.uiLanguage
                    Qt.uiLanguage = potentialSave.uiLanguage

                    reminders.clear()
                    pendingReminders.clear()
                    if (potentialSave.reminders.length > 0) {
                        reminders.append(potentialSave.reminders)
                    }
                    scheduleTimer.restart()
                } catch (err1) {
                    try {
                        alertVolume = backupSave.alertVolume
                        isFullScreen = backupSave.isFullScreen
                        isWindowLocked = backupSave.isWindowLocked
                        alertMood = backupSave.alertMood
                        uiTheme = backupSave.uiTheme
                        uiLanguage = backupSave.uiLanguage
                        Qt.uiLanguage = backupSave.uiLanguage

                        reminders.clear()
                        pendingReminders.clear()
                        if (backupSave.reminders.length > 0) {
                            reminders.append(backupSave.reminders)
                        }

                        // Tell user that things are failed
                        errMsg = qsTr("Cannot load save.\nLast known configuration restored.")
                        errStack = err1?.toString() + "\n" + qsTr("Call stack") + ": " + err1.stack?.toString()
                        windowLoader.sourceComponent = errorComponent
                        windowLoader.item.open()
                    } catch (err2) {
                        // If rollback failed, default value is used
                        alertVolume = 0.5
                        isFullScreen = false
                        isWindowLocked = false
                        alertMood = "neutral"
                        uiTheme = "system"
                        uiLanguage = defaultLanguage
                        Qt.uiLanguage = defaultLanguage

                        reminders.clear()
                        pendingReminders.clear()

                        // Tell user that things are fucked
                        errMsg = qsTr("Cannot load save.\nDefault values restored.")
                        errStack = err2.toString() + "\n" + qsTr("Call stack") + ": " + err2.stack?.toString()
                        windowLoader.sourceComponent = errorComponent
                        windowLoader.item.open()
                    }
                }
            }
        }
    }
    Component {
        id: errorComponent

        Dialog {
            id: errorDialog
            anchors.centerIn: parent

            standardButtons: Dialog.Ok
            title: qsTr("An error has occurred.")
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                spacing: 10

                TextEdit {
                    id: errStackTextEdit

                    visible: false
                    Layout.maximumWidth: 0
                    Layout.maximumHeight: 0

                    text: errStack
                }

                Label {
                    text: errMsg
                    font.pixelSize: normalFontSize
                }

                RowLayout {
                    spacing: 10

                    Button {
                        text: qsTr("Copy error to clipboard")
                        font.pixelSize: normalFontSize

                        onClicked: {
                            errStackTextEdit.selectAll()
                            errStackTextEdit.copy()
                            errorCopyAnimation.restart()
                        }
                    }

                    Label {
                        id: errorCopyLabel
                        opacity: 0.0
                        text: qsTr("Copied!")
                        font.pixelSize: smallFontSize

                        NumberAnimation on opacity {
                            id: errorCopyAnimation
                            running: false
                            from: 1.0
                            to: 0.0
                            duration: 1500
                        }
                    }
                }
            }

            onAccepted: {
                scheduleTimer.start()
            }
        }

    }
    Component {
        id: infoComponent

        Dialog {
            id: infoDialog
            anchors.centerIn: parent

            standardButtons: Dialog.Ok
            title: qsTr("About QReminder")
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                spacing: 10

                Flickable {
                    Layout.preferredWidth: infoLabel.width
                    Layout.maximumWidth: window.width
                    Layout.preferredHeight: infoLabel.height
                    Layout.maximumHeight: window.height
                    contentWidth: infoLabel.width
                    contentHeight: infoLabel.height
                    clip: true

                    Label {
                        id: infoLabel
                        text: qsTr("Copyright (C) 2024 An Van Quoc.

You can redistribute this software under the
GNU General Public License, version 3 or later.

Icons are sourced from Material Design Icons.
These are licensed under Apache License 2.0.

Audio are from Material Design Sounds, by Google
(https://m2.material.io/design/sound/sound-resources.html)
These are licensed under CC BY 4.0 license.

This program uses Qt version 6.8.
Copyright (C) 2024 The Qt Company Ltd
and other contributors.")
                        font.pixelSize: smallFontSize
                    }
                }
            }
        }

    }
    Component {
        id: kioskComponent

        Dialog {
            id: kioskDialog
            anchors.centerIn: parent

            standardButtons: Dialog.Ok | Dialog.Cancel
            title: qsTr("Kiosk Mode")
            closePolicy: Dialog.NoAutoClose
            modal: true

            ColumnLayout {
                spacing: 10

                Label {
                    text: qsTr("These changes will be applied:
 - Save / Load is no longer available.
 - Settings is no longer available.
 - Revert to normal is not possible.

Please note that other configurations are
needed depending on your requirements.

If you agree to these changes, type
    QREMINDER-KIOSK-ON
and click OK. Otherwise, click Cancel.")
                    font.pixelSize: smallFontSize
                }

                TextInput {
                    id: kioskText
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true

                    font.pixelSize: 16
                    font.weight: 600
                    color: Universal.foreground

                    property string placeholderText: qsTr("Enter here...")

                    Text {
                        text: parent.placeholderText
                        opacity: 0.5
                        color: Universal.foreground
                        font.pixelSize: parent.font.pixelSize
                        visible: !parent.text
                    }
                }
            }

            onOpened: {
                kioskText.focus = true
                kioskText.clear()
            }

            onAccepted: {
                if (kioskText.text === "QREMINDER-KIOSK-ON") {
                    saveLoadButton.width = 0
                    settingsButton.width = 0
                    seperator1.width = 0
                    seperator2.width = 0
                    windowLoader.item.close() // Only settings page open this
                    windowLoader.sourceComponent = undefined
                }
            }
        }
    }
    Loader {
        id: windowLoader
        anchors.centerIn: parent
        sourceComponent: undefined
    }
    Loader {
        id: subDialogLoader
        anchors.centerIn: parent
        sourceComponent: undefined
    }
    Popup {
        id: remindersAlertPopup
        width: window.width
        height: window.height
        modal: true
        focus: true
        closePolicy: Popup.NoAutoClose

        property bool isOpened: false

        background: Rectangle {
            color: "red"
        }

        ColumnLayout {
            anchors.centerIn: parent

            spacing: 10

            Label {
                id: attentionLabel
                color: "black"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: contentWidth
                Layout.preferredHeight: contentHeight

                text: qsTr("Reminder Alert.")
                font.pixelSize: veryLargeFontSize
            }
            ListView {
                id: pendingRemindersListView

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: window.width
                Layout.preferredHeight: contentHeight
                Layout.maximumHeight: window.height - 200

                model: pendingReminders
                delegate: ItemDelegate {
                    anchors.horizontalCenter: parent?.horizontalCenter

                    background: Rectangle {
                        id: reminderAlertsBackground
                        color: "gray"
                        opacity: 0.0
                        radius: 5

                        MouseArea {
                            anchors.fill: parent

                            hoverEnabled: true

                            onEntered: parent.opacity = 0.5
                            onExited: parent.opacity = 0.0
                        }
                    }

                    contentItem: ColumnLayout {
                        anchors.horizontalCenter: parent?.horizontalCenter
                        spacing: 5

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: name
                            color: "black"
                            font.pixelSize: veryLargeFontSize
                        }

                        Label {
                            id: timeAlertDisplayLabel
                            Layout.alignment: Qt.AlignHCenter
                            text: currentTimestamp, getBeautifyTimeString(time)
                            color: "black"
                            font.pixelSize: normalFontSize
                        }
                    }

                    onPressed: reminderAlertsBackground.opacity = 0.9
                    onReleased: reminderAlertsBackground.opacity = 0.5

                    onClicked: {
                        timeAlertDisplayLabel.text = "" // prevent NaN
                        pendingReminders.remove(index)
                        if (pendingReminders.count === 0) {
                            remindersAlertPopup.close()
                            alertPlayer.stop()
                        }
                    }
                }
            }
            MouseArea {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: skipReminderAlertLayout.width
                Layout.preferredHeight: skipReminderAlertLayout.height

                pressAndHoldInterval: 5000

                RowLayout {
                    id: skipReminderAlertLayout
                    spacing: 5

                    Item {
                        Layout.preferredWidth: skipImage.width
                        Layout.preferredHeight: skipImage.height

                        Image {
                            id: skipImage
                            source: "qrc:/images/skip"
                        }
                        ColorOverlay {
                            anchors.fill: parent

                            source: skipImage
                            color: "black"
                        }
                    }

                    Text {
                        id: name
                        text: isSkipNotHeld ? qsTr("Hold 5 seconds") : ""
                        font.pixelSize: largeFontSize
                    }
                }

                onReleased: {
                    isSkipNotHeld = true
                }

                onPressAndHold: function (_) {
                    pendingReminders.clear()
                    remindersAlertPopup.close()
                    alertPlayer.stop()
                }
            }
        }
        onOpened: isOpened = true
        onClosed: {
            isOpened = false
            isSkipNotHeld = false
        }
    }

    // Main UI
    ColumnLayout {
        id: centerUiLayout
        anchors.centerIn: parent

        spacing: 10

        Label {
            id: titleText
            visible: reminders.count <= 0
            height: visible ? height : 0
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: contentWidth
            Layout.preferredHeight: contentHeight

            text: qsTr("Reminders")
            font.pixelSize: veryLargeFontSize
        }

        ListView {
            id: remindersListView

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: window.width
            Layout.preferredHeight: contentHeight
            Layout.maximumHeight: window.height - 200

            model: reminders
            highlightRangeMode: ListView.ApplyRange
            delegate: ItemDelegate {
                hoverEnabled: true
                anchors.horizontalCenter: parent?.horizontalCenter

                background: Rectangle {
                    id: remindersItemBackground
                    color: hoverColor
                    opacity: 0.0
                    radius: 5

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true

                        onEntered: parent.opacity = 0.25
                        onExited: parent.opacity = 0.0
                    }
                }

                contentItem: ColumnLayout {
                    anchors.horizontalCenter: parent?.horizontalCenter
                    spacing: 5

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: (selectedIndex === index ? "→ " : "") +
                              name +
                              (selectedIndex === index ? " ←" : "")
                        color: Universal.foreground
                        font.pixelSize: veryLargeFontSize
                        font.weight: selectedIndex === index
                            ? 600
                            : 400

                        Component.onCompleted: {
                            if (labelColor !== "default") {
                                this.color = labelColor
                            }
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: currentTimestamp, getBeautifyTimeString(time)
                        color: Universal.foreground
                        font.pixelSize: normalFontSize

                        Component.onCompleted: {
                            if (labelColor !== "default") {
                                this.color = labelColor
                            }
                        }
                    }
                }

                onPressed: remindersItemBackground.opacity = 0.5
                onReleased: remindersItemBackground.opacity = 0.25

                onClicked: {
                    if (selectedIndex === index) {
                        selectedIndex = -1;
                    } else {
                        selectedIndex = index;
                    }

                    deleteButton.enabled = true;
                }
            }
            onCountChanged: {
                Qt.callLater(remindersListView.positionViewAtEnd)
            }
        }
        Item {
            Layout.preferredWidth: actionButtonsLayout.width
            Layout.preferredHeight: actionButtonsLayout.height
            Layout.alignment: Qt.AlignHCenter

            RowLayout {
                id: actionButtonsLayout

                spacing: 16
                opacity: 0

                Image {
                    id: createNewButton

                    source: "qrc:/images/add"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            windowLoader.sourceComponent = createNewComponent
                            windowLoader.item.open()
                        }
                    }
                }
                Image {
                    id: deleteButton

                    source: "qrc:/images/delete"
                    opacity: deleteMouseArea.enabled ? 1.0 : 0.3

                    MouseArea {
                        id: deleteMouseArea
                        anchors.fill: parent
                        enabled: selectedIndex >= 0 ? true : false
                        onClicked: {
                            reminders.remove(selectedIndex)
                            selectedIndex = -1
                        }
                    }
                }
                Image {
                    id: saveLoadButton

                    source: "qrc:/images/saveLoad"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            windowLoader.sourceComponent = saveLoadComponent
                            windowLoader.item.open()
                        }
                    }
                }
                Image {
                    id: settingsButton

                    source: "qrc:/images/settings"

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            windowLoader.sourceComponent = settingsComponent
                            windowLoader.item.open()
                        }
                    }
                }
            }
            ColorOverlay {
                source: actionButtonsLayout
                anchors.fill: actionButtonsLayout

                cached: true
                color: Universal.foreground
            }
        }
    }

    function getTheme() {
        switch (uiTheme) {
        case "system":
            switch (Application.styleHints.colorScheme) {
            case Qt.Dark:
                return Universal.Dark
            case Qt.Light:
                return Universal.Light
            default:
                return Universal.System
            }
        case "dark":
            return Universal.Dark
        case "light":
            return Universal.Light
        default:
            console.error("Cannot find maching theme: ", uiTheme)
            return Universal.System
        }
    }
    function getBeautifyTimeString(timestamp) {
        let diff = (Number(timestamp) - currentTimestamp) / 1000
        let isAgo = diff < 0
        if (diff < 0) diff = -diff
        let days = Math.floor(diff / 86400)
        let remainder = diff % 86400;
        let hours = Math.floor(remainder / 3600)
        remainder = diff % 3600
        let minutes = Math.floor(remainder / 60)
        let seconds = Math.floor(diff % 60)

        let commaSeperator = qsTr(", ") // Some languages does not have comma
        let result = ""
        let isTop = false

        // console.log(diff, days, hours, minutes, seconds)

        if (days > 0) {
            isTop = true
            result += `${days} ` + qsTr("day");
        }

        if (hours > 0) {
            if (days > 0)
                result += commaSeperator
            else {
                isTop = true
            }

            result += `${hours} ` + qsTr("hour")
        }

        if (minutes > 0) {
            if (days > 0 || hours > 0) {
                result += commaSeperator
            } else {
                isTop = true
            }

            result += `${minutes} ` + qsTr("minute")
        }

        if (seconds > 0) {
            if (days > 0 || hours > 0 || minutes > 0) {
                result += commaSeperator
            } else {
                isTop = true
            }

            result += `${seconds} ` + qsTr("second")
        }

        if (!isTop) { // 0 seconds
            if (isNaN(result)) result = qsTr("Time not available")
            else result = qsTr("Just now")
        } else if (isAgo) {
            result += qsTr(" ago")
        }

        return result
    }

    // Window-specific events
    Component.onCompleted: function () {
        defaultLanguage = Qt.uiLanguage
    }

    onClosing: function (closeEvent) {
        if (isWindowLocked) {
            closeEvent.accepted = false
        }
    }
}
