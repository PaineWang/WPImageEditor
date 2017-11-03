//
//  WP_ ClipView.swift
//  layerDraw
//
//  Created by pow on 2017/9/12.
//  Copyright © 2017年 pow. All rights reserved.
//

import UIKit


class WPBaseView: WPImageManger {
    
    /**BUG 1 : question -> change size sub View follow change
     
     idear -> record last time frame . on the layout subviews time to be  adjust
     
     **/
    @IBOutlet weak var freePathView: WPFreePathView!
    public var currentClipFrame =  CGRect.init(x:0, y:0, width: 100, height: 100)
    
    var shapeName:NSString = ""
    var pointLabel:UILabel?
    var movePath:UIBezierPath?
    
    
    
    //    setup 1.1 by means of nib file ,better show layout
    open class func loadSizeViewWithNibFile(_ editorImage:UIImage,inSuperView:UIView) -> WPBaseView {
        let cView :WPBaseView = UINib.init(nibName: "ImageImport", bundle: nil).instantiate(withOwner: self, options: nil).first as! WPBaseView
        
        cView.showClipImageView.image = editorImage.scaleToSize(size:editorImage.sizeImageToScale())
        let bigBounds = CGRect.init(x: 0, y: 0, width: (cView.showClipImageView.image?.size.width)!, height: (cView.showClipImageView.image?.size.height)!)
        cView.frame = CGRect.zero
        cView.center = inSuperView.center
        cView.bounds = bigBounds
        return cView
        
        
    }
    
    override func draw(_ rect:CGRect)
    {
        self.currentBaseView?.currentImage = self.showClipImageView.image
        
    }
    
    
    override func layoutSubviews() {
        
        /*copy last time frame*/
        self.currentClipView?.frame = self.currentClipFrame
        
    }
    
    
    //MARK:  didReceive_NotificationSlectorCellGraphicPath
    override func didReceive_NotificationSlectorCellGraphicPath(noti:Notification) {
        
        
        
        //Receive need change shapeView  size
        let path:NSMutableArray = noti.userInfo?["path"]! as! NSMutableArray
        
        shapeName = path.firstObject as! NSString
        if self.sideMenu?.operationStackView.arrangedSubviews.count == 5 {
            openPolygon_countOperationButtonView(isOpen: false)
        }
        if shapeName.isEqual(to: ShapeType.Free_C.rawValue)||shapeName.isEqual(to: ShapeType.Free_S.rawValue) {
            self.freePathView.isHidden = false
            self.freePathView.baseImage = self.currentImage
            self.freePathView.sideMenu_undoButton = self.sideMenu?.undoButton
            self.freePathView.sideMenu_clipButton = self.sideMenu?.clipButton
            self.sideMenu?.clipButton.isEnabled = false
            self.sideMenu?.clipButton.isSelected = false
            self.currentClipView?.removeFromSuperview()
            self.freePathView.freePathName = shapeName
            //TODO: current state is can't free size
            self.closeFreeSize(swith: false)
            
        }else{
            
            self.closeFreeSize(swith: true)
            
            if let oldClipView = self.currentClipView {
                
                oldClipView.removeFromSuperview()
                
            }
            self.currentClipView = WPClipView.loadClipViewWithNibFiledependOn(baseView: self)
            
            //  copy current path to shapeView
            self.currentClipView?.currentPaths = path
            self.currentClipFrame = CGRect.init(origin: currentClipFrame.origin, size: CGSize.init(width: 100, height: 100))
            //  copy current editing image  to shapeView
            self.currentClipView?.currentImage = self.currentImage
            
            //  update draw path
            self.currentClipView?.setNeedsDisplay()
            
            self.currentClipView?.rotationControlButton.isHidden = true
            
            self.addSubview(self.currentClipView!)
            
            self.freePathView.isHidden = true
            
            self.sideMenu?.undoButton.isEnabled = false
            self.sideMenu?.undoButton.isSelected = false
            
            self.sideMenu?.clipButton.isEnabled = true
            self.sideMenu?.clipButton.isSelected = true
            
            if shapeName.isEqual(to: "Polygon") {
                openPolygon_countOperationButtonView(isOpen: true)// open count operation button 
                // close up down left right free size 
                self.currentClipView?.controlSizeButton_3.isUserInteractionEnabled = false
                self.currentClipView?.controlSizeButton_4.isUserInteractionEnabled = false
                self.currentClipView?.controlSizeButton_6.isUserInteractionEnabled = false
                self.currentClipView?.controlSizeButton_1.isUserInteractionEnabled = false
                
            }
            
        }
    }
    
    func openPolygon_countOperationButtonView(isOpen:Bool) {
        
        if isOpen {
            let  countControlView:UIView = UINib.init(nibName: "ImageImport", bundle: nil).instantiate(withOwner:WPClipView.self, options: nil).last as! UIView
            self.sideMenu?.operationStackView.addArrangedSubview(countControlView)
            let countPolygonSelector:Selector = NSSelectorFromString("addAndDecrease_Polygon_Action:")
            let addCount:UIButton = countControlView.subviews.first as! UIButton
            let decreaseCount:UIButton = countControlView.subviews.last as! UIButton
            addCount.tag = 345
            decreaseCount.tag = 346
            addCount.addTarget(self.currentClipView, action:countPolygonSelector, for: .touchUpInside)
            decreaseCount.addTarget(self.currentClipView, action:countPolygonSelector, for: .touchUpInside)

        }else{
            self.sideMenu?.operationStackView.removeArrangedSubview((self.sideMenu?.operationStackView.arrangedSubviews.last)!)
            self.sideMenu?.operationStackView.subviews.last?.removeFromSuperview()
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if (touches.first?.view?.isMember(of: WPBaseView.self))! {
            
            if shapeName.isEqual(to: ShapeType.Free_C.rawValue)||shapeName.isEqual(to: ShapeType.Free_S.rawValue) {
            }else{
                super.touchesMoved(touches, with: event)
                baseViewLastFrame = self.frame
                //Handle -7
                //                baseViewangle = 0.0
                
            }
        }
    }
}

