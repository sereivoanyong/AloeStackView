// Created by Marli Oshlack on 11/10/16.
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
 * A simple class for laying out a collection of views with a convenient API, while leveraging the
 * power of Auto Layout.
 */
open class StackScrollView: UIScrollView {
  
  // MARK: Lifecycle
  
  public override init(frame: CGRect = .zero) {
    super.init(frame: frame)
    
    if #available(iOS 13.0, *) {
      backgroundColor = .systemBackground
    } else {
      backgroundColor = .white
    }
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    addSubview(stackView)
    
    NSLayoutConstraint.activate(stackEdgeConstraints)
    updateStackViewAxisConstraint()
  }
  
  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Public
  
  // MARK: Configuring AloeStackView
  
  /// `arrangedSubviews` must not be modified directly.
  public let stackView = UIStackView()
  
  /// Edge constraints (top, left, bottom, right) of `stackView`
  lazy open private(set) var stackEdgeConstraints: [NSLayoutConstraint] = [
    stackView.topAnchor.constraint(equalTo: topAnchor),
    stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
    bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
    trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
  ]
  
  /// The direction that rows are laid out in the stack view.
  ///
  /// If `axis` is `.vertical`, rows will be laid out in a vertical column. If `axis` is
  /// `.horizontal`, rows will be laid out horizontally, side-by-side.
  ///
  /// This property also controls the direction of scrolling in the stack view. If `axis` is
  /// `.vertical`, the stack view will scroll vertically, and rows will stretch to fill the width of
  /// the stack view. If `axis` is `.horizontal`, the stack view will scroll horizontally, and rows
  /// will be sized to fill the height of the stack view.
  ///
  /// The default value is `.vertical`.
  open var axis: NSLayoutConstraint.Axis {
    get { return stackView.axis }
    set {
      stackView.axis = newValue
      updateStackViewAxisConstraint()
    }
  }
  
  open var insetsCellToLayoutMargins: Bool = false
  
  // MARK: Adding and Removing Rows
  
  /// Adds a row to the end of the stack view.
  ///
  /// If `animated` is `true`, the insertion is animated.
  open func addRow(_ row: UIView, configurationHandler: ((StackScrollViewCell) -> Void)? = nil, animated: Bool = false) {
    insertCell(contentView: row, configurationHandler: configurationHandler, atIndex: stackView.arrangedSubviews.count, animated: animated)
  }
  
  /// Adds multiple rows to the end of the stack view.
  ///
  /// If `animated` is `true`, the insertions are animated.
  open func addRows(_ rows: [UIView], configurationHandler: ((StackScrollViewCell) -> Void)? = nil, animated: Bool = false) {
    rows.forEach { addRow($0, configurationHandler: configurationHandler, animated: animated) }
  }
  
  /// Adds a row to the beginning of the stack view.
  ///
  /// If `animated` is `true`, the insertion is animated.
  open func prependRow(_ row: UIView, animated: Bool = false) {
    insertCell(contentView: row, atIndex: 0, animated: animated)
  }
  
  /// Adds multiple rows to the beginning of the stack view.
  ///
  /// If `animated` is `true`, the insertions are animated.
  open func prependRows(_ rows: [UIView], animated: Bool = false) {
    rows.reversed().forEach { prependRow($0, animated: animated) }
  }
  
  /// Inserts a row above the specified row in the stack view.
  ///
  /// If `animated` is `true`, the insertion is animated.
  open func insertRow(_ row: UIView, before beforeRow: UIView, animated: Bool = false) {
    guard
      let cell = beforeRow.superview as? StackScrollViewCell,
      let index = stackView.arrangedSubviews.firstIndex(of: cell) else { return }
    
    insertCell(contentView: row, atIndex: index, animated: animated)
  }
  
  /// Inserts multiple rows above the specified row in the stack view.
  ///
  /// If `animated` is `true`, the insertions are animated.
  open func insertRows(_ rows: [UIView], before beforeRow: UIView, animated: Bool = false) {
    rows.forEach { insertRow($0, before: beforeRow, animated: animated) }
  }
  
  /// Inserts a row below the specified row in the stack view.
  ///
  /// If `animated` is `true`, the insertion is animated.
  open func insertRow(_ row: UIView, after afterRow: UIView, animated: Bool = false) {
    guard
      let cell = afterRow.superview as? StackScrollViewCell,
      let index = stackView.arrangedSubviews.firstIndex(of: cell) else { return }
    insertCell(contentView: row, atIndex: index + 1, animated: animated)
  }
  
  /// Inserts multiple rows below the specified row in the stack view.
  ///
  /// If `animated` is `true`, the insertions are animated.
  open func insertRows(_ rows: [UIView], after afterRow: UIView, animated: Bool = false) {
    _ = rows.reduce(afterRow) { currentAfterRow, row in
      insertRow(row, after: currentAfterRow, animated: animated)
      return row
    }
  }
  
  /// Removes the given row from the stack view.
  ///
  /// If `animated` is `true`, the removal is animated.
  open func removeRow(_ row: UIView, animated: Bool = false) {
    if let cell = row.superview as? StackScrollViewCell {
      removeCell(cell, animated: animated)
    }
  }
  
  /// Removes the given rows from the stack view.
  ///
  /// If `animated` is `true`, the removals are animated.
  open func removeRows(_ rows: [UIView], animated: Bool = false) {
    rows.forEach { removeRow($0, animated: animated) }
  }
  
  /// Removes all the rows in the stack view.
  ///
  /// If `animated` is `true`, the removals are animated.
  open func removeAllRows(animated: Bool = false) {
    stackView.arrangedSubviews.forEach { view in
      if let cell = view as? StackScrollViewCell {
        removeRow(cell.contentView, animated: animated)
      }
    }
  }
  
  // MARK: Accessing Rows
  
  /// The first row in the stack view.
  ///
  /// This property is nil if there are no rows in the stack view.
  open var firstRow: UIView? {
    return (stackView.arrangedSubviews.first as? StackScrollViewCell)?.contentView
  }
  
  /// The last row in the stack view.
  ///
  /// This property is nil if there are no rows in the stack view.
  open var lastRow: UIView? {
    return (stackView.arrangedSubviews.last as? StackScrollViewCell)?.contentView
  }
  
  /// Returns an array containing of all the rows in the stack view.
  ///
  /// The rows in the returned array are in the order they appear visually in the stack view.
  open func rows() -> [UIView] {
    return (stackView.arrangedSubviews as! [StackScrollViewCell]).map { $0.contentView }
  }
  
  /// Returns `true` if the given row is present in the stack view, `false` otherwise.
  open func containsRow(_ row: UIView) -> Bool {
    guard let cell = row.superview as? StackScrollViewCell else { return false }
    return stackView.arrangedSubviews.contains(cell)
  }
  
  // MARK: Hiding and Showing Rows
  
  /// Hides the given row, making it invisible.
  ///
  /// If `animated` is `true`, the change is animated.
  open func hideRow(_ row: UIView, animated: Bool = false) {
    setRowHidden(row, isHidden: true, animated: animated)
  }
  
  /// Hides the given rows, making them invisible.
  ///
  /// If `animated` is `true`, the changes are animated.
  open func hideRows(_ rows: [UIView], animated: Bool = false) {
    rows.forEach { hideRow($0, animated: animated) }
  }
  
  /// Shows the given row, making it visible.
  ///
  /// If `animated` is `true`, the change is animated.
  open func showRow(_ row: UIView, animated: Bool = false) {
    setRowHidden(row, isHidden: false, animated: animated)
  }
  
  /// Shows the given rows, making them visible.
  ///
  /// If `animated` is `true`, the changes are animated.
  open func showRows(_ rows: [UIView], animated: Bool = false) {
    rows.forEach { showRow($0, animated: animated) }
  }
  
  /// Hides the given row if `isHidden` is `true`, or shows the given row if `isHidden` is `false`.
  ///
  /// If `animated` is `true`, the change is animated.
  open func setRowHidden(_ row: UIView, isHidden: Bool, animated: Bool = false) {
    guard let cell = row.superview as? StackScrollViewCell, cell.isHidden != isHidden else { return }
    
    if animated {
      UIView.animate(withDuration: 0.3) {
        cell.isHidden = isHidden
        cell.layoutIfNeeded()
      }
    } else {
      cell.isHidden = isHidden
    }
  }
  
  /// Hides the given rows if `isHidden` is `true`, or shows the given rows if `isHidden` is
  /// `false`.
  ///
  /// If `animated` is `true`, the change are animated.
  open func setRowsHidden(_ rows: [UIView], isHidden: Bool, animated: Bool = false) {
    rows.forEach { setRowHidden($0, isHidden: isHidden, animated: animated) }
  }
  
  /// Returns `true` if the given row is hidden, `false` otherwise.
  open func isRowHidden(_ row: UIView) -> Bool {
    return (row.superview as? StackScrollViewCell)?.isHidden ?? false
  }
  
  // MARK: Handling User Interaction
  
  /// Sets a closure that will be called when the given row in the stack view is tapped by the user.
  ///
  /// The handler will be passed the row.
  open func setTapHandler<RowView: UIView>(forRow row: RowView, handler: ((RowView) -> Void)?) {
    guard let cell = row.superview as? StackScrollViewCell else { return }
    
    if let handler = handler {
      cell.tapHandler = { contentView in
        guard let contentView = contentView as? RowView else { return }
        handler(contentView)
      }
    } else {
      cell.tapHandler = nil
    }
  }
  
  // MARK: Styling Rows
  
  /// The background color of rows in the stack view.
  ///
  /// This background color will be used for any new row that is added to the stack view.
  /// The default color is clear.
  open var rowBackgroundColor = UIColor.clear
  
  /// The highlight background color of rows in the stack view.
  ///
  /// This highlight background color will be used for any new row that is added to the stack view.
  /// The default color is #D9D9D9 (RGB 217, 217, 217).
  open var rowHighlightColor = StackScrollView.defaultRowHighlightColor
  
  /// Sets the background color for the given row to the `UIColor` provided.
  open func setBackgroundColor(forRow row: UIView, color: UIColor) {
    (row.superview as? StackScrollViewCell)?.rowBackgroundColor = color
  }
  
  /// Sets the background color for the given rows to the `UIColor` provided.
  open func setBackgroundColor(forRows rows: [UIView], color: UIColor) {
    rows.forEach { setBackgroundColor(forRow: $0, color: color) }
  }
  
  /// Specifies the default inset of rows.
  ///
  /// This inset will be used for any new row that is added to the stack view.
  ///
  /// You can use this property to add space between a row and the left and right edges of the stack
  /// view and the rows above and below it. Positive inset values move the row inward and away
  /// from the stack view edges and away from rows above and below.
  ///
  /// The default inset is 15pt on each side and 12pt on the top and bottom.
  open var rowInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
  
  /// Sets the inset for the given row to the `UIEdgeInsets` provided.
  open func setInset(forRow row: UIView, inset: UIEdgeInsets) {
    (row.superview as? StackScrollViewCell)?.layoutMargins = inset
  }
  
  /// Sets the inset for the given rows to the `UIEdgeInsets` provided.
  open func setInset(forRows rows: [UIView], inset: UIEdgeInsets) {
    rows.forEach { setInset(forRow: $0, inset: inset) }
  }
  
  // MARK: Modifying the Scroll Position
  
  /// Scrolls the given row onto screen so that it is fully visible.
  ///
  /// If `animated` is `true`, the scroll is animated. If the row is already fully visible, this
  /// method does nothing.
  open func scrollRowToVisible(_ row: UIView, animated: Bool = true) {
    guard let superview = row.superview else { return }
    scrollRectToVisible(convert(row.frame, from: superview), animated: animated)
  }
  
  // MARK: Extending AloeStackView
  
  /// Returns the `StackViewCell` to be used for the given row.
  ///
  /// An instance of `StackViewCell` wraps every row in the stack view.
  ///
  /// Subclasses can override this method to return a custom `StackViewCell` subclass, for example
  /// to add custom behavior or functionality that is not provided by default.
  ///
  /// If you customize the values of some properties of `StackViewCell` in this method, these values
  /// may be overwritten by default values after the cell is returned. To customize the values of
  /// properties of the cell, override `configureCell(_:)` and perform the customization there,
  /// rather than on the cell returned from this method.
  open func cellForRow(_ row: UIView) -> StackScrollViewCell {
    return StackScrollViewCell(contentView: row)
  }
  
  /// Allows subclasses to configure the properties of the given `StackViewCell`.
  ///
  /// This method is called for newly created cells after the default values of any properties of
  /// the cell have been set by the superclass.
  ///
  /// The default implementation of this method does nothing.
  open func configureCell(_ cell: StackScrollViewCell) { }
  
  // MARK: - Private
  
  private var stackViewAxisConstraint: NSLayoutConstraint?
  
  private func updateStackViewAxisConstraint() {
    stackViewAxisConstraint?.isActive = false
    if stackView.axis == .vertical {
      stackViewAxisConstraint = stackView.widthAnchor.constraint(equalTo: widthAnchor)
    } else {
      stackViewAxisConstraint = stackView.heightAnchor.constraint(equalTo: heightAnchor)
    }
    stackViewAxisConstraint?.isActive = true
  }
  
  private func createCell(contentView: UIView) -> StackScrollViewCell {
    let cell = cellForRow(contentView)
    
    cell.preservesSuperviewLayoutMargins = insetsCellToLayoutMargins
    cell.rowBackgroundColor = rowBackgroundColor
    cell.rowHighlightColor = rowHighlightColor
    cell.layoutMargins = rowInset
    
    configureCell(cell)
    
    return cell
  }
  
  private func insertCell(contentView: UIView, configurationHandler: ((StackScrollViewCell) -> Void)? = nil, atIndex index: Int, animated: Bool) {
    let cellToRemove = containsRow(contentView) ? contentView.superview : nil
    
    let cell = createCell(contentView: contentView)
    configurationHandler?(cell)
    stackView.insertArrangedSubview(cell, at: index)
    
    if let cellToRemove = cellToRemove as? StackScrollViewCell {
      removeCell(cellToRemove, animated: false)
    }
    
    if animated {
      cell.alpha = 0
      layoutIfNeeded()
      UIView.animate(withDuration: 0.3) {
        cell.alpha = 1
      }
    }
  }
  
  private func removeCell(_ cell: StackScrollViewCell, animated: Bool) {
    let completion: (Bool) -> Void = { _ in
      cell.removeFromSuperview()
    }
    
    if animated {
      UIView.animate(
        withDuration: 0.3,
        animations: {
          cell.isHidden = true
        },
        completion: completion)
    } else {
      completion(true)
    }
  }
  
  private static let defaultRowHighlightColor: UIColor = UIColor(red: 217 / 255, green: 217 / 255, blue: 217 / 255, alpha: 1)
}
