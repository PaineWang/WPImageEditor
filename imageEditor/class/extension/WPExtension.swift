//
//  WPExtension.swift
//  WPImageEditor2
//
//  Created by pow on 2017/11/9.
//  Copyright © 2017年 pow. All rights reserved.
//

import Foundation
import UIKit
// sub action type
public enum SubActionType : String {
    case crop_free
    case crop_image
    case fullCanvas_scaleFill
    case fullCanvas_scaleFit
    case crop_canvas
    case crop_polygon
    case crop_43
    case crop_169
    case Cercle
    case Triangle
    case Rectangle
    case Oval
    case Free_C
    case Free_S
    case rotate_left
    case rotate_right
    case subCancel
    case centerSelected
    case rotateCancel
    case clip
}
// main action type
public enum OperationType : String {
    case unknown
    case crop
    case rotation
    case full
    case center
    case undo
    case cancel
    case done
    case redo
    case reset
    case paste
    case rotateRatio
}
var isCut:Bool = false

var selectedActionType:String = OperationType.unknown.rawValue

//DegreesToRadians
func DegreesToRadians(_ angle :Double )->Double{ return Double.pi*angle/180 }
func RadiansToDegrees(_ angle :Double )->Double{ return angle*180/Double.pi }
func pointRotatedAroundAnchorPoint(point:CGPoint,anchorPoint:CGPoint,angle:Double) ->CGPoint{
    let x:CGFloat = (point.x-anchorPoint.x)*CGFloat(cos(angle))-(point.y-anchorPoint.y)*CGFloat(sin(angle)) + anchorPoint.x
    let y:CGFloat = (point.x-anchorPoint.x)*CGFloat(sin(angle)) + (point.y-anchorPoint.y)*CGFloat(cos(angle))+anchorPoint.y
    return CGPoint(x:x, y:y)
}
extension Dictionary {
    
    func sortKeys() -> Array<Any> {
        
       return self.keys.sorted { (key1, key2) -> Bool in
            
           return key1.hashValue < key2.hashValue
        }
        
        
        
    }
    
}
extension CGSize {
    
    func proportionSize(p:CGFloat) -> CGSize {
        
        let Oriscale = (self.width)/(self.height)
        var width:CGFloat = 0
        var height:CGFloat = 0
        
        if Oriscale > p {
            height = (self.height)
            width = height * p
            
        }else{
            width = (self.width)
            height = width/p
            
            
        }
        return CGSize.init(width: width, height: height)
    }
    
  
    
}

extension CGFloat {
    
    func exchange(x:CGFloat,y:CGFloat) -> CGFloat {
        if self == x/y {
            return y/x
        }
        return x/y
    }
}




/**color rgb to convert code string **/
extension UIColor{
    
    
    public class func WP_Color_Conversion ( _ Color_Value:NSString)->UIColor{
        var  Str :NSString = Color_Value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased() as NSString
        if Color_Value.hasPrefix("#"){
            Str=(Color_Value as NSString).substring(from: 1) as NSString
        }
        let wp_StrRed = (Str as NSString ).substring(to: 2)
        let wp_StrGreen = ((Str as NSString).substring(from: 2) as NSString).substring(to: 2)
        let wp_StrBlue = ((Str as NSString).substring(from: 4) as NSString).substring(to: 2)
        var r:CUnsignedInt = 0, g:CUnsignedInt = 0, b:CUnsignedInt = 0;
        Scanner(string:wp_StrRed).scanHexInt32(&r)
        Scanner(string: wp_StrGreen).scanHexInt32(&g)
        Scanner(string: wp_StrBlue).scanHexInt32(&b)
        return UIColor(red: CGFloat(r)/255.0, green: CGFloat(g)/255.0, blue: CGFloat(b)/255.0, alpha: 1)
        
    }
    
}
/**DispatchQueue once  extension**/
public extension DispatchQueue {
    
    public static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public class func once(token: String, block:()->Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}
/**
 if to setting imageView of image ,must before  adjust image size .to Fit imageView .becase clip  relative to self image  size .not imageView frame
 **/
extension UIImage{
    
    
    /**
     calculate rotaed
     - parameter Radian:
     */
    public  func imageRotatedByRadians(radinFlaot:Double) -> UIImage {
        
       
        let t:CGAffineTransform = CGAffineTransform.init(rotationAngle: CGFloat(radinFlaot))
        
        let rotatedRect = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height).applying(t)
        
        let rotaedSize = rotatedRect.size
        
        UIGraphicsBeginImageContextWithOptions(rotaedSize, false, UIScreen.main.scale)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.translateBy(x: (rotaedSize.width)/2, y: (rotaedSize.height)/2)
        
        context?.rotate(by:CGFloat(radinFlaot))
        
        context?.scaleBy(x:1, y:-1)
        
        context?.draw((self.cgImage!), in:CGRect.init(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height:self.size.height))
        
        let  newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    class func imageWithImage(_ image: UIImage, scaledToFillToSize newSize: CGSize) -> UIImage? {
        //Determine the scale factors
        let widthScale = newSize.width / image.size.width;
        let heightScale = newSize.height / image.size.height;
        
        var scaleFactor: CGFloat
        
        //The larger scale factor will scale less (0 < scaleFactor < 1) leaving the other dimension hanging outside the newSize rect
        widthScale > heightScale ? (scaleFactor = widthScale) : (scaleFactor = heightScale)
        let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
        
        //Create origin point so that the center of the image falls into the drawing context rect (the origin will have negative component).
        var imageDrawOrigin = CGPoint(x: 0, y: 0)
        widthScale > heightScale ? (imageDrawOrigin.y = (newSize.height - scaledSize.height) * 0.5):
            (imageDrawOrigin.x = (newSize.width - scaledSize.width) * 0.5);
        
        
        //Create rect where the image will draw
        let imageDrawRect = CGRect(x: imageDrawOrigin.x, y: imageDrawOrigin.y, width: scaledSize.width, height: scaledSize.height);
        
        //The imageDrawRect is larger than the newSize rect, where the imageDraw origin is located defines what part of
        //the image will fall into the newSize rect.
        return imageWithImage(image, scaledToSize: newSize, inRect: imageDrawRect)
    }
    
    class func imageWithImage(_ image: UIImage, scaledToFitToSize newSize: CGSize) -> UIImage? {
        //Only scale images down
        if (image.size.width < newSize.width && image.size.height < newSize.height) {
            return image;
        }
        //Determine the scale factors
        let widthScale = newSize.width / image.size.width;
        let heightScale = newSize.height / image.size.height;
        var scaleFactor: CGFloat;
        //The smaller scale factor will scale more (0 < scaleFactor < 1) leaving the other dimension inside the newSize rect
        widthScale < heightScale ? (scaleFactor = widthScale) : (scaleFactor = heightScale);
        let scaledSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor);
        //Scale the image
        return imageWithImage(image, scaledToSize: scaledSize, inRect: CGRect(x: 0.0, y: 0.0, width: scaledSize.width, height: scaledSize.height));
    }
    class func imageWithImage(_ image: UIImage, scaledToSize newSize: CGSize, inRect rect: CGRect) -> UIImage? {
        //Determine whether the screen is retina
        if UIScreen.main.scale == 2.0 {
            UIGraphicsBeginImageContextWithOptions(newSize, true, 2.0);
        } else {
            UIGraphicsBeginImageContext(newSize);
        }
        
        //Draw image in provided rect
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        //Pop this context
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    class func imageRotatedByDegrees(_ image: UIImage, degrees: CGFloat) -> UIImage?
    {
        if degrees == 0 {
            return image
        }
        let radians = degrees
        // calculate the size of the rotated view's containing box for our drawing space
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let rotatedRect = rect.applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
        let rotatedSize = rotatedRect.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, UIScreen.main.scale)
        if let bitmap = UIGraphicsGetCurrentContext() {
            // Move the origin to the middle of the image so we will rotate and scale around the center.
            bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2);
            
            //   // Rotate the image context
            bitmap.rotate(by: CGFloat(radians));
            
            // Now, draw the rotated/scaled image into the context
            bitmap.scaleBy(x: 1.0, y: -1.0);
            
            if let cgImage = image.cgImage {
                bitmap.draw(cgImage, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
        
    }
}
func getAddress(obj:AnyObject) -> String {
    let address = Unmanaged.passUnretained(obj).toOpaque()
    return "\(address)"
}
let nibName:String = "ImageEditor2Nib"
extension UINib{
    
    convenience init(nibName:String,instantiate:Any,viewBlock:@escaping (_ view:Any)->Void) {
        self.init(nibName: nibName, bundle: Bundle.init(for:instantiate as! AnyClass))
        let owner  = self.instantiate(withOwner: instantiate, options: nil)
        for view:Any in owner {
            if ((view as AnyObject).isMember(of:instantiate as! AnyClass)) {
                viewBlock(view as AnyObject)
            }
        }
        
        
    }
}
extension CGRect {
    func applyingInversed() -> CGRect {
        return CGRect.init(x: self.minY, y: self.minX, width: self.height, height: self.width)
    }
}
extension Int {
    
    mutating func maxAngleValue() -> Int {
        if self >= 360 {
            self = 0
        }
        switch abs(self) {
        case 0...89:
            return 90
        case 91...179:
            return 180
        case 181...269:
            return 270
        case 271...359:
            return 360
        default:
            return self+90
        }
        
    }
}
extension UIImagePickerController {
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation
    {
        var orinentation: UIInterfaceOrientation = UIInterfaceOrientation.init(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
        if UIApplication.shared.statusBarOrientation.rawValue > 4 || UIApplication.shared.statusBarOrientation.rawValue < 1 {
            orinentation = .portrait
        }
        return orinentation
    }
    
    
    
}
 // handle -3 undo
class MoveGestureRecognizer: UIPanGestureRecognizer {
    
    
   var newState:Int = 0
    
    func getState() -> UIGestureRecognizerState {
        return UIGestureRecognizerState(rawValue: self.newState)!
    }
    
    override func setTranslation(_ translation: CGPoint, in view: UIView?)  {
        self.newState = self.state.rawValue
        super.setTranslation(translation, in: view)
        self.newState = self.state.rawValue
       
    }
    
    
}


