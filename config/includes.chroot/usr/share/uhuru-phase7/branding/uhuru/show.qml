import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 7000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Karibu Uhuru OS"; color: "#f5c518"; font.pixelSize: 34; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Mfumo wako, uhuru wako."; color: "#eaf6f6"; font.pixelSize: 18 }
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Salama kwa msingi"; color: "#f5c518"; font.pixelSize: 30; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ngome ya moto, ulinzi wa flash na sasisho za usalama."; color: "#eaf6f6"; font.pixelSize: 16 }
            }
        }
    }
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0b3b44"
            Column {
                anchors.centerIn: parent
                spacing: 14
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Tayari kwa kazi"; color: "#f5c518"; font.pixelSize: 30; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "LGT Store, TraceTZ Hub na zana za msanidi."; color: "#eaf6f6"; font.pixelSize: 16 }
            }
        }
    }
}
