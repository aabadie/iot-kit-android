import QtQuick 2.7
import QtWebSockets 1.0
import QtPositioning 5.2
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.4

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("RIOT Dashboard Node")
    
    property string currentText: "No message"
    property string websocketUrl: "ws://riot-demo.inria.fr/ws"
    property variant resources:
    { 
        "os": "android",
        "name": "Android Node",
        "position": 
            { 
                "lat": positionSource.position.coordinate.latitude,
                "lng": positionSource.position.coordinate.longitude
            },
        "text": currentText
    }
    
    function sendMessage(type, data) {
        if (socket.status !== WebSocket.Open) {
            return
        }
        
        var message = {   
            "type": type,
            "data": data
        }
        //        console.log("Sending message", JSON.stringify(message))
        socket.sendTextMessage(JSON.stringify(message))
    }
    
    Timer {
        id: positionTimer
        
        interval: 5000
        running: true
        repeat: true
        
        onTriggered: {
            sendMessage("update",
                        {
                            "position": { 
                                "lat": positionSource.position.coordinate.latitude,
                                "lng": positionSource.position.coordinate.longitude
                            }
                        })
        }
    }
    
    WebSocket {
        id: socket
        url: websocketUrl
        
        onTextMessageReceived: {
            var msg = JSON.parse(message)
            if (msg.request === undefined) {
                return
            }
            
            if (msg.request === "discover") {
                sendMessage("update", resources)
            }
            else if (msg.request === "update") {
                if (msg.text !== undefined && msg.data !== undefined) {
                    currentText = msg.data
                }
            }
        }
        
        onStatusChanged: {
            if (socket.status == WebSocket.Error) {
                console.log("Error: " + socket.errorString)
            } else if (socket.status == WebSocket.Open) {
                console.log("Socket connected")
                sendMessage("new", "node")
                sendMessage("update", resources)
            } else if (socket.status == WebSocket.Closed) {
                console.log("Socket closed")
            }
        }
        
        active: true
    }
    
    PositionSource {
        id: positionSource
        
        onPositionChanged: { 
            console.log("Lat:", position.coordinate.latitude, "Lng:", position.coordinate.longitude)
            latitudeText.text = qsTr("Lat: %1°").arg(position.coordinate.latitude)
            longitudeText.text = qsTr("Lng: %1°").arg(position.coordinate.longitude)
        }
        
        onSourceErrorChanged: {
            if (sourceError == PositionSource.NoError) {
                console.log("Source error: No Error")
                return
            }
            
            console.log("Source error: " + sourceError)
            stop()
        }
        
        onUpdateTimeout: {
            console.log("Update")
        }
    }
   
    Item {
        id: contentItem

        anchors.fill: parent
        
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Row {
                spacing: 20
                
                Text {
                    id: latitudeText
                }
                Text {
                    id: longitudeText
                }
            }
            
            Row {
                spacing: 5
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Message:"
                    font.bold: true
                }
                
                TextField {
                    anchors.verticalCenter: parent.verticalCenter
                    placeholderText: currentText
                    width: contentItem.width * 0.75
                    
                    style: TextFieldStyle {
                            textColor: "black"
                            background: Rectangle {
                                radius: 2
                                border.color: "#333"
                                border.width: 1
                            }
                        }
                    
                    onAccepted: {
                        currentText = text
                        sendMessage("update", { "text": text })
                    }
                }
            }
        }
    }
}
