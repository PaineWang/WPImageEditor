//
//  WPImageManger.swift
//  drawCenterView
//
//  Created by WANG on 2017/9/14.
//  Copyright © 2017年 WANG. All rights reserved.
//
/**
 
 -state-
 
 The current effect is curve and line, cut and finished. Specify shape cutting completion.
 1. Curve cutting, can not be cancelled after completion
 2.The curve is a point-to-point operation
 3.The line is a drag and drop operation
 4.Choose a curve or a straight line. You can't scale
 
 **/

import UIKit

// shape cell selector then notifation
let kNotifationSlectorCellPath = "kNotifationSlectorCellPath"
// setting all view top edge
//BUG 2: didChnageDeviceOrientation change  base View size
var baseViewLastFrame:CGRect?
var clipViewLastFrame:CGRect?

var baseViewangle = 0.0
var clipViewangle = 0.0
var orientationCode:Int?
var gestures:[UIGestureRecognizer]?

var isCut:Bool = false

// image super block
typealias imageblock = (UIImage,CGRect)->Void
class WPImageManger: UIView ,UIGestureRecognizerDelegate{
    
    
    var currentShapeType :String = ""   // shape type string
    
    var currentFrame:CGRect = CGRect.zero // current frame
    
    var sideMenu:WPSideMenu?               // edge menu control 'cancel' 'clip' 'paste'
    
    var lockX:CGFloat?
    var lockY:CGFloat?
    var lockWidth:CGFloat = 0
    var lockheight:CGFloat = 0
    var toScale:Bool = true
    
    var isMove:Bool?                          // is out edge
    var edgePoint:CGPoint = CGPoint.zero      // edge point
    /**Public var **/
    
    open var currentPaths:NSMutableArray = NSMutableArray() // path array
    
    open var currentImage:UIImage?        // current image
    
    public var currentClipView:WPClipView?// current clip view
    
    public var currentBaseView:WPBaseView?// curren background main image view
    
    open var clipImageBlock:imageblock? // clipImageBlock
    
    
    /**XIB file in property **/
    @IBOutlet weak var showClipImageView:WPShapeImageView!// show clip image
    @IBOutlet weak var controlSizeButton_0: UIButton!// left top
    @IBOutlet weak var controlSizeButton_1: UIButton!// left center
    @IBOutlet weak var controlSizeButton_2: UIButton!// left bottom
    @IBOutlet weak var controlSizeButton_3: UIButton!// top center
    @IBOutlet weak var controlSizeButton_4: UIButton!// bottom center
    @IBOutlet weak var controlSizeButton_5: UIButton!// right top
    @IBOutlet weak var controlSizeButton_6: UIButton!// right center
    @IBOutlet weak var controlSizeButton_7: UIButton!// right bottom
    @IBOutlet weak var rotationControlButton: UIButton! //rotationControlButton
    
    
    /**XIB file in internal hidden property **/
    
    @IBOutlet weak var leftBottom: UILabel!
    @IBOutlet weak var left_leftBottom: UILabel!
    @IBOutlet weak var rightBottom: UILabel!
    @IBOutlet weak var right_rightBottom: UILabel!
    @IBOutlet weak var rightCenter: UILabel!
    @IBOutlet weak var leftCenter: UILabel!
    @IBOutlet weak var centerBottom: UILabel!
    @IBOutlet weak var topRight: UILabel!
    @IBOutlet weak var centerTop: UILabel!
    @IBOutlet weak var right_topBottom: UILabel!
    @IBOutlet weak var leftTop: UILabel!
    @IBOutlet weak var left_TopBottom: UILabel!
    // point convet angle
    internal func  AngleBetweenPoints(loacationPoint locapoint:CGPoint, startPoint:CGPoint, centerPonit:CGPoint)->CGFloat {
        return atan2(locapoint.y - centerPonit.y, locapoint.x - centerPonit.x) - atan2(startPoint.y - centerPonit.y, startPoint.x - centerPonit.x);
    }
    //RadiansToDegrees
    internal func RadiansToDegrees(_ angle :Double )->Double{ return angle*180/Double.pi }
    //DegreesToRadians
    internal func DegreesToRadians(_ angle :Double )->Double{ return Double.pi*angle/180 }
    
    
    
    //    setup 1 load nib file
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.isMember(of: WPBaseView.self) {
            
            self.currentBaseView = self as? WPBaseView
            
            
        }else if self.isMember(of: WPClipView.self)
        {
            
            self.currentClipView = self as? WPClipView
        }
        
       
        // once model
        DispatchQueue.once(token: "com.wang") {
            
            /** add notification  for kNotifationSlectorCellPath
             
             - parameter cell to be clip view path and path type name
             **/
            NotificationCenter.default.addObserver(self, selector: #selector(didReceive_NotificationSlectorCellGraphicPath(noti:)), name: NSNotification.Name(kNotifationSlectorCellPath), object: nil)
            
            /**UIApplicationWillChangeStatusBarOrientation layout **/
            NotificationCenter.default.addObserver(self, selector: #selector(didChnageDeviceOrientation(noti:)), name: NSNotification.Name.UIApplicationWillChangeStatusBarOrientation, object: nil)
            
            
        }
    }
       // adjust view layout
    func didChnageDeviceOrientation(noti:Notification) {
        
        
        if let baseView = self.currentBaseView {
            
            baseViewLastFrame = baseView.frame
            baseView.transform = CGAffineTransform.init(rotationAngle: 0)
            baseViewangle = 0
            
        }
        
        if let clipView  = self.currentClipView {
            
            baseViewLastFrame = clipView.frame
            clipView.transform = CGAffineTransform.init(rotationAngle: 0)
            clipViewangle = 0
        }
        
        orientationCode = noti.userInfo?["UIApplicationStatusBarOrientationUserInfoKey"] as? Int
        
        if orientationCode == 1 || orientationCode == 2 { // Portrait
            
            
            if let side = self.sideMenu {
                side.frame = CGRect.init(x:UIScreen.main.bounds.height-30, y: 0, width: 30, height:UIScreen.main.bounds.width)
            }
            
        }else if orientationCode == 4 || orientationCode == 3 { // 2
            
            if let side = self.sideMenu {
                side.frame = CGRect.init(x:UIScreen.main.bounds.height-30, y: 0, width: 30, height:UIScreen.main.bounds.width)
            }
        }else
        {
            if let side = self.sideMenu {
                side.frame = CGRect.init(x:UIScreen.main.bounds.height-30, y: 0, width: 30, height:UIScreen.main.bounds.height)
            }
        }
    }
    
    //MARK:  /**main viewController call back retun operation done image total method **/
    public func  pasteOrClipblockCallBackValue(Actionblock:@escaping (_ image:UIImage,_ location:CGRect)->Void){
        
        DispatchQueue.once(token: " loadsideMenuView()") {
            
            loadsideMenuView()// once load top menu
        }
        
        self.clipImageBlock = Actionblock
        
        
        sideMenu?.pasteOrClipImageBlock = {
            
            (opeartionBtn_count) ->Void in
            
            if (opeartionBtn_count.isEqual("cancel")) { // cancel
                
                self.clipImageBlock!(UIImage(),CGRect.zero)
                self.removeAllEvents()

                
            }else if  (opeartionBtn_count.isEqual("clip")){// clip
                
                if (self.currentBaseView?.shapeName.isEqual(to: ShapeType.Free_C.rawValue))!||(self.currentBaseView?.shapeName.isEqual(to: ShapeType.Free_S.rawValue))! {
                    
                    self.addFreePthClipViewToMainView()
                }else{
                    
                    self.addShapeClipViewToMainView()
                }
                
                
            }else if  (opeartionBtn_count.isEqual("paste")){ // paste
                
                var pasteImage:UIImage?
                // This is a repeat ，is free path state
                var angle  = 0.0
                if isCut {
                    baseViewangle = 0 // handle -7
                    pasteImage  =  self.currentClipView?.showClipImageView.pasteImage()
                    angle = clipViewangle
                    self.currentFrame = (self.currentClipView?.frame)!
                    
                }else { // base view paste image
                    
                    isCut = false
                    angle = baseViewangle
                    self.currentFrame = self.convert((self.showClipImageView.frame), to: self.superview) //MARK:Handle -7
                    
                    pasteImage  =  self.currentBaseView?.showClipImageView.image?.imageByScalingToSize(targetSize: (self.currentBaseView?.frame.size)!)
                }
                pasteImage = pasteImage?.imageRotatedByRadians(radinFlaot: angle)
                // rotation out side ,origin of x = 0
                if self.currentFrame.origin.x<0 {
                    
                    self.currentFrame = CGRect.init(x:0, y: self.currentFrame.origin.y, width: self.currentFrame.width, height: self.currentFrame.height)
                    
                }
                
                self.clipImageBlock!(pasteImage!,self.currentFrame)
                
                self.removeAllEvents()

            }else if  (opeartionBtn_count.isEqual("undo")){ // undo
                
                self.currentBaseView?.freePathView.undoPath(sender:(self.sideMenu?.undoButton)!)
            }
        }
        
    }
    
    // add free path clip View to be main view
    func addFreePthClipViewToMainView() {
        
        let screenImage  =  self.showClipImageView.image?.imageRotatedByRadians(radinFlaot: baseViewangle)
        
        let sizeImage:UIImage = (screenImage!.imageByScalingToSize(targetSize: (self.currentBaseView?.frame.size)!))
        
        self.currentBaseView?.showClipImageView.image = sizeImage
        
        self.currentBaseView?.showClipImageView.lastPath = self.currentBaseView?.freePathView.getCurrentPath()
        
        self.currentBaseView?.showClipImageView.isFree = true
        
        let cutImage:UIImage = (self.currentBaseView?.showClipImageView.cuting())!
        
        self.currentClipView = WPClipView.loadClipViewWithNibFiledependOn(baseView: (self.currentBaseView)!)
        
        self.currentClipView?.center  = (self.currentBaseView?.center)!
        
        self.currentClipView?.bounds = CGRect.init(x: 0, y: 0, width: cutImage.size.width, height: cutImage.size.height)
        
        self.currentClipView?.showClipImageView.image = cutImage
        
        self.currentClipView?.showClipImageView.backgroundColor = UIColor.clear
        
        self.superview?.addSubview(self.currentClipView!)
        
        self.sideMenu?.undoButton.isEnabled = false
        self.sideMenu?.undoButton.isSelected = false
        
        self.currentBaseView?.removeFromSuperview()
        
        isCut = true
        
    }
    
    // add clip view to superView later operation
    func addShapeClipViewToMainView(){
        //MARK:Handle -7
        isCut = true
        let screenImage  =  self.currentBaseView?.showClipImageView.pasteImage()
        self.currentClipView?.isHidden = false
        self.currentClipView?.showClipImageView.clip(rect: (self.currentClipView?.frame)!,edtingImage:
            screenImage!)
        
        self.showClipImageView = self.currentClipView?.showClipImageView
        
        self.currentClipView?.addShapeClipViewToMainView()
        // close polygon free size 
        if  (self.currentBaseView?.shapeName.isEqual(to: "Polygon"))! {
            self.currentClipView?.controlSizeButton_3.isUserInteractionEnabled = false
            self.currentClipView?.controlSizeButton_4.isUserInteractionEnabled = false
            self.currentClipView?.controlSizeButton_6.isUserInteractionEnabled = false
            self.currentClipView?.controlSizeButton_1.isUserInteractionEnabled = false
            self.currentBaseView?.openPolygon_countOperationButtonView(isOpen: false)
        }
       
        // remove baseView
        self.currentBaseView?.removeFromSuperview()
        
    }
    
       
    // over method
    func removeAllEvents() {
        
        self.currentBaseView?.removeFromSuperview()
        self.sideMenu?.removeFromSuperview()
        self.currentClipView?.removeFromSuperview()
        DispatchQueue._onceTracker = [String]()
        NotificationCenter.default.removeObserver(self)
        clipViewangle = 0.0
        baseViewangle = 0.0
        isCut = false
        baseViewLastFrame = nil
        clipViewLastFrame = nil
        self.currentBaseView = nil
        self.sideMenu = nil
        self.currentClipView = nil
        
    }
    
    // free path view off free size
    func closeFreeSize(swith:Bool)  {
        
        self.controlSizeButton_0.isUserInteractionEnabled = swith
        self.controlSizeButton_1.isUserInteractionEnabled = swith
        self.controlSizeButton_2.isUserInteractionEnabled = swith
        self.controlSizeButton_3.isUserInteractionEnabled = swith
        self.controlSizeButton_4.isUserInteractionEnabled = swith
        self.controlSizeButton_5.isUserInteractionEnabled = swith
        self.controlSizeButton_6.isUserInteractionEnabled = swith
        self.controlSizeButton_7.isUserInteractionEnabled = swith
    }
    
    // add top menu
    func loadsideMenuView() {
        
        sideMenu = WPSideMenu.loadsideMenu(CGRect.init(x:UIScreen.main.bounds.width-32, y: 0, width: 32, height:superview!.frame.height))
        
        superview?.addSubview(sideMenu!)
        
    }
    
    
    //MARK: change view size gesture action
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // handle -9
        self.transform = CGAffineTransform.identity
        clipViewangle = 0
        currentFrame = self.frame
        if lockX != nil {
            
            lockX = nil
            
        }
        if lockY != nil {
            
            lockY = nil
            
        }
        //        if self.isMember(of: WPClipView.self) {
        lockX = self.currentClipView?.frame.origin.x
        lockY = self.currentClipView?.frame.origin.y
        
        //        }
        lockheight = 0
        lockWidth = 0
        
        return true
    }
  
    //MARK: octagonal location frre size
    @IBAction func controlSizeButton_collectionManage_Gesture(_ sender: UIPanGestureRecognizer) {
        
        
        var sP:CGPoint = CGPoint.zero;//  size point
        var orientation:NSString = "" //  orientation
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
        
           
        }else  if (sender.view?.isEqual(self.controlSizeButton_1))! {// left center
            
            sP =  sender.location(in: self.superview)
            
            sP.x = currentFrame.origin.x - sP.x
            
            sP.y = currentFrame.origin.y
            
            aP.y = currentFrame.origin.y
            
            aP.x = currentFrame.origin.x - sP.x
            
            orientation = "right&left"
            
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
            
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_3))! {// top center
            
            sP =  sender.location(in: self.superview)
            
            sP.x = currentFrame.origin.x
            
            sP.y = currentFrame.origin.y - sP.y
            
            aP.y = currentFrame.origin.y - sP.y
            
            aP.x = currentFrame.origin.x
            
            orientation = "bottom&top"
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_4))! {// bottom center
            
            sP =  sender.location(in: self.superview)
            
            sP.y = sP.y - currentFrame.size.height - currentFrame.origin.y
            
            aP = currentFrame.origin
            
            orientation = "bottom&top"
            
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
            
        }else  if (sender.view?.isEqual(self.controlSizeButton_6))! {// right center
            
            sP =  sender.location(in: self.superview)
            
            sP.x = sP.x - currentFrame.size.width - currentFrame.origin.x
            
            aP = currentFrame.origin
            
            orientation = "right&left"
            
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
        
        self.changeViewSizeEDGE(sP , ap:aP ,orientation:orientation )
        
        
    }
    /**
     centralized processing view  size change
     - parameter sp size point
     - parameter ap appear point
     - parameter orientation
     **/
    func changeViewSizeEDGE(_ sp:CGPoint,ap:CGPoint,orientation:NSString) {
        var moveFrame = CGRect.zero
        moveFrame.origin.x = ap.x
        moveFrame.origin.y = ap.y
        moveFrame.size.width = currentFrame.size.width + sp.x
        moveFrame.size.height = currentFrame.size.height + sp.y
        if orientation.isEqual(to: "right&left") {
            moveFrame.size.height = currentFrame.size.height
        }else if orientation.isEqual(to: "bottom&top"){
            moveFrame.size.width = currentFrame.size.width
        }
        if moveFrame.size.width <= 100 {
            moveFrame.size.width = 100
            return
        }else if moveFrame.size.height <= 100 {
            moveFrame.size.height = 100
            return
        }
        if self.isMember(of: WPBaseView.self) {
            
            /**
             min size handle
             */
            
            if self.currentClipView != nil {
                
                self.currentBaseView?.currentClipFrame.origin = CGPoint.zero
                
                if (self.currentClipView?.frame.size.height)! >= moveFrame.size.height {
                    
                    moveFrame.size.height = (self.currentClipView?.frame.size.height)!
                    return
                    
                }
                
                if (self.currentClipView?.frame.size.width)! >= moveFrame.size.width {
                    
                    moveFrame.size.width = (self.currentClipView?.frame.size.width)!
                    return
                }
                
                
            }
            
            self.currentBaseView?.frame = moveFrame
            
            baseViewLastFrame = moveFrame
            
            
            
        }else if self.isMember(of: WPClipView.self)
        {
            /**
             size out handle
             */
            
            if !isCut {
                
                if moveFrame.origin.x < lockX! && moveFrame.origin.x > 0 {
                    
                    lockWidth = (self.currentBaseView?.frame.width)! - moveFrame.origin.x - moveFrame.size.width
                }
                if moveFrame.origin.y < lockY! && moveFrame.origin.y > 0 {
                    
                    lockheight = (self.currentBaseView?.frame.height)! - moveFrame.origin.y - moveFrame.size.height
                }
                
                if moveFrame.origin.x < 0 {
                    
                    moveFrame.origin.x = 0
                    
                    moveFrame.size.width = (self.currentBaseView?.frame.width)! - lockWidth
                    
                }
                if moveFrame.origin.y < 0 {
                    
                    moveFrame.origin.y = 0
                    moveFrame.size.height = (self.currentBaseView?.frame.height)! - lockheight
                }
                if moveFrame.size.width + moveFrame.origin.x  > (self.currentBaseView?.frame.size.width)!  {
                    
                    moveFrame.size.width = (self.currentBaseView?.frame.size.width)! - moveFrame.origin.x
                    
                    
                }
                if moveFrame.size.height + moveFrame.origin.y  > (self.currentBaseView?.frame.size.height)!  {
                    
                    moveFrame.size.height = (self.currentBaseView?.frame.size.height)! - moveFrame.origin.y
                    
                }
                
            }
            
            
            self.currentClipView?.frame = moveFrame
            /*record last time layout */
            self.currentBaseView?.currentClipFrame = moveFrame
            
        }
        
    }
    //MARK:rotation button Action  event
    @IBAction  func rotationButton_Action(_ sender: UIPanGestureRecognizer) {
        
        
        let locaPoint = sender.location(in: self.superview)
        let startPoint  = CGPoint.init(x: (self.frame.width)/2, y:0)
        let centerPoint = self.center
        
        if self.isMember(of: WPClipView.self) {
            
            clipViewangle = Double(self.AngleBetweenPoints(loacationPoint: locaPoint, startPoint: startPoint, centerPonit: centerPoint))
            self.transform = CGAffineTransform.init(rotationAngle:CGFloat(clipViewangle))
        }else
        {
            
            baseViewangle = Double(self.AngleBetweenPoints(loacationPoint: locaPoint, startPoint: startPoint, centerPonit: centerPoint))
            //MARK:Handle-7 roation later  position problem
            self.showClipImageView.transform = CGAffineTransform.init(rotationAngle:CGFloat(baseViewangle))
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMove = false
        let touch:UITouch  = touches.first!
        let point = touch.location(in: superview)
        if self.frame.contains(point) {
            edgePoint = touch.location(in: self)
            isMove = true
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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
    }
    @IBAction func scaleBaseIamgeView(_ sender: UIPinchGestureRecognizer) {
        
        
        self.transform = CGAffineTransform.init(scaleX: sender.scale, y: sender.scale)
        
    }
    //MARK:  didReceive_NotificationSlectorCellGraphicPath
    func didReceive_NotificationSlectorCellGraphicPath(noti:Notification) {}
    // sub class WPBaseView to  receive and override implementation
    
    
    /**
     hidden all position label
     
     - parameter hidden:
     **/
    func isHiddenAllsubViews(hidden:Bool) {
        
        self.leftTop.isHidden = hidden
        self.leftBottom.isHidden = hidden
        self.leftCenter.isHidden = hidden
        self.left_TopBottom.isHidden = hidden
        self.left_leftBottom.isHidden = hidden
        self.rightBottom.isHidden = hidden
        self.rightCenter.isHidden = hidden
        self.right_topBottom.isHidden = hidden
        self.right_rightBottom.isHidden = hidden
        self.topRight.isHidden = hidden
        self.centerTop.isHidden = hidden
        self.centerBottom.isHidden = hidden
        self.rotationControlButton.isHidden = hidden
        if isCut {
            self.currentClipView?.isHidden = hidden
        }
    }
}
//  for image call back
typealias imagePasteAndClipBlock = (String)->Void
//MARK:internal class *WPSideMenu*
class WPSideMenu: UIView {
    
    open var pasteOrClipImageBlock:imagePasteAndClipBlock?
    
    @IBOutlet weak var operationStackView: UIStackView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var clipButton: UIButton!
    // instantiation nib file
    public class  func loadsideMenu(_ frame:CGRect) -> WPSideMenu {
        
        let menu = UINib.init(nibName: "ImageImport", bundle: nil).instantiate(withOwner: self, options: nil)[10] as! WPSideMenu
        
        menu.frame = frame
        menu.layer.shadowColor = UIColor.black.cgColor
        menu.layer.shadowOffset = CGSize.init(width: 0, height: 0)
        menu.layer.shadowOpacity = 1
        menu.layer.shadowRadius = 10
        return menu
        
    }
    // cancel button action
    @IBAction func cancelButton_Action(_ sender: UIButton) {pasteOrClipImageBlock!("cancel")}
    // clip button action
    @IBAction func clipButton_Action(_ sender: UIButton) {
        
        if sender.isSelected {
            pasteOrClipImageBlock!("clip")
            sender.isSelected = false
            sender.isEnabled = false
        }
        
    }
    // paste button action
    @IBAction func pasteButton_Action(_ sender: UIButton) {pasteOrClipImageBlock!("paste")}
    @IBAction func undoButton_Action(_ sender: UIButton) {
        if sender.isSelected {
            pasteOrClipImageBlock!("undo")
            
            
        }
        
    }
}
//MARK:internal class *WP_ShapeBackgroudCollectionView*
class WP_ShapeBackgroudCollectionView: UIView,UICollectionViewDataSource,UICollectionViewDelegate {
    
    var  layout:UICollectionViewFlowLayout?
    
    /** setup2 lazy shapeCollectionView **/
    lazy var shapeCollectionView :UICollectionView = {
        
        let collectionV :UICollectionView = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height), collectionViewLayout: UICollectionViewFlowLayout())
        collectionV.delegate = self
        collectionV.dataSource = self
        collectionV.backgroundColor = UIColor.clear
        collectionV.showsHorizontalScrollIndicator = false
        collectionV.register(ShapeCollectionViewCell.self, forCellWithReuseIdentifier: "ShapeCell")
        
        return collectionV
    }()
    
    //    lazy shapeArrays
    lazy var shapeArray :NSMutableArray = {
        
        let arr1:NSMutableArray = ["Free_C",UIBezierPath()]
        let arr2:NSMutableArray = ["Free_S",UIBezierPath()]
        let arr3:NSMutableArray = ["Cercle",UIBezierPath()]
        let arr4:NSMutableArray = ["Triangle",UIBezierPath()]
        let arr5:NSMutableArray = ["Rectangle",UIBezierPath()]
        let arr6:NSMutableArray = ["Oval",UIBezierPath()]
        let arr7:NSMutableArray = ["Polygon",UIBezierPath()]

        
        let array:NSMutableArray = [arr1,arr2,arr3,arr4,arr5,arr6,arr7]
        
        return array
        
    }()
    
    /****setup 1  awakeFromNib******/
    override func awakeFromNib() {
        super.awakeFromNib()
        layout = UICollectionViewFlowLayout.init()
        layout?.scrollDirection = .vertical
        layout?.minimumLineSpacing = 10
        layout?.minimumInteritemSpacing = 5
        self.shapeCollectionView.collectionViewLayout = layout!
        self.addSubview(self.shapeCollectionView)
    }
    
    /****setup 3 update subViews*****/
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.shapeCollectionView.frame = self.bounds
        // update itemSize
        layout?.itemSize = CGSize.init(width:self.bounds.width, height:self.bounds.width )
    }
    
    // MARK: CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.shapeArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let shapeCell :ShapeCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShapeCell", for: indexPath) as! ShapeCollectionViewCell
        
        shapeCell.backgroundColor = UIColor.clear
        let names:NSMutableArray = self.shapeArray.object(at: indexPath.row) as! NSMutableArray
        
        let nameStr :String = names[0] as! String
        
        shapeCell.setshapeName(nameStr)
        
        let currentArray:NSMutableArray =  [nameStr,shapeCell.currentPath!];
        
        self.shapeArray.replaceObject(at: indexPath.row, with:currentArray)
        
        return shapeCell
        
        
    }
    
    // selector cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isCut {return}
        // read current cell in the path send notifation
        let currentArray:NSMutableArray = self.shapeArray[indexPath.row] as! NSMutableArray
        
        NotificationCenter.default.post(name: NSNotification.Name(kNotifationSlectorCellPath), object: nil, userInfo: ["path":currentArray])
        
        let selectedCell:ShapeCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ShapeCollectionViewCell
        
        selectedCell.backgroundColor = UIColor.init(red: 76/255.0, green: 76/255.0, blue: 76/255.0, alpha: 0.3)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if isCut {return}
        let deselectCell:ShapeCollectionViewCell = collectionView.cellForItem(at: indexPath) as! ShapeCollectionViewCell
        deselectCell.backgroundColor = UIColor.white
        
    }
    
    
}
//MARK: reason
/**
 if to setting imageView of image ,must before  adjust image size .to Fit imageView .becase clip  relative to self image  size .not imageView frame
 **/
extension UIImage{
    
    /**
     calculate image size
     - parameter targetSize:
     */
    public  func imageByScalingToSize(targetSize :CGSize) -> UIImage {
        
        
        let sourceImage :UIImage = self
        var newImage :UIImage = UIImage()
        let imageSize  = sourceImage.size
        let width = imageSize.width
        let height = imageSize.height
        let targetWidth = targetSize.width
        let targetHeight = targetSize.height
        var scaleFactor :CGFloat = 0
        var scaleWidth = targetWidth
        var scaleHeight = targetHeight
        var thumbnailPoint = CGPoint.init(x: 0, y: 0)
        
        if !imageSize.equalTo(targetSize) {
            
            let widthFactor = targetWidth/width
            let heightFactor = targetWidth/height
            
            if widthFactor < heightFactor {
                
                scaleFactor = widthFactor
            }else
            {
                scaleFactor = heightFactor
                scaleWidth = width * scaleFactor
                scaleHeight = height * scaleFactor
            }
            if widthFactor < heightFactor {
            thumbnailPoint.y = (targetHeight - scaleHeight) * 0.5
             }else if widthFactor > heightFactor{
                thumbnailPoint.x = (targetWidth - scaleWidth ) * 0.5
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
        var thumbnailRect  = CGRect.zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width = scaleWidth
        thumbnailRect.size.height = scaleHeight
        sourceImage.draw(in: thumbnailRect)
        newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
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
    
    
    func scaleToSize(size:CGSize) -> UIImage {
        
        
        var width:CGFloat = self.size.width
        var height:CGFloat = self.size.height
        
        let verticalRadio = size.height*1.0/height;
        let horizontalRadio = size.width*1.0/width;
        
        var radio:CGFloat = 1;
        if(verticalRadio>1 && horizontalRadio>1)
        {
            radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
        }
        else
        {
            radio = verticalRadio < horizontalRadio ? verticalRadio : horizontalRadio;
        }
        
        width = width * radio;
        height = height * radio;
        
        let xPos = (size.width - width)/2;
        let yPos = (size.height-height)/2;
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        self.draw(in: CGRect.init(x: xPos, y: yPos, width: width, height: height))
        let  scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaledImage!;
     }
    func sizeImageToScale() -> CGSize {
        
        let  maxWidth:CGFloat = UIScreen.main.bounds.width*0.46
        var image_W = self.size.width/2
        var image_H = self.size.height/2
        var factor:CGFloat = 1.0
        if image_W>image_H {
            if image_W>maxWidth {
                factor = maxWidth/image_W
                image_W = image_W*factor
                image_H = image_H*factor
            }
        }else{
            
            if image_H>maxWidth {
                factor = maxWidth/image_H
                image_W = max(image_W*factor, 46.0)
                image_H = image_H*factor
            }
         }
        return CGSize.init(width:image_W, height: image_H)
           
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

extension ViewController
{
    
    override func viewDidLayoutSubviews() {
        
        if let frame = baseViewLastFrame {
            // rotation screen opearion
            self.shapeBackGroudImageView?.frame = frame
            
            if orientationCode != nil {
                for clip in self.view.subviews {
                    if clip.isMember(of: WPClipView.self) {
                        clip.frame = frame
                    }
                }
                
            }
            
            
        }
        baseViewLastFrame = nil
        orientationCode =  nil
        
        
    }
 }
