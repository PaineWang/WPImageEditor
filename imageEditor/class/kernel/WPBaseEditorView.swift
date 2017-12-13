//
//  WPBaseEditorView.swift
//  WPImageEditor2
//
//  Created by pow on 2017/11/9.
//  Copyright © 2017年 pow. All rights reserved.
//


import UIKit

enum undoKey:String {
    case image
    case center
    case orientation
    case transform
}

public typealias baseBlock = (UIImage,CGRect)->()
public class WPBaseEditorView: UIView,WPSideMenuDelegate,WPAngleRulerProtocol {
    
    /**
     Free path  view
     */
    @IBOutlet public weak var freePathView: WPFreePathView!
    /**
     photo library  of original image
     */
    public var originalImage:UIImage?
    /**
     oringinalFrame
     */
    public var oringinalFrame:CGRect?
    /**
     rotated angle
     */
    public var baseViewangle:CGFloat?
    
    var sideMenu:WPSideMenu?
    
    var angleRulerView:WPAngleRuler?
    /**
     current crop view
     */
    public var currentCropView:WPCropEditorView?// current clip view
    
    @IBOutlet weak var shpaeImageView: WPShapeImageView!
    
    var undoPackage:[(image:UIImage,orientation:UIInterfaceOrientation,transform:CGAffineTransform,center:CGPoint)] = Array()
    var stepBystep:Int = 1
    /**
     call back block .return  after clip image and current frame
     */
    public var pasteBlock:baseBlock?
    
    var moveGestureRecognizer:UIPanGestureRecognizer?
    
    public var moveableArea:CGRect?
    
    var undoIndex:Int = 0
    
    var isRotatedClip:Bool = false
    
    var willChangeRatio:CGRect  = CGRect.zero
    
    var willChangeFrame:CGRect = CGRect.zero
    // isPortrait
    var initIsPortrait:Bool = UIApplication.shared.statusBarOrientation.isPortrait
    
    var imageMaxRatio:CGFloat = 1
    
    var currentIsPortrait:Bool = UIApplication.shared.statusBarOrientation.isPortrait
    
    override public func layoutSubviews() {
        if let frame  = self.oringinalFrame {
            if !self.frame.equalTo(frame){
                self.sideMenu?.resetButton.isEnabled = true
            }
        }
    }
}
// MARK: - INIT -
extension WPBaseEditorView {
    
    public class func loadNibFileToSetup(editorImage:UIImage,InSuperView:UIView)->WPBaseEditorView {
        
        var  baseView:WPBaseEditorView?
        _ =  UINib.init(nibName: nibName, instantiate: WPBaseEditorView.self) {
            (view) in
            baseView = view as? WPBaseEditorView
        }
        InSuperView.addSubview(baseView!)
        baseView?.loadsideMenuView()
        baseView?.originalImage = editorImage
        return baseView!
    }
    
    public func  setup(){
        if let editorImage = self.originalImage {
            self.shpaeImageView.image = editorImage
            let bigBounds = CGRect.init(x: 0, y: 0, width:getSizeToFitScreen().width, height:getSizeToFitScreen().height)
            self.bounds = bigBounds
            self.center = (superview?.center)!
            self.oringinalFrame = self.frame
            addMoveGesture()
            saveToUndoPackage(image: editorImage)
        }
    }
    func updateLayout() {
        let undoTuples = self.undoPackage[undoIndex]
        var isMatch:Bool = false
        self.bounds = CGRect.init(origin: CGPoint.zero, size: self.willChangeFrame.size)
        if self.baseViewangle != nil  && !isCut{
            updateScaleFit()
        }else {
            self.bounds = CGRect.init(origin: CGPoint.zero, size: getSizeToFitScreen(undoTuples.image))
        }
        if isRotatedClip {
            self.bounds = CGRect.init(origin: CGPoint.zero, size: self.shpaeImageView.frame.size)
            self.shpaeImageView.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
            self.shpaeImageView.transform = CGAffineTransform.identity
        }
        if undoTuples.orientation.isPortrait == UIApplication.shared.statusBarOrientation.isPortrait {
            isMatch = true
        }else if undoTuples.orientation.isLandscape == UIApplication.shared.statusBarOrientation.isLandscape {
            isMatch = true
        }
        if isMatch {
            self.center = undoTuples.center
        }else{
            self.center = (superview?.center)!
        }
        self.oringinalFrame = self.frame
        if let crop = self.currentCropView {
            crop.frame = computeRatio(didChangeFrame: self.willChangeFrame, withFrame:crop.willChangeFrame)
        }
    }
    func updateScaleFit()  {
        let canvasSize:CGSize = (self.moveableArea?.size)!
        let minCanvasValue:CGFloat = min((canvasSize.width), (canvasSize.height))
        let frameFit:CGSize = self.shpaeImageView.frame.size
        var ratio :CGFloat  = 1
        if !currentIsPortrait { // landscape
            ratio = UIApplication.shared.statusBarOrientation.isPortrait ? min(canvasSize.width, canvasSize.height) / frameFit.width :  min(canvasSize.width, canvasSize.height)  / frameFit.height
        }else{
            ratio = UIApplication.shared.statusBarOrientation.isLandscape ?  min(canvasSize.width, canvasSize.height)/frameFit.height :  minCanvasValue / frameFit.width
        }
        let maxRatio:CGFloat = getMaxRatio()
        if ratio > maxRatio {
            ratio = maxRatio
        }
        self.shpaeImageView.transform = self.shpaeImageView.transform.scaledBy(x:ratio, y:ratio)
    }
    func updateScalefill() {
        let canvasSize:CGSize = (self.moveableArea?.size)!
        let minCanvasValue:CGFloat = min((canvasSize.width), (canvasSize.height))
        let minImageViewValue:CGFloat = UIApplication.shared.statusBarOrientation.isPortrait ? (self.shpaeImageView.frame.size.width) : (self.shpaeImageView.frame.size.height)
        var ratio:CGFloat = minCanvasValue/minImageViewValue
        let maxRatio:CGFloat = getMaxRatio()
        if ratio > maxRatio {
            ratio = maxRatio
        }
        self.currentIsPortrait = UIApplication.shared.statusBarOrientation.isPortrait
        self.shpaeImageView.transform = self.shpaeImageView.transform.scaledBy(x:ratio, y:ratio)
    }
    
    func getSizeToFitScreen() -> CGSize {
        if let image = originalImage {
            return getSizeToFitScreen(image)
        }
        return CGSize.zero
    }
    
    func getSizeToFitScreen(_ image: UIImage) -> CGSize {
        let scale = getScaleToFitScreen(image)
        return image.size.applying(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    func getScaleToFitScreen(_ image: UIImage, isHorizontal: Bool = false) -> CGFloat {
        var maxWidth = UIScreen.main.bounds.width // Maximum width of image container
        var maxHeight = UIScreen.main.bounds.height // Maximum height of image container
        let imageOriginalSize =  CGSize(width: image.scale * image.size.width, height: image.scale * image.size.height) // Original size of image.
        if let canvasSize = self.moveableArea {
            maxWidth = min(maxWidth, canvasSize.width)
            maxHeight = min(maxHeight, canvasSize.height)
        }
        let scaleX: CGFloat
        if isHorizontal {
            scaleX = maxWidth / imageOriginalSize.height
        } else {
            scaleX = maxWidth / imageOriginalSize.width
        }
        let scaleY: CGFloat
        if isHorizontal {
            scaleY = maxHeight / imageOriginalSize.width
        } else {
            scaleY = maxHeight / imageOriginalSize.height
        }
        return min(1, min(scaleX, scaleY))
    }
    func getImageIsHorizontal() -> Bool {
        let size:CGSize = (self.shpaeImageView.image?.size)!
        if size.width > size.height {
            return true
        }else{
            return false
        }
    }
    func getMaxRatio() -> CGFloat{
        let canvasSize:CGSize = (self.moveableArea?.size)!
        let imageSize:CGSize = (self.shpaeImageView.image?.size)!
        let baseBounds:CGSize = self.shpaeImageView.frame.size
        var  maxRatio:CGFloat = 1
        if self.shpaeImageView.frame.size.width > imageSize.width  || self.shpaeImageView.frame.size.height > imageSize.height {
            
            return maxRatio
        }
        var width:CGFloat ,height:CGFloat
        if UIApplication.shared.statusBarOrientation.isPortrait {
            width  = canvasSize.height/baseBounds.width
            height = canvasSize.height/baseBounds.height
        }else{
            width  = canvasSize.width/baseBounds.width
            height = canvasSize.width/baseBounds.height
        }
        maxRatio = min(width, height)
        return maxRatio
    }
    func computeRatio(didChangeFrame:CGRect,withFrame:CGRect) -> CGRect {
        self.willChangeRatio.size.width = withFrame.size.width/(didChangeFrame.size.width / self.frame.size.width)
        self.willChangeRatio.size.height = withFrame.size.height/(didChangeFrame.size.height / self.frame.size.height)
        self.willChangeRatio.origin.x = withFrame.origin.x/(didChangeFrame.size.width / self.frame.size.width)
        self.willChangeRatio.origin.y = withFrame.origin.y/(didChangeFrame.size.height / self.frame.size.height)
        return self.willChangeRatio
    }
    
    func getCurrentScreenSize(moveSize:CGSize) -> CGSize {
        var toScaleSize:CGSize?
        toScaleSize = UIScreen.main.bounds.width > UIScreen.main.bounds.height ?  CGSize.init(width: moveSize.width, height: moveSize.height) : moveSize
        return toScaleSize!
    }
}
// MARK: - MOVE -
extension WPBaseEditorView {
    func addMoveGesture() {
        if self.moveGestureRecognizer == nil {
            let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(performMoveAction(_:)))
            moveGesture.minimumNumberOfTouches = 1
            self.moveGestureRecognizer = moveGesture
            self.addGestureRecognizer(moveGesture)
        }
    }
    
    func setMoveable(_ canMove: Bool) {
        self.moveGestureRecognizer?.isEnabled = canMove
    }
    
    @objc func performMoveAction(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        
        switch recognizer.state {
        case .ended:
            saveToUndoPackage(image: self.shpaeImageView.image!)
            self.sideMenu?.undoButton.isEnabled = true
            undoIndex = undoPackage.count - 1
            break
            
        default:
            break
        }
        if let visibleRect = moveableArea {
            let location = self.frame.origin.applying(CGAffineTransform(translationX: translation.x, y: translation.y))
            var x = location.x
            var y = location.y
            let width = self.frame.width
            let height = self.frame.height
            
            if x < visibleRect.minX {
                x = visibleRect.minX
            }
            if y < visibleRect.minY {
                y = visibleRect.minY
            }
            if (x + width) > visibleRect.maxX {
                x = visibleRect.maxX - width
            }
            if (y + height) > visibleRect.maxY {
                y = visibleRect.maxY - height
            }
            self.center = CGPoint.init(x: x+(width/2), y: y+(height/2))
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
    }
    
}
// MARK: PROTOCOL
extension WPBaseEditorView {
    
    func didScrollAngle(angle: CGFloat) {
        baseViewangle = angle
        if isCut {
            self.shpaeImageView.transform = CGAffineTransform.init(rotationAngle: angle)
        }else{
            self.shpaeImageView.transform = CGAffineTransform.init(rotationAngle: angle)
            updateScalefill()
        }
    }
    func scrollRulerState(panGresture: UIPanGestureRecognizer) {
        if  panGresture.state == .ended {
            saveToUndoPackage(image: self.shpaeImageView.image!)
            self.sideMenu?.undoButton.isEnabled = true
            self.sideMenu?.resetButton.isEnabled = true
            undoIndex = self.undoPackage.count - 1
        }
    }
    func onClick_SideMenu_SubAction_Events(type: String, sender: UIButton) {
        
        switch type {
        case OperationType.rotation.rawValue:
            selectedActionType = type
            addRotationView()
            break
        case OperationType.rotateRatio.rawValue:
            selectedActionType = type
            if let crop = self.currentCropView {
                crop.rotateRatio()
            }
            break
        case SubActionType.rotate_right.rawValue:
            selectedActionType = type
            if let angle  = baseViewangle {
                var d_Value:Int = Int(RadiansToDegrees(Double(abs(angle))))
                baseViewangle = CGFloat(DegreesToRadians(Double(d_Value.maxAngleValue())))
            }else{
                baseViewangle = CGFloat(DegreesToRadians(90))
            }
            self.angleRulerView?.angleCollectionView.transform = CGAffineTransform.init(rotationAngle:baseViewangle!)
            self.angleRulerView?.lastclockwise_Angle = baseViewangle!
            if isCut {
                self.shpaeImageView.transform = (self.angleRulerView?.angleCollectionView.transform)!
            }else{
                self.shpaeImageView.transform = (self.angleRulerView?.angleCollectionView.transform)!
                updateScalefill()
            }
            saveToUndoPackage(image: self.shpaeImageView.image!)
            undoIndex = undoPackage.count - 1
            if RadiansToDegrees(Double(baseViewangle!)) == 360 {
                baseViewangle = nil
            }
            self.sideMenu?.undoButton.isEnabled = true
            self.sideMenu?.resetButton.isEnabled = true
            break
        case SubActionType.rotate_left.rawValue:
            selectedActionType = type
            if let angle  = baseViewangle {
                var d_Value:Int = Int(RadiansToDegrees(Double(abs(angle))))
                baseViewangle = -CGFloat(DegreesToRadians(Double(d_Value.maxAngleValue())))
            }else{
                baseViewangle = -CGFloat(DegreesToRadians(90))
            }
            self.angleRulerView?.angleCollectionView.transform = CGAffineTransform.init(rotationAngle:baseViewangle!)
            self.angleRulerView?.lastclockwise_Angle = baseViewangle!
            if isCut {
                self.shpaeImageView.transform = (self.angleRulerView?.angleCollectionView.transform)!
            }else{
                self.shpaeImageView.transform = (self.angleRulerView?.angleCollectionView.transform)!
                updateScalefill()
            }
            saveToUndoPackage(image: self.shpaeImageView.image!)
            undoIndex = undoPackage.count - 1
            if RadiansToDegrees(Double(baseViewangle!)) == -360 {
                baseViewangle = nil
            }
            self.sideMenu?.undoButton.isEnabled = true
            self.sideMenu?.resetButton.isEnabled = true
            break
        case SubActionType.fullCanvas_scaleFit.rawValue:
            selectedActionType = type
            let undoTuples = self.undoPackage[undoIndex]
            self.shpaeImageView.image = UIImage.imageRotatedByDegrees(self.shpaeImageView.image!, degrees:acos(undoTuples.transform.a))
            self.shpaeImageView.image = UIImage.imageWithImage(undoTuples.image , scaledToFitToSize:getCurrentScreenSize(moveSize:  (self.moveableArea?.size)!))
            self.bounds = CGRect.init(x: 0, y: 0, width: (self.shpaeImageView.image?.size.width)!, height: (self.shpaeImageView.image?.size.height)!)
            self.center = (superview?.center)!
            break
        case SubActionType.fullCanvas_scaleFill.rawValue:
            selectedActionType = type
            let undoTuples = self.undoPackage[undoIndex]
            self.shpaeImageView.image = UIImage.imageRotatedByDegrees(self.shpaeImageView.image!, degrees:acos(undoTuples.transform.a))
            let  fillRect:CGRect = CGRect.init(origin: CGPoint.zero, size: getCurrentScreenSize(moveSize: (self.moveableArea?.size)!))
            self.shpaeImageView.image = UIImage.imageWithImage(undoTuples.image, scaledToSize:fillRect.size, inRect:fillRect)
            self.bounds = CGRect.init(x: 0, y: 0, width: (self.shpaeImageView.image?.size.width)!, height: (self.shpaeImageView.image?.size.height)!)
            self.center = (superview?.center)!
            break
        case OperationType.crop.rawValue:
            selectedActionType = type
            break
        case OperationType.center.rawValue:
            selectedActionType = type
            self.center = (superview?.center)!
            break
        case SubActionType.subCancel.rawValue:
            selectedActionType = type
            self.currentCropView?.drawBackgroudView?.removeFromSuperview()
            self.currentCropView?.removeFromSuperview()
            self.currentCropView = nil
            self.freePathView.isHidden = true
            NotificationCenter.default.removeObserver(self.angleRulerView as Any)
            self.angleRulerView?.removeFromSuperview()
            self.angleRulerView = nil
            setMoveable(true)
            self.shpaeImageView.image = self.originalImage
            let bigBounds = CGRect.init(x: 0, y: 0, width:getSizeToFitScreen().width, height:getSizeToFitScreen().height)
            self.bounds = bigBounds
            self.shpaeImageView.transform = CGAffineTransform.identity
            isRotatedClip = false
            self.baseViewangle = nil
            break
        case SubActionType.rotateCancel.rawValue:
            selectedActionType = type
            NotificationCenter.default.removeObserver(self.angleRulerView as Any)
            self.angleRulerView?.removeFromSuperview()
            self.angleRulerView = nil
            setMoveable(true)
            break
        case OperationType.cancel.rawValue:
            selectedActionType = type
            self.pasteBlock!(UIImage(),CGRect.zero)
            self.removeAllEvents()
            break
        case OperationType.reset.rawValue:
            self.reset()
            break
        case SubActionType.clip.rawValue:
            selectedActionType = type
            if !self.freePathView.isHidden {
                self.cropFrreShape()
            }else{
                self.cropShpae()
            }
            saveToUndoPackage(image: self.shpaeImageView.image!)
            undoIndex = undoPackage.count - 1
            self.sideMenu?.undoButton.isEnabled = true
            self.sideMenu?.redoButton.isEnabled = false
            self.sideMenu?.rotateRatioButton.isHidden = true
            setMoveable(true)
            isRotatedClip = false
            break
        case OperationType.undo.rawValue:
            if !self.freePathView.isHidden {
                self.freePathView.undoPath(sender: (self.sideMenu?.undoButton)!)
            }else{
                undoAction(sender)
            }
            break
        case OperationType.redo.rawValue:
            redoAction(sender)
            break
        case OperationType.paste.rawValue:
            pasteImage()
            break
        default:
            selectedActionType = type
            self.addCropView(type:type)
        }
    }
    
    func pasteImage() {
        var pasteImage:UIImage?
        self.shpaeImageView.image = UIImage.imageRotatedByDegrees(self.shpaeImageView.image!, degrees: (baseViewangle != nil) ? baseViewangle! : 0)
        pasteImage = UIImage.imageWithImage(self.shpaeImageView.image!, scaledToSize: self.shpaeImageView.frame.size, inRect:CGRect.init(origin: CGPoint.zero, size: self.shpaeImageView.frame.size))
        let origin:CGPoint = self.convert(self.shpaeImageView.center, to: self.superview)
        let cropSize:CGSize = (pasteImage?.size)!
        var cropFrame:CGRect = CGRect.init(origin:CGPoint.init(x: origin.x - (cropSize.width/2), y: origin.y - (cropSize.height/2)), size:cropSize)
        if cropFrame.origin.x < 0 || cropFrame.origin.y < 0 {
            cropFrame.origin.x = 0 ; cropFrame.origin.y = 0
        }
        let currentRect:CGSize = getCurrentScreenSize(moveSize: (self.moveableArea?.size)!)
        if cropFrame.size.width >  currentRect.width {
            cropFrame.size.width = currentRect.width
        }
        if cropFrame.size.height > currentRect.height  {
            cropFrame.size.height = currentRect.height
        }
        if let block = self.pasteBlock {
            block(pasteImage!,cropFrame)
        }
        self.removeAllEvents()
    }
    
}
// MARK: - UNDO & REDO -
extension WPBaseEditorView {
    
    func saveToUndoPackage(image:UIImage) {
        if (self.sideMenu?.redoButton?.isEnabled)! {
            self.undoPackage.removeSubrange(Range.init(NSRange.init(location:undoPackage.count - self.stepBystep, length: self.stepBystep))!)
            self.stepBystep  = 0
        }
        self.undoPackage.append((image,UIApplication.shared.statusBarOrientation,self.shpaeImageView.transform,self.center))
        self.sideMenu?.redoButton.isEnabled = false
    }
    
    func undoAction(_ sender:UIButton) {
        self.sideMenu?.redoButton?.isEnabled = true
        self.stepBystep += 1
        if self.stepBystep == undoPackage.count   {
            sender.isEnabled = false
        }
        updateUI(undoObject:undoPackage[undoPackage.count - self.stepBystep])
        undoIndex = undoPackage.count - self.stepBystep
    }
    
    func redoAction(_ sender:UIButton) {
        
        self.sideMenu?.undoButton?.isEnabled = true
        self.stepBystep -= 1
        if self.stepBystep == 1 {
            sender.isEnabled = false
        }
        
        updateUI(undoObject: undoPackage[undoPackage.count - self.stepBystep])
        undoIndex = undoPackage.count - self.stepBystep
    }
    
    func updateUI(undoObject:(UIImage,UIInterfaceOrientation,CGAffineTransform,CGPoint)) {
        var isMatch:Bool = false
        self.shpaeImageView.image = undoObject.0
        self.shpaeImageView.transform = undoObject.2
        if let angleRuler = self.angleRulerView {
            angleRuler.angleCollectionView.transform = CGAffineTransform.init(rotationAngle: acos(undoObject.2.a))
        }
        self.baseViewangle = acos(self.shpaeImageView.transform.a)
        if undoObject.1.isPortrait == UIApplication.shared.statusBarOrientation.isPortrait {
            isMatch = true
        }
        if undoObject.1.isLandscape == UIApplication.shared.statusBarOrientation.isLandscape {
            isMatch = true
        }
        if isMatch {
            let undoCenter:CGPoint = undoObject.3
            self.center = undoCenter
        }else{
            self.center = (superview?.center)!
        }
        self.bounds = CGRect.init(origin: CGPoint.zero, size:getSizeToFitScreen(undoObject.0))
        self.sideMenu?.resetButton.isEnabled = (self.sideMenu?.undoButton.isEnabled)!
        
    }
    
}
//MARK: - ADD VIEW -
extension WPBaseEditorView {
    // add top menu
    func loadsideMenuView() {
        
        self.sideMenu = WPSideMenu.loadsideMenu(CGRect.init(x:0, y:UIScreen.main.bounds.size.height - 64, width: UIScreen.main.bounds.size.width, height:64))
        superview?.insertSubview(self.sideMenu!, aboveSubview: self)
        self.sideMenu?.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeStatusBarOrientation), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarOrientation), name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation, object: nil)
        
    }
    @objc func didChangeStatusBarOrientation() {
        self.moveableArea = self.moveableArea?.applyingInversed()
        self.updateLayout()
        if let side = self.sideMenu {
            side.frame = CGRect.init(x:0, y:UIScreen.main.bounds.height-64, width:UIScreen.main.bounds.width, height:64)
        }
    }
    @objc func willChangeStatusBarOrientation() {
        self.willChangeFrame = self.frame
        if let crop  = self.currentCropView {
            crop.willChangeFrame = crop.frame
        }
    }
    
    
    func addCropView(type:String) {
        
        setMoveable(false)
        isCut = false
        self.sideMenu?.rotateRatioButton.isHidden = true
        
        if type.isEqual(SubActionType.Free_S.rawValue)||type.isEqual(SubActionType.Free_C.rawValue) {
            if let cropView = self.currentCropView {
                cropView.drawBackgroudView?.removeFromSuperview()
                cropView.removeFromSuperview()
                self.currentCropView = nil
            }
            self.freePathView.isHidden = false
            self.freePathView.baseImage = self.originalImage
            self.freePathView.sideMenu_undoButton = self.sideMenu?.undoButton
            self.freePathView.sideMenu_clipButton = self.sideMenu?.doneButton
            self.freePathView.freePathName = NSString.init(string: type)
            self.sideMenu?.doneButton.isEnabled = false
            self.sideMenu?.closePolygonCountView()
        }else{
            
            if let cropView = self.currentCropView {
                cropView.initShapeLayout(type: type)
                self.sideMenu?.rotateRatioButton.isHidden = true
                if !self.freePathView.isHidden {
                    self.freePathView.isHidden = true
                }
                if !type.isEqual(SubActionType.crop_polygon.rawValue) {
                    cropView.polygonLayer.removeFromSuperlayer()
                    self.sideMenu?.closePolygonCountView()
                }
                if type.isEqual(SubActionType.crop_43.rawValue) || type.isEqual(SubActionType.crop_169.rawValue) || type.isEqual(SubActionType.crop_image.rawValue) || type.isEqual(SubActionType.crop_canvas.rawValue) {
                    self.sideMenu?.rotateRatioButton.isHidden = false
                }
                return
            }else{
                self.sideMenu?.resetButton.isEnabled = true
                self.sideMenu?.undoButton.isEnabled = false
                self.sideMenu?.redoButton.isEnabled = false
                self.freePathView.isHidden = true
                self.sideMenu?.doneButton.isEnabled = true
                if type.isEqual(SubActionType.crop_43.rawValue) || type.isEqual(SubActionType.crop_169.rawValue) || type.isEqual(SubActionType.crop_image.rawValue) || type.isEqual(SubActionType.crop_canvas.rawValue) {
                    self.sideMenu?.rotateRatioButton.isHidden = false
                }
                isRotatedClip = false
                if let angle = self.baseViewangle {
                    self.bounds = CGRect.init(origin: CGPoint.zero, size: self.shpaeImageView.frame.size)
                    self.shpaeImageView.frame = CGRect.init(origin: CGPoint.zero, size: self.bounds.size)
                    self.shpaeImageView.image = UIImage.imageRotatedByDegrees(self.shpaeImageView.image!, degrees: angle)
                    self.shpaeImageView.transform = CGAffineTransform.identity
                    isRotatedClip = true
                }
                self.currentCropView = WPCropEditorView.loadNibFileToCropView(onTheSuperView: self)
                self.currentCropView?.initShapeLayout(type: type)
            }
        }
    }
    
    @objc  func add_Count_Polygon_Action(_ sender:UIButton) {
        self.currentCropView?.addAndDecrease_Polygon_Action(sender)
    }
    // add rotationview
    func addRotationView() {
        var sourc:[Int] = Array()
        for index in 0..<20 {
            sourc.append(index*18)
        }
        self.angleRulerView = WPAngleRuler.init(rulerDataSource: sourc, rotatedView: self)
        angleRulerView?.delegate = self
        self.superview?.insertSubview(self.angleRulerView!, belowSubview: self.sideMenu!)
    }
    
    
    // add free path clip View to be main view
    func cropFrreShape() {
        self.shpaeImageView.lastPath = self.freePathView.getCurrentPath()
        self.freePathView.isHidden = true
        self.shpaeImageView.image = self.shpaeImageView.pasteImage()
        let cutImage:UIImage = (self.shpaeImageView.cuting())
        let convertFrame = self.convert((self.shpaeImageView.lastPath?.bounds)!, to: self.superview)
        self.frame = convertFrame
        self.shpaeImageView.image = cutImage
        self.shpaeImageView.backgroundColor = UIColor.clear
        self.shpaeImageView.transform = CGAffineTransform.identity
        isCut = true
        baseViewangle = nil
    }
    
    // add clip view to superView later operation
    func cropShpae(){
        
        self.currentCropView?.removeFromSuperview()
        let sourceImageRef: CGImage = self.shpaeImageView.pasteImage().cgImage!
        isCut = true
        let newCGImage :CGImage = sourceImageRef.cropping(to:(self.currentCropView?.frame)!)!
        let newImage:UIImage = UIImage.init(cgImage: newCGImage)
        self.shpaeImageView.image = newImage
        self.shpaeImageView.lastPath = self.currentCropView?.crop_shapePath
        let cutImage:UIImage = (self.shpaeImageView.cuting())
        self.shpaeImageView.image = cutImage
        let convertPoint:CGPoint = self.convert((self.currentCropView?.center)!, to: self.superview)
        var convertSize:CGSize = cutImage.size
        if (self.currentCropView?.crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue))! {
            convertSize = cutImage.size
        }
        self.bounds = CGRect.init(origin: CGPoint.zero, size: convertSize)
        self.center = convertPoint
        self.currentCropView?.drawBackgroudView?.removeFromSuperview()
        self.currentCropView?.removeFromSuperview()
        self.currentCropView = nil
        self.shpaeImageView.transform = CGAffineTransform.identity
        baseViewangle = nil
        
        
    }
    // over method
    func removeAllEvents() {
        self.sideMenu?.rotateRatioButton.isHidden = true
        self.sideMenu?.removeFromSuperview()
        self.angleRulerView?.removeFromSuperview()
        DispatchQueue._onceTracker = [String]()
        NotificationCenter.default.removeObserver(self)
        self.removeFromSuperview()
        selectedActionType = OperationType.unknown.rawValue
        self.angleRulerView = nil
        self.baseViewangle = nil
        isCut = false
        isRotatedClip = false
    }
    
    func reset() {
        self.undoPackage.removeAll()
        undoIndex = 0
        self.sideMenu?.redoButton.isEnabled = false
        self.sideMenu?.undoButton.isEnabled = false
        self.sideMenu?.rotateRatioButton.isHidden = true
        if let cropView = self.currentCropView {
            cropView.drawBackgroudView?.removeFromSuperview()
            cropView.removeFromSuperview()
            self.currentCropView = nil
        }
        if let editorImage = self.originalImage {
            self.shpaeImageView.image = editorImage
            self.bounds = CGRect.init(origin: CGPoint.zero, size: getSizeToFitScreen())
            self.center = (superview?.center)!
            self.shpaeImageView.transform = CGAffineTransform.identity
            saveToUndoPackage(image: editorImage)
        }
        if !self.freePathView.isHidden {
            self.freePathView.isHidden = true
        }
        if self.angleRulerView != nil {
            self.angleRulerView?.angleCollectionView.transform = CGAffineTransform.identity
            self.angleRulerView?.lastclockwise_Angle = 0
            self.angleRulerView?.removeFromSuperview()
            self.angleRulerView = nil
        }
        self.baseViewangle = nil
        setMoveable(true)
        isCut = false
    }
    
}

class WPShapeImageView: UIImageView {
    
    public var lastPath:UIBezierPath?
    // free path clip image
    public func cuting() -> UIImage {
        
        var imgSize:CGSize = CGSize.zero
        imgSize = (self.frame.size)
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 1)
        lastPath?.addClip()
        self.image?.draw(at: CGPoint.zero)
        let newImage2  = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 1)
        let sourceImageRef: CGImage = (newImage2!.cgImage!)// next In accordance with the path bouns .clip image szie
        let newCGImage :CGImage = sourceImageRef.cropping(to:(self.lastPath?.bounds)!)!
        let newImage:UIImage = UIImage.init(cgImage: newCGImage)
        return newImage
    }
    
    func pasteImage() -> UIImage {
        let imageSize = self.bounds.size
        var screen:UIView = self
        if !isCut {
            screen = self.superview!
        }
        UIGraphicsBeginImageContextWithOptions(imageSize, false,1)
        screen.layer.render(in: UIGraphicsGetCurrentContext()!)
        let layerImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return layerImage
    }
    
}



