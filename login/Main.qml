import QtQuick 2.15
import QtQuick.Effects
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#090909"
    property string currentUser: userModel.lastUser
    property bool loginFailed: false
    property int sessionIndex: {
        for (var i = 0; i < sessionModel.rowCount(); i++) {
            var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
            if (name.indexOf("uwsm") !== -1) return i
        }
        return sessionModel.lastIndex
    }
    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginFailed = true
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() { root.loginFailed = false }
    }
    Rectangle {
        anchors.centerIn: parent
        width: 440
        height: 278
        radius: 5
        color: "#f0100d09"
        border.color: "#ec934b"
        border.width: 2
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#c47a28"
            shadowOpacity: 0.42
            shadowBlur: 0.85
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            blurMax: 40
        }
        Column {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 18
            Text {
                text: "PLASMA / 585"
                color: "#ffe3ae"
                font.family: "monospace"
                font.pixelSize: 26
                font.letterSpacing: 3
                style: Text.Outline
                styleColor: "#704218"
            }
            Text {
                text: "SESSION / " + root.currentUser.toUpperCase()
                color: "#7e9f64"
                font.family: "monospace"
                font.pixelSize: 12
                font.letterSpacing: 1
            }
            Rectangle {
                width: parent.width
                height: 52
                radius: 3
                color: "#141414"
                border.color: root.loginFailed ? "#ef8063" : password.text.length ? "#ffbe66" : "#777777"
                border.width: 1
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "PASSWORD"
                    visible: password.text.length === 0
                    color: "#ab997b"
                    font.family: "monospace"
                    font.pixelSize: 14
                }
                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.margins: 14
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "\u25cf"
                    passwordMaskDelay: 0
                    color: root.loginFailed ? "#ef8063" : "#ffd58a"
                    layer.enabled: text.length > 0
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: root.loginFailed ? "#dc6334" : "#ffad42"
                        shadowOpacity: 0.85
                        shadowBlur: 0.45
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                        blurMax: 16
                        autoPaddingEnabled: true
                    }
                    selectionColor: "#343434"
                    selectedTextColor: "#ffe3ae"
                    font.family: "monospace"
                    font.pixelSize: 20
                    focus: true
                    onTextEdited: root.loginFailed = false
                    Keys.onReturnPressed: sddm.login(root.currentUser, password.text, root.sessionIndex)
                    Keys.onEnterPressed: sddm.login(root.currentUser, password.text, root.sessionIndex)
                }
            }
            Rectangle {
                width: parent.width
                height: 38
                radius: 2
                color: button.pressed ? "#aa672f" : button.containsMouse ? "#e9c66d" : "#ec934b"
                border.color: "#936038"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.loginFailed ? "RETRY / ENTER" : "CONNECT / ENTER"
                    font.family: "monospace"
                    font.bold: true
                    font.pixelSize: 13
                    color: "#101010"
                }
                MouseArea {
                    id: button
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.login(root.currentUser, password.text, root.sessionIndex)
                }
            }
        }
    }
    Component.onCompleted: password.forceActiveFocus()
}
