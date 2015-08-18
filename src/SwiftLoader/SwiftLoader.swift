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

let loaderSpinnerMarginSide : CGFloat = 35.0
let loaderSpinnerMarginTop : CGFloat = 20.0
let loaderTitleMargin : CGFloat = 5.0

public class SwiftLoader: UIView {
  
  private var coverView : UIView?
  private var titleLabel : UILabel?
  private var subtitleLabel: UILabel?
  private var loadingView : SwiftLoadingView?
  private var animated : Bool? = false
  private var canUpdated = false
  private var title: String?
  private var subtitle: String?
  private var dismissable: Bool? = false
  private var dismissCompletionBlock: (() -> Void)? = nil
  private var tapGesture: UITapGestureRecognizer?
  private var allowDismissAfter: UInt64 = 0
  
  private var config : Config = Config() {
    didSet {
      self.loadingView?.config = config
    }
  }
  
  override public var frame : CGRect {
    didSet {
      self.update()
    }
  }
  
  class var sharedInstance: SwiftLoader {
    struct Singleton {
      static let instance = SwiftLoader(frame: CGRectMake(0,0,Config().size,Config().size))
    }
    return Singleton.instance
  }
  
  public class func show(#animated: Bool) {
    self.show(title: nil, subtitle: nil, animated: false, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  public class func show(#title: String?, animated : Bool) {
    self.show(title: title, subtitle: nil, animated: animated, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  public class func show(#title: String?, subtitle: String?, animated: Bool) {
    self.show(title: title, subtitle: subtitle, animated: animated, dismissable: false, allowDismissAfter: 0, completionBlock: nil)
  }
  
  public class func show(#title: String?, subtitle: String?, animated: Bool, dismissable: Bool, allowDismissAfter: UInt64) {
    self.show(title: title, subtitle: subtitle, animated: animated, dismissable: dismissable, allowDismissAfter: allowDismissAfter, completionBlock: nil)
  }
  
  public class func show(#title: String?, subtitle: String?, animated: Bool, dismissable: Bool, allowDismissAfter: UInt64, completionBlock: (() -> Void)?) {
    var currentWindow : UIWindow = UIApplication.sharedApplication().keyWindow!
    
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
    
    var height : CGFloat = UIScreen.mainScreen().bounds.size.height
    var width : CGFloat = UIScreen.mainScreen().bounds.size.width
    var center : CGPoint = CGPointMake(width / 2.0, height / 2.0)
    loader.center = center
    
    loader.coverView = UIView(frame: currentWindow.bounds)
    loader.coverView?.backgroundColor = loader.config.coverBackgroundColor
    
    if dismissable {
      
      if loader.tapGesture == nil {
        loader.tapGesture = UITapGestureRecognizer(target: loader, action: "tapGestureHandle:")
        loader.tapGesture?.numberOfTapsRequired = 1
        loader.tapGesture?.numberOfTouchesRequired = 1
        loader.tapGesture?.cancelsTouchesInView = false
        loader.tapGesture?.enabled = false
        loader.coverView?.addGestureRecognizer(loader.tapGesture!)
      }
      
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(loader.allowDismissAfter * NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
        loader.tapGesture?.enabled = true
        if let subtitleDismissingText = loader.config.subtitleDismissingText {
          loader.subtitleLabel?.text = subtitleDismissingText
        }
      })
    }
    
    currentWindow.addSubview(loader.coverView!)
    currentWindow.addSubview(loader)
    loader.start()
  }
  
  public class func hide() {
    let loader = SwiftLoader.sharedInstance
    loader.tapGesture = nil
    loader.stop()
  }
  
  public class func setConfig(config : Config) {
    let loader = SwiftLoader.sharedInstance
    loader.config = config
    loader.frame = CGRectMake(0,0,loader.config.size,loader.config.size)
  }
  
  /**
  Private methods
  */
  
  private func setup() {
    self.alpha = 0
    self.update()
  }
  
  private func start() {
    self.loadingView?.start()
    
    if (self.animated!) {
      UIView.animateWithDuration(0.3, animations: { () -> Void in
        self.alpha = 1
        }, completion: { (finished) -> Void in
          
      });
    } else {
      self.alpha = 1
    }
  }
  
  private func stop() {
    
    if (self.animated!) {
      UIView.animateWithDuration(0.3, animations: { () -> Void in
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
  
  private func update() {
    self.backgroundColor = self.config.backgroundColor
    self.layer.cornerRadius = self.config.cornerRadius
    var loadingViewSize = self.frame.size.width - (loaderSpinnerMarginSide * 2)
    
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
      self.titleLabel = UILabel(frame: CGRectMake(loaderTitleMargin, yOffset, self.frame.width - loaderTitleMargin*2, height))
      self.addSubview(self.titleLabel!)
      self.titleLabel?.numberOfLines = 1
      self.titleLabel?.textAlignment = NSTextAlignment.Center
      self.titleLabel?.adjustsFontSizeToFitWidth = true
      self.titleLabel?.minimumScaleFactor = 12.0 / UIFont.labelFontSize()
    } else {
      self.titleLabel?.frame = CGRectMake(loaderTitleMargin, yOffset, self.frame.width - loaderTitleMargin*2, height)
    }
    
    self.titleLabel?.font = self.config.titleTextFont
    self.titleLabel?.textColor = self.config.titleTextColor
    self.titleLabel?.text = self.title
    
    self.titleLabel?.hidden = self.title == nil
    
    /*
    * Subtitle
    */
    yOffset = self.titleLabel!.hidden ? yOffset : self.titleLabel!.frame.height + self.titleLabel!.frame.origin.y
    
    if (self.subtitleLabel == nil) {
      self.subtitleLabel = UILabel(frame: CGRectMake(loaderTitleMargin, yOffset, self.frame.width - loaderTitleMargin*2, height))
      self.addSubview(self.subtitleLabel!)
      self.subtitleLabel?.numberOfLines = 1
      self.subtitleLabel?.textAlignment = NSTextAlignment.Center
      self.subtitleLabel?.adjustsFontSizeToFitWidth = true
      self.subtitleLabel?.minimumScaleFactor = 12.0 / UIFont.labelFontSize()
    } else {
      self.subtitleLabel?.frame = CGRectMake(loaderTitleMargin, yOffset, self.frame.width - loaderTitleMargin*2, height)
    }
    
    self.subtitleLabel?.font = self.config.subtitleTextFont
    self.subtitleLabel?.textColor = self.config.subtitleTextColor
    self.subtitleLabel?.text = self.subtitle
    
    self.subtitleLabel?.hidden = self.subtitle == nil
  }
  
  func frameForSpinner() -> CGRect {
    var loadingViewSize = self.frame.size.width - (loaderSpinnerMarginSide * 2)
    
    if (self.title == nil && self.subtitle == nil) {
      var yOffset = (self.frame.size.height - loadingViewSize) / 2
      return CGRectMake(loaderSpinnerMarginSide, yOffset, loadingViewSize, loadingViewSize)
    }
    return CGRectMake(loaderSpinnerMarginSide, loaderSpinnerMarginTop, loadingViewSize, loadingViewSize)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }
  
  required public init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func tapGestureHandle(sender: UITapGestureRecognizer) {
    println("[debug]: \((__FILE__).lastPathComponent.stringByDeletingPathExtension).\(__FUNCTION__) [Line \(__LINE__)]")
    SwiftLoader.hide()
    self.dismissCompletionBlock?()
  }
  
  /**
  *  Loader View
  */
  class SwiftLoadingView : UIView {
    
    private var lineWidth : Float?
    private var lineTintColor : UIColor?
    private var backgroundLayer : CAShapeLayer?
    private var isSpinning : Bool?
    
    private var config : Config = Config() {
      didSet {
        self.update()
      }
    }
    
    override init(frame: CGRect) {
      super.init(frame: frame)
      self.setup()
    }
    
    required init(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
    }
    
    /**
    Setup loading view
    */
    
    private func setup() {
      self.backgroundColor = UIColor.clearColor()
      self.lineWidth = fmaxf(Float(self.frame.size.width) * 0.025, 1)
      
      self.backgroundLayer = CAShapeLayer()
      self.backgroundLayer?.strokeColor = self.config.spinnerColor.CGColor
      self.backgroundLayer?.fillColor = self.backgroundColor?.CGColor
      self.backgroundLayer?.lineCap = kCALineCapRound
      self.backgroundLayer?.lineWidth = CGFloat(self.lineWidth!)
      self.layer.addSublayer(self.backgroundLayer!)
    }
    
    private func update() {
      self.lineWidth = self.config.spinnerLineWidth
      
      self.backgroundLayer?.lineWidth = CGFloat(self.lineWidth!)
      self.backgroundLayer?.strokeColor = self.config.spinnerColor.CGColor
    }
    
    /**
    Draw Circle
    */
    
    override func drawRect(rect: CGRect) {
      self.backgroundLayer?.frame = self.bounds
    }
    
    private func drawBackgroundCircle(partial : Bool) {
      var startAngle : CGFloat = CGFloat(M_PI) / CGFloat(2.0)
      var endAngle : CGFloat = (2.0 * CGFloat(M_PI)) + startAngle
      
      var center : CGPoint = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2)
      var radius : CGFloat = (CGFloat(self.bounds.size.width) - CGFloat(self.lineWidth!)) / CGFloat(2.0)
      
      var processBackgroundPath : UIBezierPath = UIBezierPath()
      processBackgroundPath.lineWidth = CGFloat(self.lineWidth!)
      
      if (partial) {
        endAngle = (1.8 * CGFloat(M_PI)) + startAngle
      }
      
      processBackgroundPath.addArcWithCenter(center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
      self.backgroundLayer?.path = processBackgroundPath.CGPath;
    }
    
    /**
    Start and stop spinning
    */
    
    private func start() {
      self.isSpinning? = true
      self.drawBackgroundCircle(true)
      
      var rotationAnimation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
      rotationAnimation.toValue = NSNumber(double: M_PI * 2.0)
      rotationAnimation.duration = 1;
      rotationAnimation.cumulative = true;
      rotationAnimation.repeatCount = HUGE;
      self.backgroundLayer?.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }
    
    private func stop() {
      self.drawBackgroundCircle(false)
      
      self.backgroundLayer?.removeAllAnimations()
      self.isSpinning? = false
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
    public var spinnerColor = UIColor.blackColor()
    
    /**
    *  S
    */
    public var spinnerLineWidth :Float = 1.0
    
    /**
    *  Color of title text
    */
    public var titleTextColor = UIColor.blackColor()
    
    /**
    *  Font for title text in loader
    */
    public var titleTextFont : UIFont? = UIFont.boldSystemFontOfSize(16.0)
    
    /**
    *  Background color for loader
    */
    public var backgroundColor = UIColor.whiteColor()
    
    
    /**
    * Background color for the cover
    */
    public var coverBackgroundColor = UIColor.whiteColor()
    
    /**
    *  Color of subtitle text
    */
    public var subtitleTextColor = UIColor.blackColor()
    
    /**
    *  Font for subtitle text in loader
    */
    public var subtitleTextFont : UIFont? = UIFont.systemFontOfSize(16.0)
    
    /**
    *  subtitle dismissing text in loader
    */
    public var subtitleDismissingText: String?
    /**
    *  Corner radius for loader
    */
    public var cornerRadius : CGFloat = 10.0
    
    public init() {}
    
  }
}
