//  Created by Dominik Hauser on 26.12.21.
//  
//

import UIKit

class SettingsView: UIView {

  let starsKeyLabel: UILabel
  let starsSwitch: UISwitch

  let zoomKeyLabel: UILabel
  let zoomSwitch: UISwitch

//  let gravityFieldKeyLabel: UILabel
//  let gravityFieldSwitch: UISwitch

  let gravityControl: UISegmentedControl

  let blackHolesControl: UISegmentedControl

//  let trailKeyLabel: UILabel
//  let trailLengthControl: UISegmentedControl
//
//  let trailThicknessControl: UISegmentedControl

  let colorControl: UISegmentedControl

//  let spawnControl: UISegmentedControl
  let backgroundColorKeyLabel: UILabel
  let backgroundColorControl: UISegmentedControl
  let backgroundColorDescriptionLabel: UILabel

  let loadButton: UIButton
  let saveButton: UIButton

  let shareImageButton: UIButton

  let clockWiseButton: UIButton
  let randomButton: UIButton
  let counterClockWiseButton: UIButton

  let clearButton: UIButton

  let showHideButton: UIButton

  override init(frame: CGRect) {

    starsKeyLabel = UILabel()
    starsKeyLabel.text = "Stars"
    starsKeyLabel.textColor = .label
    starsKeyLabel.font = .systemFont(ofSize: 13)

    starsSwitch = UISwitch()
    starsSwitch.isOn = true

    zoomKeyLabel = UILabel()
    zoomKeyLabel.text = "Zoom buttons"
    zoomKeyLabel.textColor = .label
    zoomKeyLabel.font = .systemFont(ofSize: 13)

    zoomSwitch = UISwitch()
    zoomSwitch.isOn = false
    zoomSwitch.accessibilityLabel = "Show zoom buttons"

//    gravityFieldKeyLabel = UILabel()
//    gravityFieldKeyLabel.text = "Gravity field"
//    gravityFieldKeyLabel.textColor = .label
//    gravityFieldKeyLabel.font = .systemFont(ofSize: 13)
//
//    gravityFieldSwitch = UISwitch()
//    gravityFieldSwitch.isOn = true
//    gravityFieldSwitch.accessibilityLabel = "Activate gravity field"

    gravityControl = UISegmentedControl(items: ["Gravity", "Spirograph"])
    gravityControl.selectedSegmentIndex = 0

    let blackHolesLabel = UILabel()
    blackHolesLabel.text = "Number Of Black Holes"
    blackHolesLabel.textColor = .label
    blackHolesLabel.font = .systemFont(ofSize: 13)

    blackHolesControl = UISegmentedControl(items: ["1", "2", "3"])
    blackHolesControl.selectedSegmentIndex = 0

//    trailKeyLabel = UILabel()
//    trailKeyLabel.text = "Trail"
//    trailKeyLabel.textColor = .label
//    trailKeyLabel.font = .systemFont(ofSize: 13)
//
//    trailLengthControl = UISegmentedControl(items: ["none", "short", "long"])
//    trailLengthControl.selectedSegmentIndex = 2
//
//    trailThicknessControl = UISegmentedControl(items: ["thin", "normal", "thick"])
//    trailThicknessControl.selectedSegmentIndex = 1

    colorControl = UISegmentedControl(items: [UIImage(systemName: "paintpalette")!.withRenderingMode(.alwaysOriginal), UIImage(systemName: "paintpalette")!])
    colorControl.selectedSegmentIndex = 0

    backgroundColorKeyLabel = UILabel()
    backgroundColorKeyLabel.text = "Background"
    backgroundColorKeyLabel.textColor = .label
    backgroundColorKeyLabel.font = .systemFont(ofSize: 13)

    backgroundColorControl = UISegmentedControl(items: ["black", "gray", "white"])
    backgroundColorControl.selectedSegmentIndex = 0
    backgroundColorControl.isEnabled = true

    backgroundColorDescriptionLabel = UILabel()
    backgroundColorDescriptionLabel.text = ""
    backgroundColorDescriptionLabel.textColor = .secondaryLabel
    backgroundColorDescriptionLabel.font = .systemFont(ofSize: 11)
    backgroundColorDescriptionLabel.textAlignment = .center

//    spawnControl = UISegmentedControl(items: ["manual", "automatic"])
//    spawnControl.selectedSegmentIndex = 0

    loadButton = UIButton(configuration: .glass())
    loadButton.setTitle("Load", for: .normal)

    saveButton = UIButton(configuration: .glass())
    saveButton.setTitle("Save", for: .normal)

    var buttonConfig = UIButton.Configuration.glass()
    buttonConfig.image = UIImage(systemName: "arrow.clockwise")
    clockWiseButton = UIButton(configuration: buttonConfig)

    buttonConfig.image = UIImage(systemName: "dice")
    randomButton = UIButton(configuration: buttonConfig)

    buttonConfig.image = UIImage(systemName: "arrow.counterclockwise")
    counterClockWiseButton = UIButton(configuration: buttonConfig)

    clearButton = UIButton(type: .system)
    clearButton.configuration = UIButton.Configuration.glass()
    clearButton.setImage(UIImage(systemName: "trash"), for: .normal)

    shareImageButton = UIButton(type: .system)
    shareImageButton.configuration = UIButton.Configuration.glass()
    shareImageButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)

    showHideButton = UIButton(type: .system)
    showHideButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)

    super.init(frame: frame)

    backgroundColor = .clear

    // Add Liquid Glass background for the settings panel
    let glassEffect = UIGlassEffect()
    let glassView = UIVisualEffectView(effect: glassEffect)
    glassView.translatesAutoresizingMaskIntoConstraints = false
    glassView.layer.cornerRadius = 16
    glassView.clipsToBounds = true

    let zoomStackView = UIStackView(arrangedSubviews: [zoomKeyLabel, zoomSwitch])
    zoomStackView.spacing = 20

    let starsStackView = UIStackView(arrangedSubviews: [starsKeyLabel, starsSwitch])
    starsStackView.spacing = 20

//    let gravityFieldStackView = UIStackView(arrangedSubviews: [gravityFieldKeyLabel, gravityFieldSwitch])
//    gravityFieldStackView.spacing = 20

//    let trailsStackView = UIStackView(arrangedSubviews: [trailKeyLabel, trailLengthControl, trailThicknessControl])
//    trailsStackView.axis = .vertical
//    trailsStackView.spacing = 5

    let blackHolesStackView = UIStackView(arrangedSubviews: [blackHolesLabel, blackHolesControl])
    blackHolesStackView.axis = .vertical
    blackHolesStackView.spacing = 5

    let backgroundColorStackView = UIStackView(arrangedSubviews: [backgroundColorKeyLabel, backgroundColorControl, backgroundColorDescriptionLabel])
    backgroundColorStackView.axis = .vertical
    backgroundColorStackView.spacing = 5

    let loadSaveStackView = UIStackView(arrangedSubviews: [loadButton, saveButton])
    loadSaveStackView.spacing = 5
    loadSaveStackView.distribution = .fillEqually

    let randomButtonStackView = UIStackView(arrangedSubviews: [clockWiseButton, randomButton, counterClockWiseButton])
    randomButtonStackView.spacing = 5
    randomButtonStackView.distribution = .fillEqually

    let buttonStackView = UIStackView(arrangedSubviews: [clearButton, shareImageButton])
    buttonStackView.spacing = 5
    buttonStackView.distribution = .fillEqually

    let settingsStackView = UIStackView(arrangedSubviews: [zoomStackView, starsStackView, 
//                                                           gravityFieldStackView,
                                                           gravityControl,
                                                           blackHolesStackView,
//                                                           trailsStackView,
                                                           colorControl, backgroundColorStackView, loadSaveStackView, randomButtonStackView, buttonStackView])
    settingsStackView.axis = .vertical
    settingsStackView.spacing = 20

    let showHideStackView = UIStackView(arrangedSubviews: [showHideButton])
    showHideStackView.alignment = .top

    let stackView = UIStackView(arrangedSubviews: [settingsStackView, showHideStackView])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.spacing = 22

    // Insert glass background behind the settings content (not behind showHideButton)
    addSubview(glassView)
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),

      showHideButton.widthAnchor.constraint(equalToConstant: 44),
      showHideButton.heightAnchor.constraint(equalToConstant: 44),

      // Glass background covers the settings content area (excluding the show/hide button)
      glassView.topAnchor.constraint(equalTo: topAnchor),
      glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
      glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
      glassView.trailingAnchor.constraint(equalTo: showHideButton.leadingAnchor, constant: -4),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
