//
//  WPCropEditorView.swift
//  WPImageEditor2
//
//  Created by pow on 2017/11/9.
//  Copyright © 2017年 pow. All rights reserved.
//

import UIKit

// FIXME: do make clip drawing path
public class WPCropEditorView: UIView {
    
    // drawing  path type name
    var crop_shapeName:String = ""
    // drawing path of self
    var crop_shapePath:UIBezierPath = UIBezierPath()
    // spaceing
    let space:CGFloat = 1
    //  setup min value  count  of the polygon
    var polygonCount = 5
    // degree measure of the polygon
    var degreeMeasure:Double?
    /*------------------------------------------------------------------*/
    /**XIB file in property **/
    @IBOutlet weak var controlSizeButton_0: UIButton!// left top
    @IBOutlet weak var controlSizeButton_2: UIButton!// left bottom
    @IBOutlet weak var controlSizeButton_5: UIButton!// right top
    @IBOutlet weak var controlSizeButton_7: UIButton!// right bottom
    /**XIB file in internal hidden property **/
    @IBOutlet weak var leftBottom: UILabel!
    @IBOutlet weak var left_leftBottom: UILabel!
    @IBOutlet weak var rightBottom: UILabel!
    @IBOutlet weak var right_rightBottom: UILabel!
    @IBOutlet weak var topRight: UILabel!
    @IBOutlet weak var right_topBottom: UILabel!
    @IBOutlet weak var leftTop: UILabel!
    @IBOutlet weak var left_TopBottom: UILabel!
    var isMove:Bool?                          // is out edge
    var edgePoint:CGPoint = CGPoint.zero      // edge point
    var currentFrame:CGRect = CGRect.zero // current frame
    var toScale:Bool = true
    var lockX:CGFloat?
    var lockY:CGFloat?
    var lockWidth:CGFloat = 0
    var lockheight:CGFloat = 0
    var maxRatio:CGFloat?
    var polygonLayer:CAShapeLayer = CAShapeLayer()
    var drawBackgroudView:WPDrawingView?
    var willChangeFrame:CGRect = CGRect.zero
    
    public override var bounds: CGRect {
        didSet{
            self.setNeedsLayout()
        }
    }
    
    override  public func draw(_ rect: CGRect) {
        crop_shapePath.removeAllPoints()
        // update out side obscure view
        self.draw_BaseView_Outside_BezierPath()
        // main view path update
        switch crop_shapeName {
        case SubActionType.Cercle.rawValue:
            crop_shapePath = UIBezierPath.init(arcCenter:CGPoint.init(x: self.frame.width/2, y: self.frame.height/2), radius:self.frame.width/2-space, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: true)
            break
        case SubActionType.Rectangle.rawValue:
            crop_shapePath = UIBezierPath(rect: CGRect.init(x: 0, y: 0, width: rect.width, height: rect.height))
            break
        case SubActionType.Triangle.rawValue:
            crop_shapePath.move(to: CGPoint.init(x: rect.width-space, y: rect.height-space))
            crop_shapePath.addLine(to: CGPoint.init(x: rect.width/2, y:space))
            crop_shapePath.addLine(to: CGPoint.init(x: space, y:rect.height-space))
            crop_shapePath.addLine(to: CGPoint.init(x:  rect.width-space, y:rect.height-space))
            break
        case SubActionType.crop_43.rawValue:
            crop_shapePath = UIBezierPath.init(rect: rect)
            break
        case SubActionType.crop_169.rawValue:
            crop_shapePath = UIBezierPath.init(rect: rect)
            break
        case SubActionType.crop_image.rawValue:
            crop_shapePath = UIBezierPath.init(rect: rect)
            break
        case SubActionType.crop_canvas.rawValue:
            crop_shapePath = UIBezierPath.init(rect: rect)
            break
        case SubActionType.Oval.rawValue:
            crop_shapePath = UIBezierPath.init(ovalIn: CGRect.init(x: space, y: space, width: rect.width-space*2, height: rect.height-space*2))
            break
        case SubActionType.crop_polygon.rawValue:
            crop_shapePath = getPolygonPath(rect: rect)
            polygonLayer.lineWidth = 2
            polygonLayer.strokeColor = UIColor.orange.cgColor
            polygonLayer.fillColor = UIColor.clear.cgColor
            polygonLayer.bounds = crop_shapePath.bounds
            polygonLayer.frame = CGRect.init(x: (rect.width - crop_shapePath.bounds.width)/2, y: (rect.height - crop_shapePath.bounds.height)/2, width: crop_shapePath.bounds.width, height: crop_shapePath.bounds.height)
            polygonLayer.path = crop_shapePath.cgPath
            break
        case SubActionType.crop_free.rawValue:
            crop_shapePath = UIBezierPath(rect: CGRect.init(x: 0, y: 0, width:rect.size.width, height:rect.height))
            break
        default:
            print("not type")
        }
        if !crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue) {
            UIColor.orange.setStroke()
            crop_shapePath.lineWidth = 2
            crop_shapePath.stroke()
        }
    }
    
    
    override  public func layoutSubviews() {
        self.drawBackgroudView?.frame = CGRect.init(origin: CGPoint.zero, size: (self.superview?.bounds.size)!)
        self.setNeedsDisplay()
    }
    // init loading nib file to be WPCropEditorView class object
    class func loadNibFileToCropView(onTheSuperView:WPBaseEditorView)->WPCropEditorView {
        
        var  crop:WPCropEditorView?
        _ =  UINib.init(nibName:nibName, instantiate: WPCropEditorView.self) {
            (view) in
            crop = view as? WPCropEditorView
        }
        isCut = false
        crop?.drawBackgroudView = WPDrawingView(frame:onTheSuperView.bounds)
        onTheSuperView.addSubview((crop?.drawBackgroudView!)!)
        onTheSuperView.addSubview(crop!)
        return crop!
    }
    // init shape layout
    func initShapeLayout(type:String) {
        
        crop_shapeName = type
        self.toScale = true
        switch type {
        case SubActionType.crop_free.rawValue:
            self.toScale = false
            self.bounds = CGRect.init(origin: CGPoint.zero, size: (self.superview?.frame.size)!)
            break
        case SubActionType.crop_image.rawValue:
            let baseView:WPBaseEditorView = (self.superview as! WPBaseEditorView)
            maxRatio = max((baseView.originalImage?.size.width)!, (baseView.originalImage?.size.height)!)/min ((baseView.originalImage?.size.width)!, (baseView.originalImage?.size.height)!)
            let proSize:CGSize = baseView.bounds.size.proportionSize(p: maxRatio!)
            self.bounds = CGRect.init(origin: CGPoint.zero, size:proSize)
            break
        case SubActionType.crop_canvas.rawValue:
            let baseView:WPBaseEditorView = (self.superview as! WPBaseEditorView)
            maxRatio = max((baseView.moveableArea?.size.width)!, (baseView.moveableArea?.size.height)!)/min ((baseView.moveableArea?.size.width)!, (baseView.moveableArea?.size.height)!)
            let proSize:CGSize = baseView.bounds.size.proportionSize(p: maxRatio!)
            self.bounds = CGRect.init(origin: CGPoint.zero, size:proSize)
            break
        case SubActionType.Oval.rawValue:
            self.toScale = false
            self.bounds = CGRect.init(origin: CGPoint.zero, size:(self.superview?.frame.size)!)
            break
        case SubActionType.crop_polygon.rawValue:
            let minSize = min((self.superview?.frame.size.width)!, (self.superview?.frame.size.height)!)
            self.layer.addSublayer(polygonLayer)
            self.bounds = CGRect.init(origin: CGPoint.zero, size:CGSize.init(width:minSize, height:  minSize))
            break
        case SubActionType.crop_43.rawValue:
            self.bounds = CGRect.init(origin: CGPoint.zero, size: (self.superview?.frame.size)!)
            let proSize = self.frame.size.proportionSize(p: 4/3)
            maxRatio = 4/3
            self.bounds = CGRect.init(origin: CGPoint.zero, size:CGSize.init(width: proSize.width, height: proSize.height))
            break
        case SubActionType.crop_169.rawValue:
            self.bounds = CGRect.init(origin: CGPoint.zero, size: (self.superview?.frame.size)!)
            let proSize = self.frame.size.proportionSize(p: 16/9)
            maxRatio = 16/9
            self.bounds = CGRect.init(origin: CGPoint.zero, size:CGSize.init(width: proSize.width, height: proSize.height))
            break
        default:
            let minSize:CGFloat = min((self.superview?.frame.width)!, (self.superview?.frame.height)!)
            self.bounds = CGRect.init(origin: CGPoint.zero, size:CGSize.init(width: minSize, height: minSize))
        }
        
        self.center = CGPoint.init(x: (self.superview?.frame.width)!/2, y: (self.superview?.frame.height)!/2)
        
        
    }
    // MARK: - rotateRatio -
    func rotateRatio() {
        let scaleSize:CGSize = self.superview!.frame.size
        let baseView:WPBaseEditorView = (self.superview as! WPBaseEditorView)
        var maxValue:CGFloat?, minValue:CGFloat?
        if crop_shapeName.isEqual(SubActionType.crop_169.rawValue) {
            maxValue = 16
            minValue = 9
        }else if crop_shapeName.isEqual(SubActionType.crop_43.rawValue) {
            maxValue = 4
            minValue = 3
        }else if crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue) {
            maxValue =  max((baseView.moveableArea?.size.width)!, (baseView.moveableArea?.size.height)!)
            minValue = min((baseView.moveableArea?.size.width)!, (baseView.moveableArea?.size.height)!)
        }else if crop_shapeName.isEqual(SubActionType.crop_image.rawValue) {
            maxValue =  max((baseView.originalImage?.size.width)!, (baseView.originalImage?.size.height)!)
            minValue = min((baseView.originalImage?.size.width)!, (baseView.originalImage?.size.height)!)
        }
        
        if let ratio = maxRatio {
            maxRatio = ratio == maxValue!/minValue! ? minValue!/maxValue! : maxValue!/minValue!
            let proSize:CGSize = (scaleSize.proportionSize(p:maxRatio!))
            self.bounds = CGRect.init(origin: CGPoint.zero, size:CGSize.init(width:proSize.width, height: proSize.height))
            self.center = CGPoint.init(x: (superview?.frame.width)!/2, y: (superview?.frame.height)!/2)
            
        }
        
    }
    
    override  public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isMove = false
        let touch:UITouch  = touches.first!
        let point = touch.location(in: superview)
        if self.frame.contains(point) {
            edgePoint = touch.location(in: self)
            isMove = true
        }
    }
    
    override  public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !isMove! {
            return
        }
        let touch = touches.first
        var point  = touch?.location(in: superview)
        point?.x += self.frame.size.width/2 - edgePoint.x
        point?.y += self.frame.size.height/2 - edgePoint.y
        if (point?.x)! < self.frame.size.width/2  {
            point?.x = self.frame.size.width/2
        }
        if (point?.y)! < self.frame.size.height/2  {
            point?.y = self.frame.size.height/2
        }
        if (point?.x)! > (superview?.frame.size.width)! - self.frame.size.width / 2 {
            point?.x = (superview?.frame.size.width)! - self.frame.size.width / 2
        }
        if (point?.y)! > (superview?.frame.size.height)! - self.frame.size.height / 2 {
            point?.y = (superview?.frame.size.height)! - self.frame.size.height / 2
        }
        self.center = point!
        self.setNeedsDisplay()
    }
    
    
    
}
// FIXME: update base editor view draw
extension WPCropEditorView{
    
    
    func draw_BaseView_Outside_BezierPath() {
        
        let outSidePath = UIBezierPath()
        
        let super_X:CGFloat = 0
        let super_Y:CGFloat = 0
        let super_W = (superview?.frame.size.width)!
        let super_H = (superview?.frame.size.height)!
        let self_X = self.frame.origin.x
        let self_Y = self.frame.origin.y
        let self_W = self.frame.size.width
        let self_H = self.frame.size.height
        
        outSidePath.move(to: CGPoint.init(x:super_X, y:super_Y))
        outSidePath.addLine(to: CGPoint.init(x:self_X, y:self_Y))
        outSidePath.addLine(to: CGPoint.init(x:self_X+self_W, y:self_Y))
        outSidePath.addLine(to: CGPoint.init(x: super_X+super_W, y: super_Y))
        outSidePath.addLine(to: CGPoint.init(x: super_X, y: super_Y))
        
        outSidePath.move(to: CGPoint.init(x: super_X, y: super_H))
        outSidePath.addLine(to: CGPoint.init(x:self_X, y: self_H+self_Y))
        outSidePath.addLine(to: CGPoint.init(x:self_X, y:self_Y))
        outSidePath.addLine(to: CGPoint.zero)
        outSidePath.addLine(to: CGPoint.init(x: super_X, y: super_H+super_Y))
        
        outSidePath.move(to: CGPoint.init(x: super_X, y: super_Y+super_H))
        outSidePath.addLine(to: CGPoint.init(x:self_X, y:self_Y+self_H))
        outSidePath.addLine(to: CGPoint.init(x:self_X+self_W, y:self_Y+self_H))
        outSidePath.addLine(to: CGPoint.init(x: super_X+super_W, y: super_Y+super_H))
        outSidePath.addLine(to: CGPoint.init(x: super_X, y: super_Y+super_H))
        
        outSidePath.move(to: CGPoint.init(x: super_X+super_W, y: super_Y+super_H))
        outSidePath.addLine(to: CGPoint.init(x:self_X+self_W, y: self_H+self_Y))
        outSidePath.addLine(to: CGPoint.init(x: self_W+self_X, y: self_Y))
        outSidePath.addLine(to: CGPoint.init(x: super_W+super_X, y: super_Y))
        outSidePath.addLine(to: CGPoint.init(x: super_X+super_W, y: super_Y+super_H))
        
        self.drawBackgroudView?.drawPath = outSidePath
        
    }
    
    
    
    
}
// FIXME: make add polygon
extension WPCropEditorView{
    
    func getPolygonPath(rect:CGRect) -> UIBezierPath {
        if self.degreeMeasure == nil {
            degreeMeasure = degree(count:CGFloat(polygonCount))
        }
        crop_shapePath.removeAllPoints()
        let beginPoint:CGPoint = CGPoint.init(x: rect.size.width/2, y:0)
        let boundsCenter = CGPoint.init(x: rect.size.width/2, y:rect.size.height/2)
        var endPoint:CGPoint = pointRotatedAroundAnchorPoint(point:beginPoint,anchorPoint:boundsCenter,angle:degreeMeasure!)
        crop_shapePath.move(to:beginPoint)
        for _ in 0..<polygonCount {
            endPoint = pointRotatedAroundAnchorPoint(point:crop_shapePath.currentPoint, anchorPoint: boundsCenter, angle:degreeMeasure!)
            crop_shapePath.addLine(to: endPoint)
        }
        return crop_shapePath
    }
    func degree(count:CGFloat) ->Double {
        let clipLength:CGFloat = 100*4.13
        let cercleLength:CGFloat = 100*CGFloat(Double.pi)
        let length:CGFloat = clipLength / count
        let measureLength:CGFloat = 360/cercleLength
        let degree:Double = Double(length/measureLength)
        return  Double.pi*degree/180
    }
    func addAndDecrease_Polygon_Action(_ sender: UIButton) {
        // update frame
        if sender.tag == 345 {// add
            polygonCount += 1
        }else{//Decrease
            polygonCount -= 1
        }
        if polygonCount>20 {
            polygonCount = 20
        }
        if polygonCount<5 {
            polygonCount = 5
        }
        degreeMeasure = degree(count:CGFloat(polygonCount))
        self.setNeedsDisplay()
    }
    func pointRotatedAroundAnchorPoint(point:CGPoint,anchorPoint:CGPoint,angle:Double) ->CGPoint{
        let x:CGFloat = (point.x-anchorPoint.x)*CGFloat(cos(angle))-(point.y-anchorPoint.y)*CGFloat(sin(angle)) + anchorPoint.x
        let y:CGFloat = (point.x-anchorPoint.x)*CGFloat(sin(angle)) + (point.y-anchorPoint.y)*CGFloat(cos(angle))+anchorPoint.y
        return CGPoint(x:x, y:y)
    }
    
    
    
}
// FIXME: ---------    WPDrawingView       -------------------
class WPDrawingView: UIView {
    
    var drawPath:UIBezierPath = UIBezierPath() {
        didSet{
            self.setNeedsDisplay()
        }
    }
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func draw(_ rect: CGRect) {
        UIColor.init(red: 102/255, green: 102/255, blue: 102/255, alpha: 0.7).setFill()
        drawPath.fill()
    }
    
    
}
extension WPCropEditorView{
    
    
    //MARK: change view size gesture action
    override  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // handle -9
        currentFrame = self.frame
        if lockX != nil {lockX = nil}
        if lockY != nil {lockY = nil}
        lockX = self.frame.origin.x
        lockY = self.frame.origin.y
        lockheight = 0
        lockWidth = 0
        return true
    }
    
    //MARK: octagonal location frre size
    @IBAction func controlSizeButton_collectionManage_Gesture(_ sender: UIPanGestureRecognizer) {
        
        
        var sP:CGPoint = CGPoint.zero;//  size point
        var aP:CGPoint = CGPoint.zero //  appear point
        
        if (sender.view?.isEqual(self.controlSizeButton_0))! { // left top
            
            sP = sender.location(in: self.superview)
            
            sP.x  = currentFrame.origin.x -  sP.x
            
            sP.y  = currentFrame.origin.y -  sP.y
            // handle -16 to scale size
            if self.toScale {
                if sP.x > sP.y {sP.y = sP.x}
                if sP.y > sP.x {sP.x = sP.y}
            }
            aP.x = currentFrame.origin.x - sP.x
            aP.y = currentFrame.origin.y - sP.y
            
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_2))! {// left bottom
            
            sP =  sender.location(in: self.superview)
            
            sP.x = currentFrame.origin.x - sP.x
            
            sP.y = sP.y - currentFrame.origin.y - currentFrame.height
            if self.toScale {
                if sP.x > sP.y {sP.y = sP.x}
                if sP.y > sP.x {sP.x = sP.y}
            }
            aP.y = currentFrame.origin.y
            
            aP.x = currentFrame.origin.x - sP.x
            
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_5))! {// right top
            
            
            sP =  sender.location(in: self.superview)
            
            sP.x = sP.x - currentFrame.origin.x - currentFrame.width
            
            sP.y = currentFrame.origin.y - sP.y
            if self.toScale {
                if sP.x > sP.y {sP.y = sP.x}
                if sP.y > sP.x {sP.x = sP.y}
            }
            aP.y = currentFrame.origin.y - sP.y
            
            aP.x = currentFrame.origin.x
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_7))! {// right bottom
            
            
            sP = sender.location(in: self.superview)
            
            aP = currentFrame.origin
            
            sP.x = sP.x - currentFrame.size.width - currentFrame.origin.x
            
            sP.y = sP.y - currentFrame.size.height - currentFrame.origin.y
            if self.toScale {
                if sP.x > sP.y {sP.y = sP.x}
                if sP.y > sP.x {sP.x = sP.y}
            }
            
            
        }
        self.changeViewSizeEDGE(sP , ap:aP)
    }
    /**
     centralized processing view  size change
     - parameter sp size point
     - parameter ap appear point
     - parameter orientation
     **/
    func changeViewSizeEDGE(_ sp:CGPoint,ap:CGPoint) {
        var moveFrame = CGRect.zero
        moveFrame.origin.x = ap.x
        moveFrame.origin.y = ap.y
        moveFrame.size.width = currentFrame.size.width + sp.x
        moveFrame.size.height = currentFrame.size.height + sp.y
        if crop_shapeName.isEqual(SubActionType.crop_43.rawValue)||crop_shapeName.isEqual(SubActionType.crop_169.rawValue)||crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue)||crop_shapeName.isEqual(SubActionType.crop_image.rawValue) {
            moveFrame.size = moveFrame.size.proportionSize(p: maxRatio!)
        }
        
        if moveFrame.size.width <= 100 {
            moveFrame.size.width = 100
            return
        }else if moveFrame.size.height <= 100 {
            moveFrame.size.height = 100
            return
        }
        
        
        /**
         size out handle
         */
        if moveFrame.origin.x < lockX! && moveFrame.origin.x > 0 {
            
            lockWidth = (self.superview?.frame.width)! - moveFrame.origin.x - moveFrame.size.width
        }
        if moveFrame.origin.y < lockY! && moveFrame.origin.y > 0 {
            
            lockheight = (self.superview?.frame.height)! - moveFrame.origin.y - moveFrame.size.height
        }
        
        if moveFrame.origin.x < 0 {
            
            moveFrame.origin.x = 0
            moveFrame.size.width = (self.superview?.frame.width)! - lockWidth
            if crop_shapeName.isEqual(SubActionType.Cercle.rawValue) || crop_shapeName.isEqual(SubActionType.Triangle.rawValue)||crop_shapeName.isEqual(SubActionType.Rectangle.rawValue)||crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue) {
                moveFrame.size.height = moveFrame.size.width
            }else if crop_shapeName.isEqual(SubActionType.crop_43.rawValue) || crop_shapeName.isEqual(SubActionType.crop_169.rawValue) || crop_shapeName.isEqual(SubActionType.crop_image.rawValue)||crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue){
                moveFrame.size.height =  moveFrame.size.proportionSize(p: maxRatio!).height
            }
            
        }
        if moveFrame.origin.y < 0 {
            moveFrame.origin.y = 0
            moveFrame.size.height = (self.superview?.frame.height)! - lockheight
            if crop_shapeName.isEqual(SubActionType.Cercle.rawValue) || crop_shapeName.isEqual(SubActionType.Triangle.rawValue)||crop_shapeName.isEqual(SubActionType.Rectangle.rawValue)||crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue) {
                moveFrame.size.width = moveFrame.size.height
            }else if crop_shapeName.isEqual(SubActionType.crop_43.rawValue) || crop_shapeName.isEqual(SubActionType.crop_169.rawValue) || crop_shapeName.isEqual(SubActionType.crop_image.rawValue)||crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue){
                moveFrame.size.width =  moveFrame.size.proportionSize(p: maxRatio!).width
            }
        }
        if moveFrame.size.width + moveFrame.origin.x  > (self.superview?.frame.size.width)!  {
            moveFrame.size.width = (self.superview?.frame.size.width)! - moveFrame.origin.x
            if crop_shapeName.isEqual(SubActionType.Cercle.rawValue) || crop_shapeName.isEqual(SubActionType.Triangle.rawValue)||crop_shapeName.isEqual(SubActionType.Rectangle.rawValue)||crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue) {
                moveFrame.size.height = moveFrame.size.width
            }else if crop_shapeName.isEqual(SubActionType.crop_43.rawValue) || crop_shapeName.isEqual(SubActionType.crop_169.rawValue) || crop_shapeName.isEqual(SubActionType.crop_image.rawValue)||crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue){
                moveFrame.size.height =  moveFrame.size.proportionSize(p: maxRatio!).height
            }
        }
        if moveFrame.size.height + moveFrame.origin.y  > (self.superview?.frame.size.height)!  {
            
            moveFrame.size.height = (self.superview?.frame.size.height)! - moveFrame.origin.y
            if crop_shapeName.isEqual(SubActionType.Cercle.rawValue) || crop_shapeName.isEqual(SubActionType.Triangle.rawValue)||crop_shapeName.isEqual(SubActionType.Rectangle.rawValue)||crop_shapeName.isEqual(SubActionType.crop_polygon.rawValue) {
                moveFrame.size.width = moveFrame.size.height
            }else if crop_shapeName.isEqual(SubActionType.crop_43.rawValue) || crop_shapeName.isEqual(SubActionType.crop_169.rawValue) || crop_shapeName.isEqual(SubActionType.crop_image.rawValue)||crop_shapeName.isEqual(SubActionType.crop_canvas.rawValue){
                moveFrame.size.width =  moveFrame.size.proportionSize(p: maxRatio!).width
            }
            
        }
        self.frame = moveFrame
    }
    
}


