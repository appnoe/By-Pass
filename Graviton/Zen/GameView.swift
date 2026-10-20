//  Created by Dominik Hauser on 28.12.21.
//  Copyright © 2021 dasdom. All rights reserved.
//

import UIKit
import SpriteKit

// MARK: - GravitySKView

/// SKView subclass that opts out of UIKit focus navigation.
class GravitySKView: SKView {
  override func focusItems(in rect: CGRect) -> [any UIFocusItem] { [] }
}

// MARK: - DockButton

/// Icon-only 40×44 button for the control dock. Inactive icons are dimmed.
final class DockButton: UIButton {

  init(icon: String, accessibilityLabel label: String.LocalizationValue) {
    super.init(frame: .zero)
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
    )
    config.baseForegroundColor = DockButton.inactiveColor
    configuration = config
    accessibilityLabel = String(localized: label)
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: 40),
      heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  static let inactiveColor = UIColor.white.withAlphaComponent(0.6)

  func setIcon(_ icon: String) {
    var config = configuration ?? .plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
    )
    configuration = config
  }

  func setActive(_ active: Bool) {
    var config = configuration ?? .plain()
    config.baseForegroundColor = active ? .white : DockButton.inactiveColor
    configuration = config
    UIView.animate(withDuration: 0.2) {
      self.backgroundColor = active ? UIColor.white.withAlphaComponent(0.18) : .clear
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2
  }
}

// MARK: - SunPickerView

/// Segmented 1 | 2 | 3 selector for the number of gravity centres.
/// Has no background of its own; it lives inside a glass group of the dock.
final class SunPickerView: UIView {

  let button1: UIButton
  let button2: UIButton
  let button3: UIButton

  var selectedIndex: Int = 0 {
    didSet { positionSelection(animated: true) }
  }

  private let selectionView = UIView()
  private let stackView: UIStackView

  override init(frame: CGRect) {
    button1 = SunPickerView.makeSegment("1", accessibilityLabel: "1 sun")
    button2 = SunPickerView.makeSegment("2", accessibilityLabel: "2 suns")
    button3 = SunPickerView.makeSegment("3", accessibilityLabel: "3 suns")

    stackView = UIStackView(arrangedSubviews: [button1, button2, button3])
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false

    selectionView.backgroundColor = UIColor.white.withAlphaComponent(0.18)
    selectionView.isUserInteractionEnabled = false
    addSubview(selectionView)
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      button1.widthAnchor.constraint(equalToConstant: 36),
      button1.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    positionSelection(animated: false)
  }

  private static func makeSegment(_ title: String, accessibilityLabel label: String.LocalizationValue) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.title = title
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var out = incoming
      out.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
      return out
    }
    let btn = UIButton(configuration: config)
    btn.accessibilityLabel = String(localized: label)
    btn.translatesAutoresizingMaskIntoConstraints = false
    return btn
  }

  private func positionSelection(animated: Bool) {
    let buttons = [button1, button2, button3]
    for (i, btn) in buttons.enumerated() {
      var config = btn.configuration ?? .plain()
      config.baseForegroundColor = i == selectedIndex ? .white : DockButton.inactiveColor
      btn.configuration = config
      btn.accessibilityTraits = i == selectedIndex ? [.button, .selected] : .button
    }
    guard stackView.frame.width > 0 else { return }
    stackView.layoutIfNeeded()

    let frame = buttons[selectedIndex].frame
    let update = {
      self.selectionView.frame = frame
      self.selectionView.layer.cornerRadius = frame.height / 2
    }
    if animated {
      UIView.animate(withDuration: 0.35, delay: 0,
                     usingSpringWithDamping: 0.75, initialSpringVelocity: 0,
                     animations: update)
    } else {
      update()
    }
  }
}

// MARK: - ControlDock

/// Floating Liquid-Glass dock that bundles all HUD controls:
/// [ 1 | 2 | 3 ]  [ speed · capture · clear ]  [ sound · info ]
///
/// The groups are separate glass capsules inside one UIGlassContainerEffect,
/// so they are rendered together and visually melt into each other.
final class ControlDock: UIView {

  let sunPickerView = SunPickerView()
  let speedButton   = DockButton(icon: "forward.fill",   accessibilityLabel: "Fast forward")
  let captureButton = DockButton(icon: "camera.fill",    accessibilityLabel: "Capture")
  let clearButton   = DockButton(icon: "trash.fill",     accessibilityLabel: "Clear")
  let soundButton   = DockButton(icon: "speaker.wave.2.fill", accessibilityLabel: "Sound")
  let infoButton    = DockButton(icon: "info.circle",    accessibilityLabel: "Info")

  override init(frame: CGRect) {
    super.init(frame: frame)
    translatesAutoresizingMaskIntoConstraints = false

    let containerEffect = UIGlassContainerEffect()
    containerEffect.spacing = 12
    let container = UIVisualEffectView(effect: containerEffect)
    container.translatesAutoresizingMaskIntoConstraints = false
    addSubview(container)

    let groups = [
      ControlDock.glassGroup(containing: [sunPickerView]),
      ControlDock.glassGroup(containing: [speedButton, captureButton, clearButton]),
      ControlDock.glassGroup(containing: [soundButton, infoButton]),
    ]
    let row = UIStackView(arrangedSubviews: groups)
    row.axis = .horizontal
    row.spacing = 6
    row.translatesAutoresizingMaskIntoConstraints = false
    container.contentView.addSubview(row)

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: topAnchor),
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
      container.trailingAnchor.constraint(equalTo: trailingAnchor),

      row.topAnchor.constraint(equalTo: container.contentView.topAnchor),
      row.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),
      row.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor),
      row.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  /// One interactive glass capsule with the given controls laid out in a row.
  private static func glassGroup(containing views: [UIView]) -> UIVisualEffectView {
    let effect = UIGlassEffect()
    effect.tintColor = UIColor.white.withAlphaComponent(0.06)
    effect.isInteractive = true
    let glass = UIVisualEffectView(effect: effect)
    glass.translatesAutoresizingMaskIntoConstraints = false
    glass.cornerConfiguration = .capsule()

    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = .horizontal
    stack.spacing = 2
    stack.translatesAutoresizingMaskIntoConstraints = false
    glass.contentView.addSubview(stack)

    let inset: CGFloat = 3
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: glass.contentView.topAnchor, constant: inset),
      stack.leadingAnchor.constraint(equalTo: glass.contentView.leadingAnchor, constant: inset),
      stack.bottomAnchor.constraint(equalTo: glass.contentView.bottomAnchor, constant: -inset),
      stack.trailingAnchor.constraint(equalTo: glass.contentView.trailingAnchor, constant: -inset),
    ])
    return glass
  }
}

// MARK: - GameView

class GameView: UIView {

  let skView: GravitySKView
  let satellitesCountLabel: UILabel
  let controlDock = ControlDock()

  var sunPickerView: SunPickerView { controlDock.sunPickerView }
  var speedButton:   DockButton    { controlDock.speedButton }
  var captureButton: DockButton    { controlDock.captureButton }
  var clearButton:   DockButton    { controlDock.clearButton }
  var soundButton:   DockButton    { controlDock.soundButton }
  var infoButton:    DockButton    { controlDock.infoButton }

  override init(frame: CGRect) {

    skView = GravitySKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = UIColor.white.withAlphaComponent(0.4)
    satellitesCountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120

    addSubview(skView)
    addSubview(controlDock)
    addSubview(satellitesCountLabel)

    NSLayoutConstraint.activate([
      // ── Bottom-centre: control dock ───────────────────────────
      controlDock.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
      controlDock.centerXAnchor.constraint(equalTo: centerXAnchor),
      controlDock.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 12),

      // ── Planet count, just above the dock ─────────────────────
      satellitesCountLabel.bottomAnchor.constraint(equalTo: controlDock.topAnchor, constant: -8),
      satellitesCountLabel.centerXAnchor.constraint(equalTo: controlDock.centerXAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
