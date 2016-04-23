import QtQuick 2.4
import QtQuick.LocalStorage 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Styles 1.3
import Ubuntu.Content 1.1
import Ubuntu.Components.Popups 1.3
import Ubuntu.Connectivity 1.0
import "../components"
import "../js/localdb.js" as LocalDb
import "../js/user.js" as User
import "../js/scripts.js" as Scripts

Page {
    id: pocketArchive

    TabsList {
        id: tabsList
    }

    header: PageHeader {
        title: i18n.tr("Archive")
        StyleHints {
            backgroundColor: currentTheme.backgroundColor
            foregroundColor: currentTheme.baseFontColor
        }
        leadingActionBar {
            actions: tabsList.actions
        }
        trailingActionBar {
            numberOfSlots: 2
            actions: [searchAction, settingsAction, refreshAction, aboutAction]
        }
    }

    function get_list() {
        Scripts.get_list()
    }

    function home() {
        // Offline articles
        Scripts.my_archive_list()
    }

    Component.onCompleted: {
        home()
    }

    //property bool finished: true
    property bool empty: false

    BouncingProgressBar {
        id: bouncingProgress
        z: 9
        anchors.top: pocketArchive.header.bottom
        visible: finished == false
    }

    EmptyBar {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: bouncingProgress.bottom
        }
        visible: empty == true

        title: i18n.tr("Archive Empty")
        description: i18n.tr("The Archive can list items that you're finished with.")
        help: i18n.tr("To add items to your Archive list, tap the checkmark button after swiping from right on item.")
    }

    ListModel {
        id: archiveModel
    }

    Loader {
        id: viewLoader
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: bouncingProgress.bottom
        }
        sourceComponent: archiveListComponent
    }

    Component {
        id: archiveListComponent

        ListView {
            id: archiveList
            anchors.fill: parent
            clip: true
            model: archiveModel
            delegate: ListItem {
                id: archiveListDelegate
                divider.visible: true
                height: entry_row.height

                property var removalAnimation

                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            enabled: Connectivity.online
                            iconName: "delete"
                            text: i18n.tr("Remove")
                            onTriggered: {
                                removalAnimation.start()
                                Scripts.delete_item(item_id)
                            }
                        }
                    ]
                }
                trailingActions: ListItemActions {
                    delegate: Item {
                        width: units.gu(6)
                        Icon {
                            name: action.iconName
                            width: units.gu(2)
                            height: width
                            color: action.iconColor ? action.iconColor : UbuntuColors.lightGrey
                            anchors.centerIn: parent
                        }
                    }
                    actions: [
                        Action {
                            enabled: Connectivity.online
                            iconName: "share"
                            text: i18n.tr("Share")
                            onTriggered: {
                                PopupUtils.open(shareDialog, pageStack, {"contentType": ContentType.Links, "path": resolved_url});
                            }
                        },
                        Action {
                            enabled: Connectivity.online
                            iconName: "add"
                            text: i18n.tr("Readd")
                            onTriggered: {
                                removalAnimation.start()
                                Scripts.archive_item(item_id, '0')
                                myListPage.home(true)
                                favListPage.home()
                                archiveListPage.home()
                            }
                        },
                        Action {
                            enabled: Connectivity.online
                            iconName: "tag"
                            text: i18n.tr("Tags")
                            onTriggered: {
                                entryTagsPage.entry_id = item_id
                                entryTagsPage.home()
                                pageStack.push(entryTags)
                            }
                        },
                        Action {
                            enabled: Connectivity.online
                            iconName: "starred"
                            text: i18n.tr("Favorite")
                            property var iconColor: favorite == 1 ? UbuntuColors.blue : UbuntuColors.lightGrey
                            property var is_fav: favorite == 1 ? 1 : 0
                            onTriggered: {
                                if (is_fav == 1) {
                                    Scripts.fav_item(item_id, 0)
                                    iconColor = UbuntuColors.lightGrey
                                } else {
                                    Scripts.fav_item(item_id, 1)
                                    iconColor = UbuntuColors.blue
                                }
                                favListPage.home()
                                archiveListPage.home()
                            }
                        }
                    ]
                }

                removalAnimation: SequentialAnimation {
                    alwaysRunToEnd: true

                    PropertyAction {
                        target: archiveListDelegate
                        property: "ListView.delayRemove"
                        value: true
                    }

                    UbuntuNumberAnimation {
                        target: archiveListDelegate
                        property: "height"
                        to: 0
                    }

                    PropertyAction {
                        target: archiveListDelegate
                        property: "ListView.delayRemove"
                        value: false
                    }
                }

                Row {
                    id: entry_row
                    width: parent.width
                    height: entry_column.height + units.gu(3)
                    Column {
                        id: entry_column
                        spacing: units.gu(1)
                        anchors.verticalCenter: parent.verticalCenter
                        width: image == '' ? parent.width : parent.width - units.gu(10)

                        Label {
                            id: entry_title
                            x: units.gu(2)
                            width: parent.width - units.gu(4)
                            text: resolved_title
                            fontSize: "medium"
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            id: entry_domain
                            x: units.gu(2)
                            width: parent.width - units.gu(4)
                            text: only_domain
                            fontSize: "x-small"
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            width: parent.width - units.gu(4)
                            x: units.gu(2)
                            spacing: units.gu(0.5)
                            Repeater {
                                model: tags
                                Rectangle {
                                    height: tag_label.height + units.gu(0.5)
                                    width: tag_label.width + units.gu(1.5)
                                    color: "#c3c3c3"
                                    radius: units.gu(0.3)
                                    Label {
                                        anchors.centerIn: parent
                                        id: tag_label
                                        text: tag
                                        color: "#ffffff"
                                        fontSize: "x-small"
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: entry_image_box
                        width: image == '' ? 0 : units.gu(10)
                        height: entry_column.height + units.gu(3)
                        color: "#dfdfdf"
                        Image {
                            id: entry_image
                            width: parent.width
                            height: parent.height
                            source: image
                            clip: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        Image {
                            id: videoicon
                            width: parent.width/2
                            height: width
                            visible: has_video != '0' ? true : false
                            anchors.centerIn: parent
                            source: "../img/play.png"
                            clip: true
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push(articleView);
                        Scripts.parseArticleView(resolved_url, item_id);
                    }
                }
            }
        }
    }
}
