// Created by Marli Oshlack on 11/1/16.
// Copyright Marli Oshlack 2018.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

/**
 * A view that wraps every row in a stack view.
 */
open class StackScrollViewCell: UIView {
  
  public struct Options {
    
    public var insetsReference: InsetsReference
    public var overrideHeight: CGFloat?
    
    public init(insetsReference: InsetsReference = .layoutMargins, overrideHeight: CGFloat? = nil) {
      self.insetsReference = insetsReference
      self.overrideHeight = overrideHeight
    }
    
    public static var `default`: Self {
      return .init()
    }
  }
  
  public enum InsetsReference {
    
    case none
    case layoutMargins
  }
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  // MARK: Lifecycle
  
  public init(contentView: UIView, options: Options = .default) {
    self.contentView = contentView
    super.init(frame: .zero)
    
    translatesAutoresizingMaskIntoConstraints = false
    if #available(iOS 11.0, *) {
      insetsLayoutMarginsFromSafeArea = false
    }
    clipsToBounds = true
    
    contentView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentView)
    
    switch options.insetsReference {
    case .none:
      contentEdgeConstraints = [
        contentView.topAnchor.constraint(equalTo: topAnchor),
        contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
        bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      ]
    case .layoutMargins:
      contentEdgeConstraints = [
        contentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
        contentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
        layoutMarginsGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        layoutMarginsGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      ]
    }
    contentEdgeConstraints[2].priority = .required - 1
    NSLayoutConstraint.activate(contentEdgeConstraints)
    
    if let overrideHeight = options.overrideHeight {
      heightAnchor.constraint(equalToConstant: overrideHeight).isActive = true
    }
    
    if contentView is Tappable {
      tapGestureRecognizer = UITapGestureRecognizer()
      tapGestureRecognizer.addTarget(self, action: #selector(handleTap(_:)))
      tapGestureRecognizer.delegate = self
      addGestureRecognizer(tapGestureRecognizer)
    }
  }
  
  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: Open
  
  open var rowHighlightColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)
  
  open var rowBackgroundColor: UIColor = .clear {
    didSet {
      backgroundColor = rowBackgroundColor
    }
  }
  
  // MARK: Public
  
  public let contentView: UIView
  
  open var accessoryView: UIView? {
    didSet {
      guard accessoryView != oldValue else {
        return
      }
      oldValue?.removeFromSuperview()
      if let accessoryView = accessoryView {
        accessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessoryView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accessoryView)
        
        contentEdgeConstraints[3].isActive = false
        contentEdgeConstraints[3] = accessoryView.leftAnchor.constraint(equalTo: contentView.rightAnchor, constant: 8)
        
        NSLayoutConstraint.activate([
          contentEdgeConstraints[3],
          accessoryView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
          layoutMarginsGuide.rightAnchor.constraint(equalTo: accessoryView.rightAnchor),
        ])
      } else {
        contentEdgeConstraints[3].isActive = false
        contentEdgeConstraints[3] = layoutMarginsGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        contentEdgeConstraints[3].isActive = true
      }
    }
  }
  
  /// Edge constraints (top, left, bottom, right) of `contentView`
  open private(set) var contentEdgeConstraints: [NSLayoutConstraint]!
  
  // MARK: UIResponder
  
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard contentView.isUserInteractionEnabled else { return }
    
    if let contentView = contentView as? Highlightable, contentView.isHighlightable {
      contentView.setIsHighlighted(true)
    }
  }
  
  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesMoved(touches, with: event)
    guard contentView.isUserInteractionEnabled, let touch = touches.first else { return }
    
    let locationInSelf = touch.location(in: self)
    
    if let contentView = contentView as? Highlightable, contentView.isHighlightable {
      let isPointInsideCell = point(inside: locationInSelf, with: event)
      contentView.setIsHighlighted(isPointInsideCell)
    }
  }
  
  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    guard contentView.isUserInteractionEnabled else { return }
    
    if let contentView = contentView as? Highlightable, contentView.isHighlightable {
      contentView.setIsHighlighted(false)
    }
  }
  
  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    guard contentView.isUserInteractionEnabled else { return }
    
    if let contentView = contentView as? Highlightable, contentView.isHighlightable {
      contentView.setIsHighlighted(false)
    }
  }
  
  // MARK: Internal
  
  internal var tapHandler: ((UIView) -> Void)? {
    didSet {
      tapGestureRecognizer.isEnabled = tapHandler != nil
    }
  }
  
  // MARK: Private
  
  @objc private func handleTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
    guard contentView.isUserInteractionEnabled else { return }
    (contentView as? Tappable)?.didTapView()
    tapHandler?(contentView)
  }
}

extension StackScrollViewCell: UIGestureRecognizerDelegate {
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let view = gestureRecognizer.view else { return false }
    
    let location = touch.location(in: view)
    var hitView = view.hitTest(location, with: nil)
    
    // Traverse the chain of superviews looking for any UIControls.
    while hitView != view && hitView != nil {
      if hitView is UIControl {
        // Ensure UIControls get the touches instead of the tap gesture.
        return false
      }
      hitView = hitView?.superview
    }
    
    return true
  }
}
