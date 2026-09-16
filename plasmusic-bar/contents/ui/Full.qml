import "./components"
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import Qt5Compat.GraphicalEffects

Item {
	id: root
	
	// ==================== 新增：SoundBars 音频跳动条组件 ====================
	component SoundBars: Row {
		property bool playing: false
		spacing: 3
		width: 28
		height: 24
		Repeater {
			model: [12, 18, 10, 16, 14]
			Rectangle {
				id: bar
				width: 2.5
				height: modelData
				y: (parent.height - height) / 2
				radius: 1.5
				color: Kirigami.Theme.textColor
				opacity: playing ? 0.9 : 0.4
				transformOrigin: Item.Center
				transform: Scale {
					origin.x: bar.width / 2
					origin.y: bar.height / 2
					yScale: playing ? 1 : 0.5
					SequentialAnimation on yScale {
						running: playing
						loops: Animation.Infinite
						NumberAnimation {
							to: 0.3 + ((index * 13) % 40) / 100
							duration: 220 + index * 40
							easing.type: Easing.InOutSine
						}
						NumberAnimation {
							to: 1
							duration: 220 + index * 40
							easing.type: Easing.InOutSine
						}
					}
				}
			}
		}
	}
	// ========================================================================
	
	enum SongAndArtistTextPosition {
		AboveProgressBar,
		UnderProgressBar
	}
	
	property string albumPlaceholder: plasmoid.configuration.albumPlaceholder
	property bool albumCoverBackground: plasmoid.configuration.fullAlbumCoverAsBackground
	property bool thumbnailVisible: plasmoid.configuration.fullViewThumbnailVisible
	property bool progressBarVisible: plasmoid.configuration.fullViewProgressBarVisible
	property bool songTextVisible: plasmoid.configuration.fullViewSongTextVisible
	property int songTextAlignment: plasmoid.configuration.fullViewSongTextAlignment
	property bool songTextAboveProgressBar: plasmoid.configuration.fullViewSongTextPosition === Full.SongAndArtistTextPosition.AboveProgressBar
	// The Full View max and min width is driven by config values. The window can be resized within these bounds; thumbnail and text adapt.
	readonly property int configMinWidth: plasmoid.configuration.fullViewMinWidth
	readonly property int maximumWidth: plasmoid.configuration.fullViewMaxWidth
	property bool fullAlbumCoverRounded: plasmoid.configuration.fullAlbumCoverRounded
	property int albumCoverRadius: plasmoid.configuration.fullAlbumCoverRadius
	readonly property int effectiveMinWidth: Math.min(configMinWidth, maximumWidth)
	Layout.minimumWidth: effectiveMinWidth
	Layout.maximumWidth: maximumWidth
	Layout.preferredWidth: effectiveMinWidth
	Layout.preferredHeight: column.implicitHeight
	Layout.minimumHeight: column.implicitHeight
	Layout.maximumHeight: column.implicitHeight
	// Store the original theme colors (root keeps default Kirigami.Theme.inherit: true)
	readonly property color _originalTextColor: Kirigami.Theme.textColor
	readonly property color _originalHighlightColor: Kirigami.Theme.highlightColor
	
	Item {
		visible: albumCoverBackground && thumbnailVisible
		Layout.margins: 0
		anchors.centerIn: parent
		height: column.height
		width: column.width
		
		ImageWithPlaceholder {
			id: albumArtFull
			anchors.top: parent.top
			anchors.horizontalCenter: parent.horizontalCenter
			height: parent.height * 0.7
			width: parent.width
			fillMode: Image.PreserveAspectCrop
			placeholderSource: albumPlaceholder
			imageSource: player.artUrl
			onStatusChanged: {
				if (status === Image.Ready) {
					imageColors.update()
				}
			}
			Kirigami.ImageColors {
				id: imageColors
				source: albumArtFull
				readonly property color bgColor: average
				readonly property var bgColorBrightness: Kirigami.ColorUtils.brightnessForColor(bgColor)
				readonly property color contrastColor: bgColorBrightness === Kirigami.ColorUtils.Dark ? "white" : "black"
				readonly property color fgColor: Kirigami.ColorUtils.tintWithAlpha(bgColor, contrastColor, .6)
				readonly property color hlColor: Kirigami.ColorUtils.tintWithAlpha(bgColor, contrastColor, .8)
			}
			layer.enabled: root.fullAlbumCoverRounded && root.albumCoverRadius > 0
			layer.effect: OpacityMask {
				maskSource: Item {
					width: albumArtFull.width
					height: albumArtFull.height
					Rectangle {
						anchors.fill: parent
						radius: albumCoverRadius
						bottomRightRadius: 0
						bottomLeftRadius: 0
					}
				}
			}
		}
		
		LinearGradient {
			id: mask
			anchors.fill: parent
			gradient: Gradient {
				GradientStop { position: 0; color: headerbar.visible ? imageColors.bgColor : "transparent" }   // Adjust top gradient when the player selector is visible
				GradientStop { position: 0.11; color: "transparent" }
				GradientStop { position: headerbar.visible ? 0.5 : 0.4; color: "transparent" }
				GradientStop { position: 0.7; color: imageColors.bgColor }
				GradientStop { position: 1; color: imageColors.bgColor }
			}
		}
	}
	
	ColumnLayout {
		id: column
		spacing: 0
		anchors.fill: parent
		// Override theme ONLY for this layout and its children
		Kirigami.Theme.inherit: false
		Kirigami.Theme.textColor: albumCoverBackground ? imageColors.fgColor : root._originalTextColor
		Kirigami.Theme.highlightColor: albumCoverBackground ? imageColors.hlColor : root._originalHighlightColor
		
		// Media Player Selector
		Rectangle {
			id: headerbar
			Layout.fillWidth: true
			visible: plasmoid.configuration.showPlayerSelector
			&& playerList.count > 2
			&& player.sourceIdentities == null
			color: albumCoverBackground
			? "transparent"
			: Kirigami.Theme.backgroundColor
			implicitHeight: Kirigami.Units.gridUnit * 2
			PlasmaComponents3.TabBar {
				id: playerSelector
				objectName: "playerSelector"
				anchors.fill: parent
				implicitHeight: contentHeight
				currentIndex: player.mpris2Model.currentIndex
				Repeater {
					id: playerList
					model: player.mpris2Model
					delegate: PlasmaComponents3.TabButton {
						required property string iconName
						required property bool isMultiplexer
						required property string identity
						required property int index
						anchors.top: parent?.top
						anchors.bottom: parent?.bottom
						display: PlasmaComponents3.AbstractButton.IconOnly
						icon.name: iconName
						icon.height: Kirigami.Units.iconSizes.small
						text: isMultiplexer ? i18nc("@action:button", "Choose player automatically") : identity
						Accessible.onPressAction: clicked()
						onClicked: {
							player.mpris2Model.currentIndex = index;
						}
						PlasmaComponents3.ToolTip.text: text
						PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
						PlasmaComponents3.ToolTip.visible: hovered || (activeFocus && (focusReason === Qt.TabFocusReason || focusReason === Qt.BacktabFocusReason))
					}
				}
			}
		}
		
		Rectangle {
			id: thumbnailContainer
			visible: thumbnailVisible
			Layout.fillWidth: true
			Layout.margins: 10
			// Use the actual image aspect ratio, fallback to square if not loaded yet
			readonly property real imageRatio: albumArtNormal.implicitWidth > 0 && albumArtNormal.implicitHeight > 0
			? albumArtNormal.implicitWidth / albumArtNormal.implicitHeight
			: 1.0
			Layout.preferredHeight: thumbnailVisible ? width / imageRatio : 0
			color: 'transparent'
			PlasmaComponents3.ToolTip {
				id: raisePlayerTooltip
				anchors.centerIn: parent
				text: player.canRaise ? i18n("Bring player to the front") : i18n("This player can't be raised")
				visible: !plasmoid.configuration.hideCanBeRaisedTooltip && coverMouseArea.containsMouse
			}
			MouseArea {
				id: coverMouseArea
				anchors.fill: parent
				cursorShape: player.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
				onClicked: {
					if (player.canRaise) player.raise()
				}
				hoverEnabled: true
			}
			ImageWithPlaceholder {
				visible: !albumCoverBackground
				id: albumArtNormal
				anchors.fill: parent
				fillMode: Image.PreserveAspectFit
				placeholderSource: albumPlaceholder
				imageSource: player.artUrl
				layer.enabled: root.fullAlbumCoverRounded && root.albumCoverRadius > 0
				layer.effect: OpacityMask {
					maskSource: Item {
						width: albumArtNormal.width
						height: albumArtNormal.height
						Rectangle {
							anchors.fill: parent
							radius: albumCoverRadius
						}
					}
				}
			}
		}
		
		SongAndArtistText {
			visible: songTextVisible && songTextAboveProgressBar
			Layout.fillWidth: true
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			Layout.bottomMargin: 5
			textAlignment: songTextAlignment
			scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
			title: player.title
			artists: player.artists
			album: player.album
			textFont: baseFont
			titlePosition: plasmoid.configuration.fullTitlePosition
			artistsPosition: plasmoid.configuration.fullArtistsPosition
			albumPosition: plasmoid.configuration.fullAlbumPosition
			hideAlbumForSingles: plasmoid.configuration.fullHideAlbumForSingles
			scrollingEnabled: widget.expanded
		}
		
			RowLayout {
			Layout.leftMargin: 10
			Layout.rightMargin: 10
				spacing: 8

				TrackPositionSlider {
				visible: progressBarVisible
				Layout.fillWidth: true
				songPosition: player.songPosition
				songLength: player.songLength
				playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
				enableChangePosition: player.canSeek
				onRequireChangePosition: (position) => {
					player.setPosition(position)
				}
				onRequireUpdatePosition: () => {
					player.updatePosition()
				}
			}
				
			// SoundBars 放在进度条右边；进度条隐藏时居中显示
			SoundBars {
				playing: player.playbackStatus === Mpris.PlaybackStatus.Playing
				Layout.alignment: progressBarVisible ? Qt.AlignVCenter : Qt.AlignVCenter | Qt.AlignHCenter
			}
		}
		
		SongAndArtistText {
			visible: songTextVisible && !songTextAboveProgressBar
			Layout.fillWidth: true
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			Layout.topMargin: 5
			textAlignment: songTextAlignment
			scrollingSpeed: plasmoid.configuration.fullViewTextScrollingSpeed
			title: player.title
			artists: player.artists
			album: player.album
			textFont: baseFont
			titlePosition: plasmoid.configuration.fullTitlePosition
			artistsPosition: plasmoid.configuration.fullArtistsPosition
			albumPosition: plasmoid.configuration.fullAlbumPosition
			hideAlbumForSingles: plasmoid.configuration.fullHideAlbumForSingles
			scrollingEnabled: widget.expanded
		}
	}
}
