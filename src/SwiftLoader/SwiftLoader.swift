//
//  BSLoader.swift
//  Brainstorage
//
//  Created by Kirill Kunst on 07.02.15.
//  Copyright (c) 2015 Kirill Kunst. All rights reserved.
//

import UIKit
import QuartzCore
import CoreGraphics

open class SwiftLoader: UIView {
  
  fileprivate var coverView : UIView?
  fileprivate var titleLabel : UILabel?
  fileprivate var subtitleLabel: UILabel?
  fileprivate var loadingView : SwiftLoadingView?
  fileprivate var animated : Bool? = false
  fileprivate var canUpdated = false
  fileprivate var title: String?
  fileprivate var subtitle: String?
  fileprivate var dismissable: Bool? = false
  fileprivate var dismissCompletionBlock: (() -> Void)? = nil
  fileprivate var tapGesture: UITapGestureRecognizer?
  fileprivate var allowDismissAfter: UInt64 = 0
  
  fileprivate var config : Config = Config() {
    didSet {
      self.loadingView?.config = config
    }
  }
  
  override open var frame : CGRect {
    didSet {
      self.update()
    }
  }
  
  class var sharedInstance: SwiftLoader {
    struct Singleton {
      static let instance = SwiftLoader(frame: CGRect(x: 0,y: 0,width: Config().size,height: Config().size))
    }
    return Singleton.instance
  }
  
  open class func show(animated: Bool) {
    self.show(title: nil, subtitle: nil, animated: false, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  open class func show(title: String?, animated : Bool) {
    self.show(title: title, subtitle: nil, animated: animated, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  open class func show(title: String?, subtitle: String?, animated: Bool) {
    self.show(title: title, subtitle: subtitle, animated: animated, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  open class func show(title: String?, subtitle: String?, animated: Bool, dismissable: Bool, allowDismissAfter: UInt64) {
    self.show(title: title, subtitle: subtitle, animated: animated, dismissable: dismissable, allowDismissAfter: allowDismissAfter, completionBlock: nil)
  }
  
  open class func show(title: String?, subtitle: String?, animated: Bool, dismissable: Bool, allowDismissAfter: UInt64, completionBlock: (() -> Void)?) {
    let currentWindow : UIWindow = UIApplication.shared.keyWindow!
    
    let loader = SwiftLoader.sharedInstance
    
    if loader.superview != nil {
      loader.coverView?.removeFromSuperview()
      loader.removeFromSuperview()
    }
    
    loader.canUpdated = true
    loader.animated = animated
    loader.title = title
    loader.subtitle = subtitle
    loader.update()
    
    loader.dismissable = dismissable
    loader.allowDismissAfter = allowDismissAfter
    loader.dismissCompletionBlock = completionBlock
    
    let height : CGFloat = UIScreen.main.bounds.size.height
    let width : CGFloat = UIScreen.main.bounds.size.width
    let center : CGPoint = CGPoint(x: width / 2.0, y: height / 2.0)
    loader.center = center
    
    loader.coverView = UIView(frame: currentWindow.bounds)
    loader.coverView?.backgroundColor = loader.config.coverBackgroundColor
    
    if dismissable {
      
      if loader.tapGesture == nil {
        loader.tapGesture = UITapGestureRecognizer(target: loader, action: #selector(SwiftLoader.tapGestureHandle(_:)))
        loader.tapGesture?.numberOfTapsRequired = 1
        loader.tapGesture?.numberOfTouchesRequired = 1
        loader.tapGesture?.cancelsTouchesInView = false
        loader.tapGesture?.isEnabled = false
        loader.coverView?.addGestureRecognizer(loader.tapGesture!)
      }
      
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(loader.allowDismissAfter * NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: { () -> Void in
        loader.tapGesture?.isEnabled = true
        if let subtitleDismissingText = loader.config.subtitleDismissingText {
          loader.subtitleLabel?.text = subtitleDismissingText
        }
      })
    }
    
    currentWindow.addSubview(loader.coverView!)
    currentWindow.addSubview(loader)
    loader.start()
  }
  
  open class func hide() {
    let loader = SwiftLoader.sharedInstance
    loader.tapGesture = nil
    loader.stop()
  }
  
  open class func refreshIfNeeded() {
    let loader = SwiftLoader.sharedInstance
    if let spinning = loader.loadingView?.isSpinning , spinning {
      loader.start()
    }
  }
  
  open class func setConfig(_ config : Config) {
    let loader = SwiftLoader.sharedInstance
    loader.config = config
    loader.frame = CGRect(x: 0,y: 0,width: loader.config.size,height: loader.config.size)
  }
  
  /**
  Private methods
  */
  
  fileprivate func setup() {
    self.alpha = 0
    self.update()
  }
  
  fileprivate func start() {
    self.loadingView?.start()
    
    if (self.animated!) {
      UIView.animate(withDuration: 0.3, animations: { () -> Void in
        self.alpha = 1
        }, completion: { (finished) -> Void in
          
      });
    } else {
      self.alpha = 1
    }
  }
  
  fileprivate func stop() {
    if (self.animated!) {
      UIView.animate(withDuration: 0.3, animations: { () -> Void in
        self.alpha = 0
        }, completion: { (finished) -> Void in
          self.removeFromSuperview()
          self.coverView?.removeFromSuperview()
          self.loadingView?.stop()
      });
    } else {
      self.alpha = 0
      self.removeFromSuperview()
      self.coverView?.removeFromSuperview()
      self.loadingView?.stop()
    }
  }
  
  fileprivate func update() {
    self.backgroundColor = self.config.backgroundColor
    self.layer.cornerRadius = self.config.cornerRadius
    
    if (self.loadingView == nil) {
      self.loadingView = SwiftLoadingView(frame: self.frameForSpinner())
      self.loadingView?.clipsToBounds = true
      self.addSubview(self.loadingView!)
    } else {
      self.loadingView?.frame = self.frameForSpinner()

    }
    
    var yOffset: CGFloat = self.loadingView!.frame.origin.y + self.loadingView!.frame.height    
    var height: CGFloat = 42.0
    
    if self.title != nil && self.subtitle != nil {
      height = 21.0
    }
    
    if (self.titleLabel == nil) {
      self.titleLabel = UILabel(frame: CGRect(x: config.loaderTitleMargin, y: yOffset, width: self.frame.width - config.loaderTitleMargin*2, height: height))
      self.addSubview(self.titleLabel!)
      self.titleLabel?.numberOfLines = 1
      self.titleLabel?.textAlignment = NSTextAlignment.center
      self.titleLabel?.adjustsFontSizeToFitWidth = true
      self.titleLabel?.minimumScaleFactor = 12.0 / UIFont.labelFontSize
    } else {
      self.titleLabel?.frame = CGRect(x: config.loaderTitleMargin, y: yOffset, width: self.frame.width - config.loaderTitleMargin*2, height: height)
    }
    
    self.titleLabel?.font = self.config.titleTextFont
    self.titleLabel?.textColor = self.config.titleTextColor
    self.titleLabel?.text = self.title
    
    self.titleLabel?.isHidden = self.title == nil
    
    /*
    * Subtitle
    */
    yOffset = self.titleLabel!.isHidden ? yOffset : self.titleLabel!.frame.height + self.titleLabel!.frame.origin.y
    
    if (self.subtitleLabel == nil) {
      self.subtitleLabel = UILabel(frame: CGRect(x: config.loaderTitleMargin, y: yOffset, width: self.frame.width - config.loaderTitleMargin*2, height: height))
      self.addSubview(self.subtitleLabel!)
      self.subtitleLabel?.numberOfLines = 1
      self.subtitleLabel?.textAlignment = NSTextAlignment.center
      self.subtitleLabel?.adjustsFontSizeToFitWidth = true
      self.subtitleLabel?.minimumScaleFactor = 12.0 / UIFont.labelFontSize
    } else {
      self.subtitleLabel?.frame = CGRect(x: config.loaderTitleMargin, y: yOffset, width: self.frame.width - config.loaderTitleMargin*2, height: height)
    }
    
    self.subtitleLabel?.font = self.config.subtitleTextFont
    self.subtitleLabel?.textColor = self.config.subtitleTextColor
    self.subtitleLabel?.text = self.subtitle
    
    self.subtitleLabel?.isHidden = self.subtitle == nil
  }
  
  func frameForSpinner() -> CGRect {
    let loadingViewSize = self.frame.size.width - (config.loaderSpinnerMarginSide * 2)
    
    if (self.title == nil && self.subtitle == nil) {
      let yOffset = (self.frame.size.height - loadingViewSize) / 2
      return CGRect(x: config.loaderSpinnerMarginSide, y: yOffset, width: loadingViewSize, height: loadingViewSize)
    }
    return CGRect(x: config.loaderSpinnerMarginSide, y: config.loaderSpinnerMarginTop, width: loadingViewSize, height: loadingViewSize)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func tapGestureHandle(_ sender: UITapGestureRecognizer) {
    SwiftLoader.hide()
    self.dismissCompletionBlock?()
  }
  
  /**
  *  Loader View
  */
  class SwiftLoadingView : UIView {
    
    fileprivate var lineWidth : Float?
    fileprivate var lineTintColor : UIColor?
    fileprivate var backgroundLayer : CAShapeLayer?
    fileprivate var isSpinning : Bool?
    
    fileprivate var config : Config = Config() {
      didSet {
        self.update()
      }
    }
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
    
    /**
    Setup loading view
    */
    
    fileprivate func setup() {
      self.backgroundColor = UIColor.clear
      self.lineWidth = fmaxf(Float(self.frame.size.width) * 0.025, 1)
      
      self.backgroundLayer = CAShapeLayer()
      self.backgroundLayer?.strokeColor = self.config.spinnerColor.cgColor
      self.backgroundLayer?.fillColor = self.backgroundColor?.cgColor
      self.backgroundLayer?.lineCap = kCALineCapRound
      self.backgroundLayer?.lineWidth = CGFloat(self.lineWidth!)
      self.layer.addSublayer(self.backgroundLayer!)
    }
    
    fileprivate func update() {
      self.lineWidth = self.config.spinnerLineWidth
      
      self.backgroundLayer?.lineWidth = CGFloat(self.lineWidth!)
      self.backgroundLayer?.strokeColor = self.config.spinnerColor.cgColor
    }
    
    /**
    Draw Circle
    */    
    override func draw(_ rect: CGRect) {
      self.backgroundLayer?.frame = self.bounds
    }
    
    fileprivate func drawBackgroundCircle(_ partial : Bool) {
      let startAngle : CGFloat = CGFloat(M_PI) / CGFloat(2.0)
      var endAngle : CGFloat = (2.0 * CGFloat(M_PI)) + startAngle
      
      let center : CGPoint = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
      let radius : CGFloat = (CGFloat(self.bounds.size.width) - CGFloat(self.lineWidth!)) / CGFloat(2.0)
      
      let processBackgroundPath : UIBezierPath = UIBezierPath()
      processBackgroundPath.lineWidth = CGFloat(self.lineWidth!)
      
      if (partial) {
        endAngle = (1.8 * CGFloat(M_PI)) + startAngle
      }
      
      processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
      self.backgroundLayer?.path = processBackgroundPath.cgPath;
    }
    
    /**
    Start and stop spinning
    */    
    fileprivate func start() {
      self.isSpinning = true
      self.drawBackgroundCircle(true)
      
      let rotationAnimation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
      rotationAnimation.toValue = NSNumber(value: M_PI * 2.0 as Double)
      rotationAnimation.duration = 1;
      rotationAnimation.isCumulative = true;
      rotationAnimation.repeatCount = HUGE;
      self.backgroundLayer?.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    fileprivate func stop() {
      self.drawBackgroundCircle(false)
      
      self.backgroundLayer?.removeAllAnimations()
      self.isSpinning = false
    }
  }
  
  
  /**
  * Loader config
  */
  public struct Config {
    
    /**
    *  Size of loader
    */
    public var size : CGFloat = 120.0
    
    /**
    *  Color of spinner view
    */
    public var spinnerColor = UIColor.black
    
    /**
    *  S
    */
    public var spinnerLineWidth :Float = 1.0
    
    /**
     *  Spinner side margin
     */
    public var loaderSpinnerMarginSide : CGFloat = 35.0
    
    /**
     *  Spinner top margin
     */
    public var loaderSpinnerMarginTop : CGFloat = 20.0
    
    /**
     *  Title margin
     */
    public var loaderTitleMargin : CGFloat = 5.0
    
    /**
    *  Color of title text
    */
    public var titleTextColor = UIColor.black
    
    /**
    *  Font for title text in loader
    */
    public var titleTextFont : UIFont? = UIFont.boldSystemFont(ofSize: 16.0)
    
    /**
    *  Color of subtitle text
    */
    public var subtitleTextColor = UIColor.black
    
    /**
    *  Font for subtitle text in loader
    */
    public var subtitleTextFont : UIFont? = UIFont.systemFont(ofSize: 16.0)
    
    /**
    *  subtitle dismissing text in loader
    */
    public var subtitleDismissingText: String?
    
    /**
    *  Background color for loader
    */
    public var backgroundColor = UIColor.white
    
    /**
    * Background color for the cover
    */
    public var coverBackgroundColor = UIColor.white
    
    /**
    *  Foreground color
    */
    public var foregroundColor = UIColor.clear
    
    /**
    *  Foreground alpha CGFloat, between 0.0 and 1.0
    */
    public var foregroundAlpha:CGFloat = 0.0
    
    /**
    *  Corner radius for loader
    */
    public var cornerRadius : CGFloat = 10.0
    
    public init() {}
    
  }
}
