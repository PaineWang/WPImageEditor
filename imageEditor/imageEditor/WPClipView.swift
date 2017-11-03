//
//  WPClipView.swift
//  drawCenterView
//
//  Created by WANG on 2017/9/14.
//  Copyright © 2017年 WANG. All rights reserved.
//

import Foundation
import UIKit
class WPClipView: WPImageManger {
    
    
    var clipPath:UIBezierPath = UIBezierPath()// draw path
    var pointArray:[CGPoint] = Array()
    var polygonCount = 3
    var degreeMeasure:Double?
    let clipPathSpace:CGFloat = 3
    
    //    setup 1.1 by means of nib file ,better show layout
    open class func loadClipViewWithNibFiledependOn(baseView:WPBaseView) -> WPClipView {
        
        let cView :WPClipView = UINib.init(nibName: "ImageImport", bundle: nil).instantiate(withOwner: self, options: nil)[1] as! WPClipView
        cView.frame = CGRect.init(x: baseView.center.x - 50, y: baseView.center.y - 50, width: 100, height: 100)
        cView.currentBaseView =  baseView
        return cView
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        self.transform = CGAffineTransform.identity
    }
    override func layoutSubviews() {
                self.setNeedsDisplay()
    }
    
    
    
     //    setup 4 confine setting
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (touches.first?.view?.isMember(of: WPClipView.self))! {
            
            super.touchesMoved(touches, with: event)
            
        }
        self.currentBaseView?.currentClipFrame = CGRect.init(x: self.center.x-self.frame.width/2, y: self.center.y-self.frame.height/2, width: self.frame.width, height: self.frame.height)
        // handle -9  clipViewangle = 0.0
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // MARK:handle -9 roattion later move  go back position
        self.transform = CGAffineTransform.init(rotationAngle: CGFloat(clipViewangle))
        
    }
    
    
    //    setup 2 draw image function
    
    override func draw(_ rect: CGRect) {
        
        if currentPaths.count == 0 {
            
            return
        }
        clipPath.removeAllPoints()
        //       equal type string to do load path
        switch currentPaths.firstObject as! String {
        case ShapeType.Cercle.rawValue:
            clipPath = UIBezierPath.init(roundedRect:CGRect.init(x:clipPathSpace, y:clipPathSpace, width: self.frame.width-clipPathSpace*2, height: self.bounds.height-clipPathSpace*2), cornerRadius: (self.bounds.width)/2)
            clipPath.lineWidth = 2

        case ShapeType.Triangle.rawValue:
            
            clipPath.move(to: CGPoint.init(x: self.frame.width/2, y: clipPathSpace))
            clipPath.addLine(to: CGPoint.init(x: clipPathSpace, y:self.frame.height-clipPathSpace*2))
            clipPath.addLine(to: CGPoint.init(x: self.frame.width-clipPathSpace*2, y:self.frame.height-clipPathSpace*2))
            clipPath.addLine(to: CGPoint.init(x: self.frame.width/2, y:clipPathSpace))
            clipPath.lineWidth = 2

        case ShapeType.Rectangle.rawValue:
            clipPath = UIBezierPath(rect: CGRect.init(x: clipPathSpace, y: clipPathSpace, width: self.bounds.width-clipPathSpace*2, height: self.bounds.height-clipPathSpace*2))
            clipPath.lineWidth = 2

        case ShapeType.Oval.rawValue:
           
            clipPath = UIBezierPath(ovalIn: CGRect.init(x: clipPathSpace, y: clipPathSpace*2, width: self.frame.width-clipPathSpace*2, height: self.frame.height-clipPathSpace*4))
            clipPath.lineWidth = 2

        case ShapeType.Polygon.rawValue:
            pointArray.removeAll()
            clipPath = UIBezierPath()
            let beginPoint:CGPoint = CGPoint.init(x:self.frame.size.width/2, y:0)
            clipPath.move(to:beginPoint)
            addPolygon()
            for index in 0..<polygonCount {
                clipPath.addLine(to: pointArray[index])
            }
            clipPath.lineWidth = 2

        default:
            
            print("not type")
            
        }
        
        if isCut {
            
            UIColor.clear.set()
            
        }else
        {
            UIColor.black.set()
            clipPath.stroke()
        }
        

        clipPath.addClip()
        
        //  setup 1 copy temp
        self.currentShapeType = currentPaths.firstObject as!String
        //  remove all
        //MARK: self.currentPaths.removeAllObjects()
        //   add new path and name
        let newPathArray :NSMutableArray = [self.currentShapeType,clipPath]
        //   replace new data
        self.currentPaths = newPathArray
        if  ((self.currentClipView?.showClipImageView.image) != nil) {
            self.currentClipView?.showClipImageView.clip(rect: (self.currentClipView?.showClipImageView.frame)!, edtingImage: (self.currentClipView?.showClipImageView.image)!)
        }
    }
    func addPolygon() {
        if self.degreeMeasure == nil {
         degreeMeasure = degree(count:CGFloat(polygonCount))
        }
        let beginPoint:CGPoint = CGPoint.init(x:self.frame.size.width/2, y:0)
        let boundsCenter = CGPoint.init(x: self.frame.size.width/2, y: self.frame.size.height/2)
        var endPoint:CGPoint = pointRotatedAroundAnchorPoint(point:beginPoint,anchorPoint:boundsCenter,angle:degreeMeasure!)
        pointArray.append(endPoint)
        for index in 1..<polygonCount {
            endPoint = pointRotatedAroundAnchorPoint(point: pointArray[index-1], anchorPoint: boundsCenter, angle:degreeMeasure!)
            pointArray.append(endPoint)
        }
    }
    
      open func addAndDecrease_Polygon_Action(_ sender: UIButton) {
        // update frame
        self.frame = CGRect.init(origin: self.frame.origin, size: CGSize.init(width: 100, height: 100))
        
        if sender.tag == 345 {// add
            polygonCount += 1
        }else{//Decrease
            polygonCount -= 1
        }
        // FIXME: MAX 20 MIN 3
        if polygonCount>20 {
            polygonCount = 20
        }
        if polygonCount<3 {
            polygonCount = 3
        }
        degreeMeasure = degree(count:CGFloat(polygonCount))
        self.setNeedsDisplay()
    }
    func degree(count:CGFloat) ->Double {
        let clipLength:CGFloat = self.frame.width*4.15
        let cercleLength:CGFloat = self.frame.width*CGFloat(Double.pi)
        let length:CGFloat = clipLength / count
        let measureLength:CGFloat = 360/cercleLength
        let degree:Double = Double(length/measureLength)
        return  Double.pi*degree/180
    }
    
    func pointRotatedAroundAnchorPoint(point:CGPoint,anchorPoint:CGPoint,angle:Double) ->CGPoint{
        let x:CGFloat = (point.x-anchorPoint.x)*CGFloat(cos(angle))-(point.y-anchorPoint.y)*CGFloat(sin(angle)) + anchorPoint.x
        let y:CGFloat = (point.x-anchorPoint.x)*CGFloat(sin(angle)) + (point.y-anchorPoint.y)*CGFloat(cos(angle))+anchorPoint.y
        return CGPoint(x:x, y:y)
    }
    override  func addShapeClipViewToMainView() {
        // convert frame
        let convertFrame = self.currentBaseView?.convert((self.currentClipView?.frame)!, to: self.superview?.superview)
        // copy new frame on the super view
        
        // add sub view
        self.frame = convertFrame!
        self.superview?.superview?.addSubview(self.currentClipView!)
        
        // copy new image to currentImage
        self.currentImage = (self.currentClipView?.showClipImageView.image)!
        
        self.showClipImageView = self.currentClipView?.showClipImageView
        
        self.currentClipView?.rotationControlButton.isHidden = false
      
        
    }
    
}

class WPShapeImageView: UIImageView {
    
    
    internal func RadiansToDegrees(_ angle :Double )->Double{ return angle*180/Double.pi }
    
    
    public var lastPath:UIBezierPath?
    
    public var isFree:Bool = false
    
    
    
    // shape clip image
    public  func clip(rect:CGRect,edtingImage:UIImage) {
        
        let backgroudView :WPClipView = superview as! WPClipView
        let paths = backgroudView.currentPaths
        lastPath = paths[1] as? UIBezierPath
//        lastPath?.removeAllPoints()
        let shapeLayer = CAShapeLayer()
        // equal type string to do load path
//        switch paths.firstObject as! String {
//            
//        case ShapeType.Cercle.rawValue:
//            
//            lastPath? = UIBezierPath.init(roundedRect:CGRect.init(x:3, y:3, width:rect.width-6, height: rect.height-6), cornerRadius: rect.width/2)
//            
//        case ShapeType.Triangle.rawValue:
//            
//            lastPath?.move(to: CGPoint.init(x: rect.width/2, y:3))
//            lastPath?.addLine(to: CGPoint.init(x:3, y:rect.height-6))
//            lastPath?.addLine(to: CGPoint.init(x: rect.width-6, y:rect.height-6))
//            lastPath?.addLine(to: CGPoint.init(x: rect.width/2, y:3))
//            
//        case ShapeType.Rectangle.rawValue:
//            
//            lastPath? = UIBezierPath(rect: CGRect.init(x:3, y:3, width:rect.width-6, height: rect.height-6))
//            
//        case ShapeType.Oval.rawValue:
//            
//            lastPath? = UIBezierPath.init(ovalIn: CGRect.init(x:3, y: 3, width: rect.width-6, height: rect.height-6))
//        case ShapeType.Polygon.rawValue:
//            
//            lastPath? = (paths[1] as? UIBezierPath)!
//   
//        default:
//            
//            print("not type")
//            
//        }
        
        if self.image == nil {
            
            
            let sourceImageRef: CGImage = edtingImage.cgImage!
            
            let newCGImage :CGImage = sourceImageRef.cropping(to:rect)!
            
            let newImage:UIImage = UIImage.init(cgImage: newCGImage)
            
            self.image = newImage
            
        }
        
        lastPath?.fill()
        lastPath?.addClip()
        shapeLayer.path = lastPath?.cgPath
        self.layer.mask = shapeLayer
        
    }
    
    // free path clip image
    public func cuting() -> UIImage {
        
        var imgSize:CGSize = CGSize.zero
        
        if let path = self.lastPath {// 1. free path clip image action
            
            imgSize = (self.image?.size)!
            
            UIGraphicsBeginImageContextWithOptions(imgSize, false, 1)
            path.addClip()
            self.image?.draw(at: CGPoint.zero)
            
            let newImage2  = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsBeginImageContextWithOptions(imgSize, false, 1)
            
            let sourceImageRef: CGImage = (newImage2!.cgImage!)// next In accordance with the path bouns .clip image szie
            
            let newCGImage :CGImage = sourceImageRef.cropping(to:(self.lastPath?.bounds)!)!
            
            let newImage:UIImage = UIImage.init(cgImage: newCGImage)
            
            self.isFree = false
            
            return newImage
            
        }else // 2. not clip iamge action
        {
            
            imgSize = self.frame.size
            
            self.image = self.image?.imageByScalingToSize(targetSize: (self.frame.size))
            
            UIGraphicsBeginImageContextWithOptions(imgSize, false, 1)
            
            self.image?.draw(at: CGPoint.zero)
            
            let newImage2  = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return newImage2!
            
        }
        
    }
    
    // paste image operation
    
    func pasteImage() -> UIImage {
        
        let pasteView = self.superview as!WPImageManger
        var imageSize = self.frame.size
        var screen:UIView = self
        pasteView.isHiddenAllsubViews(hidden: true)
        if (baseViewangle != 0) && isCut {
            // is cuting
            imageSize = pasteView.frame.size
            screen = pasteView
        }
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1)
        screen.layer.render(in: UIGraphicsGetCurrentContext()!)
        let layerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return layerImage!
    }
    
}










