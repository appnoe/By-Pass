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

// MARK: - RoundGlassButton

/// A 44×44 Liquid-Glass circle wrapping a single UIButton.
final class RoundGlassButton: UIView {

  let button: UIButton

  init(icon: String, pointSize: CGFloat = 18) {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: icon)?.withConfiguration(
      UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    )
    config.baseForegroundColor = UIColor.white.withAlphaComponent(0.55)
    button = UIButton(configuration: config)
    button.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    layer.cornerRadius = 22
    layer.cornerCurve = .continuous
    clipsToBounds = true

    let container = UIVisualEffectView(effect: UIGlassContainerEffect())
    container.translatesAutoresizingMaskIntoConstraints = false

    let glassEffect = UIGlassEffect()
    glassEffect.tintColor = UIColor.black.withAlphaComponent(0.55)
    glassEffect.isInteractive = true
    let glass = UIVisualEffectView(effect: glassEffect)
    glass.translatesAutoresizingMaskIntoConstraints = false
    glass.isUserInteractionEnabled = false

    container.contentView.addSubview(glass)
    container.contentView.addSubview(button)
    addSubview(container)

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: topAnchor),
      container.leadingAnchor.constraint(equalTo: leadingAnchor),
      container.bottomAnchor.constraint(equalTo: bottomAnchor),
      container.trailingAnchor.constraint(equalTo: trailingAnchor),

      glass.topAnchor.constraint(equalTo: container.contentView.topAnchor),
      glass.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),
      glass.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor),
      glass.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),

      button.topAnchor.constraint(equalTo: container.contentView.topAnchor),
      button.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor),
      button.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor),
      button.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }

  func setActive(_ active: Bool) {
    var config = button.configuration ?? .plain()
    config.baseForegroundColor = active ? .white : UIColor.white.withAlphaComponent(0.55)
    button.configuration = config
  }
}

// MARK: - SunPickerView

/// Compact 3-segment Liquid-Glass pill: selects 1, 2 or 3 gravity centres.
final class SunPickerView: UIView {

  let button1: UIButton
  let button2: UIButton
  let button3: UIButton

  var selectedIndex: Int = 0 {
    didSet { positionSelection(animated: true) }
  }

  private let containerView: UIVisualEffectView
  private let selectionView: UIVisualEffectView
  private let stackView: UIStackView
  private var selectionLeadingConstraint: NSLayoutConstraint?
  private var selectionWidthConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    button1 = SunPickerView.makeSegment("1")
    button2 = SunPickerView.makeSegment("2")
    button3 = SunPickerView.makeSegment("3")

    containerView = UIVisualEffectView(effect: UIGlassContainerEffect())
    containerView.translatesAutoresizingMaskIntoConstraints = false

    let pillEffect = UIGlassEffect()
    pillEffect.tintColor = UIColor.black.withAlphaComponent(0.55)
    let pillGlass = UIVisualEffectView(effect: pillEffect)
    pillGlass.translatesAutoresizingMaskIntoConstraints = false
    pillGlass.isUserInteractionEnabled = false

    let selEffect = UIGlassEffect()
    selEffect.tintColor = UIColor.white.withAlphaComponent(0.2)
    selectionView = UIVisualEffectView(effect: selEffect)
    selectionView.translatesAutoresizingMaskIntoConstraints = false
    selectionView.layer.cornerRadius = 18
    selectionView.layer.cornerCurve = .continuous
    selectionView.clipsToBounds = true

    stackView = UIStackView(arrangedSubviews: [button1, button2, button3])
    stackView.axis = .horizontal
    stackView.distribution = .fillEqually
    stackView.translatesAutoresizingMaskIntoConstraints = false

    super.init(frame: frame)

    translatesAutoresizingMaskIntoConstraints = false
    layer.cornerRadius = 22
    layer.cornerCurve = .continuous
    clipsToBounds = true

    containerView.contentView.addSubview(pillGlass)
    containerView.contentView.addSubview(selectionView)
    containerView.contentView.addSubview(stackView)
    addSubview(containerView)

    let leading = selectionView.leadingAnchor.constraint(
      equalTo: containerView.contentView.leadingAnchor, constant: 4)
    let width = selectionView.widthAnchor.constraint(equalToConstant: 44)
    selectionLeadingConstraint = leading
    selectionWidthConstraint   = width

    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

      pillGlass.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
      pillGlass.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
      pillGlass.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
      pillGlass.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),

      selectionView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 4),
      selectionView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor, constant: -4),
      leading, width,

      stackView.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
      stackView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor),
      stackView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),
    ])

    dim(button1, false)
    dim(button2, true)
    dim(button3, true)
  }

  required init?(coder: NSCoder) { fatalError() }

  override func layoutSubviews() {
    super.layoutSubviews()
    positionSelection(animated: false)
  }

  private static func makeSegment(_ title: String) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.title = title
    config.baseForegroundColor = .white
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var out = incoming
      out.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
      return out
    }
    let btn = UIButton(configuration: config)
    btn.translatesAutoresizingMaskIntoConstraints = false
    return btn
  }

  private func positionSelection(animated: Bool) {
    let buttons = [button1, button2, button3]
    for (i, btn) in buttons.enumerated() { dim(btn, i != selectedIndex) }
    guard stackView.frame.width > 0 else { return }
    let target   = buttons[selectedIndex]
    let newLeading = target.frame.origin.x + 4
    let newWidth   = target.frame.width - 8

    let update = {
      self.selectionLeadingConstraint?.constant = newLeading
      self.selectionWidthConstraint?.constant   = newWidth
      self.containerView.contentView.layoutIfNeeded()
    }
    if animated {
      UIView.animate(withDuration: 0.3, delay: 0,
                     usingSpringWithDamping: 0.75, initialSpringVelocity: 0,
                     animations: update)
    } else {
      update()
    }
  }

  private func dim(_ button: UIButton, _ dimmed: Bool) {
    var config = button.configuration ?? .plain()
    config.baseForegroundColor = dimmed
      ? UIColor.white.withAlphaComponent(0.35)
      : .white
    button.configuration = config
  }
}

// MARK: - GameView

class GameView: UIView {

  let skView: GravitySKView
  let satellitesCountLabel: UILabel

  // HUD controls
  let sunPickerView: SunPickerView    // top-left:  1 | 2 | 3 gravity centres
  let speedButton:   RoundGlassButton // bottom-right, inner
  let clearButton:   RoundGlassButton // bottom-right, outer
  let infoButton:    RoundGlassButton // bottom-left

  // Capture button: accessed as UIButton by GameViewController
  private let captureRoundButton: RoundGlassButton
  var captureButton: UIButton { captureRoundButton.button }

  override init(frame: CGRect) {

    skView = GravitySKView(frame: frame)
    skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    skView.isMultipleTouchEnabled = true

    satellitesCountLabel = UILabel()
    satellitesCountLabel.translatesAutoresizingMaskIntoConstraints = false
    satellitesCountLabel.text = "0"
    satellitesCountLabel.textColor = UIColor.white.withAlphaComponent(0.4)
    satellitesCountLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)

    sunPickerView       = SunPickerView()
    speedButton         = RoundGlassButton(icon: "forward")
    clearButton         = RoundGlassButton(icon: "trash")
    infoButton          = RoundGlassButton(icon: "info.circle")
    captureRoundButton  = RoundGlassButton(icon: "camera")

    super.init(frame: frame)

    skView.ignoresSiblingOrder = true
    skView.preferredFramesPerSecond = 120

    addSubview(skView)
    addSubview(sunPickerView)
    addSubview(captureRoundButton)
    addSubview(infoButton)
    addSubview(satellitesCountLabel)
    addSubview(speedButton)
    addSubview(clearButton)

    NSLayoutConstraint.activate([
      // ── Top-left: sun picker pill ──────────────────────────────
      sunPickerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
      sunPickerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
      sunPickerView.widthAnchor.constraint(equalToConstant: 120),
      sunPickerView.heightAnchor.constraint(equalToConstant: 44),

      // ── Top-right: capture button ──────────────────────────────
      captureRoundButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
      captureRoundButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
      captureRoundButton.widthAnchor.constraint(equalToConstant: 44),
      captureRoundButton.heightAnchor.constraint(equalToConstant: 44),

      // ── Bottom-left: info + count ──────────────────────────────
      infoButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
      infoButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
      infoButton.widthAnchor.constraint(equalToConstant: 44),
      infoButton.heightAnchor.constraint(equalToConstant: 44),

      satellitesCountLabel.leadingAnchor.constraint(equalTo: infoButton.trailingAnchor, constant: 10),
      satellitesCountLabel.centerYAnchor.constraint(equalTo: infoButton.centerYAnchor),

      // ── Bottom-right: clear then speed (right to left) ────────
      clearButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
      clearButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16),
      clearButton.widthAnchor.constraint(equalToConstant: 44),
      clearButton.heightAnchor.constraint(equalToConstant: 44),

      speedButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
      speedButton.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -10),
      speedButton.widthAnchor.constraint(equalToConstant: 44),
      speedButton.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  required init?(coder: NSCoder) { fatalError() }
}
