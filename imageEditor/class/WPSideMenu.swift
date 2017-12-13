//
//  WPSideMenu.swift
//  imageEditor
//
//  Created by pow on 2017/11/7.
//  Copyright © 2017年 pow. All rights reserved.
//

import Foundation
import UIKit
protocol WPSideMenuDelegate {
    
    
    func onClick_SideMenu_SubAction_Events(type:String,sender:UIButton)
    
}

//MARK:internal class *WPSideMenu*
public typealias imagePasteAndClipBlock = (String)->Void

public class WPSideMenu: UIView {
    
    open var pasteOrClipImageBlock:imagePasteAndClipBlock?
    var delegate:WPSideMenuDelegate?
    
    
    @IBOutlet weak var operationStackView: UIStackView!
    
    @IBOutlet weak var countControlView: UIView!
    
    @IBOutlet weak var eventsStackView: UIStackView!
    
    @IBOutlet weak var centerButton: UIButton!
    
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var redoButton: UIButton!
    
    @IBOutlet weak var rotateRatioButton: UIButton!
    
    
    
    // instantiation nib file
    public class  func loadsideMenu(_ frame:CGRect) -> WPSideMenu {
        var  menu:WPSideMenu?
        _ =  UINib.init(nibName:nibName, instantiate: WPSideMenu.self) {
            (view) in
            menu = view as? WPSideMenu
            
        }
        menu?.frame = frame
        return menu!
        
    }
    
    // MARK: load Actions To StackView
    func loadActionsToStackView(type:OperationType) {
        // loading  button
        close_ActionsStackView()
        for b:UIButton in loadImageData(type: type) {
            self.operationStackView.addArrangedSubview(b)
        }
        
    }
    //MARK: close_ActionsStackView
    func close_ActionsStackView() {
        for view in self.operationStackView.subviews {
            self.operationStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
    }
    //MARK: reset_ActionsStackView
    func reset_ActionsStackView() {
        loadActionsToStackView(type: .unknown)
        selectedActionType = OperationType.unknown.rawValue
    }
    
    //MARK: load  button image
    func loadImageData(type:OperationType) -> Array<UIButton> {
        
        var datas:[UIButton] = Array()
        var images:[String] = Array()
        if type == .crop {
            // the frsit setup stack view and init install
            images = ["crop_free","crop_image","crop_canvas","crop_polygon","crop_path_c","crop_path_s","crop_square","crop_triangle","crop_circle","crop_oval","crop_43","crop_169"]
            
        }else if type == .full{
            images = ["fullCanvas_scaleFill","fullCanvas_scaleFit"]
        }else if type == .center{
            
        }else if type == .rotation{
            images = ["rotate_left","rotate_right"]
        }else{
            images = ["crop","rotate","center","fullCanvas"]
        }
        for name:String in images {
            let actionsBut:UIButton = UIButton()
            actionsBut.setImage(UIImage.init(named: name, in:Bundle.init(for: WPSideMenu.self), compatibleWith: nil), for: .normal)
            actionsBut.addTarget(self, action: NSSelectorFromString(name+"_Button_Action:"), for: .touchUpInside)
            datas.append(actionsBut)
        }
        
        return datas
        
    }
}
// FIXME: main operation  extension
extension WPSideMenu{
    
    // cancel button action
    @IBAction func cancelButton_Action(_ sender: UIButton) {
        
        if selectedActionType == OperationType.unknown.rawValue  {
            
            delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.cancel.rawValue, sender: sender)
            
        }else{
            delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.subCancel.rawValue, sender: sender)
            reset_ActionsStackView()
            closePolygonCountView()
        }
        
    }
    // clip button action
    @IBAction func crop_Button_Action(_ sender: UIButton) {
        loadActionsToStackView(type: .crop)
        doneButton.isEnabled = true
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        rotateRatioButton.isHidden = false
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.crop.rawValue, sender: sender)
    }
    
    @IBAction func rotate_Button_Action(_ sender: UIButton) {
        loadActionsToStackView(type: .rotation)
        selectedActionType = OperationType.rotation.rawValue
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.rotation.rawValue, sender: sender)
        doneButton.isEnabled = true
        rotateRatioButton.isHidden = true
       
        
    }
    @IBAction func center_Button_Action(_ sender: UIButton) {
        self.centerButton = sender
        sender.setImage(UIImage.init(named: "center.selected", in: Bundle.init(for: WPSideMenu.self), compatibleWith: nil), for: .highlighted)
        selectedActionType = OperationType.center.rawValue
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.center.rawValue, sender: sender)
        rotateRatioButton.isHidden = true
    }
    @IBAction func  redoButton_Action(_ sender:UIButton){
        
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.redo.rawValue, sender: sender)
        rotateRatioButton.isHidden = true
    }
    @IBAction func undoButton_Action(_ sender: UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.undo.rawValue, sender: sender)
        rotateRatioButton.isHidden = true
    }
    @IBAction func fullCanvas_Button_Action(_ sender: UIButton) {
        loadActionsToStackView(type: .full)
        selectedActionType = OperationType.full.rawValue
        doneButton.isEnabled = true
        rotateRatioButton.isHidden = true
    }
    
    @IBAction func doneButton_Action(_ sender:UIButton){
        
        if selectedActionType.isEqual(SubActionType.rotate_left.rawValue)||selectedActionType.isEqual(OperationType.center.rawValue)||selectedActionType.isEqual(OperationType.rotation.rawValue)||selectedActionType.isEqual(OperationType.unknown.rawValue)||selectedActionType.isEqual(OperationType.full.rawValue)||selectedActionType.isEqual(SubActionType.rotate_right.rawValue)||selectedActionType.isEqual(SubActionType.fullCanvas_scaleFit.rawValue)||selectedActionType.isEqual(SubActionType.fullCanvas_scaleFill.rawValue)||selectedActionType.isEqual(OperationType.crop.rawValue)||selectedActionType.isEqual(OperationType.undo.rawValue)||selectedActionType.isEqual(OperationType.redo.rawValue)||selectedActionType.isEqual(OperationType.reset.rawValue){
            delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.paste.rawValue, sender: sender)
        }else{
            delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.clip.rawValue, sender: sender)
            loadActionsToStackView(type: .unknown)
            selectedActionType = OperationType.unknown.rawValue
            closePolygonCountView()
            
        }
    }
    
    @IBAction func resetButton_Action(_ sender:UIButton){
        reset_ActionsStackView()
        closePolygonCountView()
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.reset.rawValue, sender: sender)
        resetButton.isEnabled = false
        undoButton.isEnabled = false
        redoButton.isEnabled = false
    }
    
    @IBAction func rotationScaleButton_Action(_ sender:UIButton){
       
        delegate?.onClick_SideMenu_SubAction_Events(type: OperationType.rotateRatio.rawValue, sender: sender)
    }
}



// FIXME: sub actions extension
extension WPSideMenu {
    
    @objc  func crop_free_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_free.rawValue, sender: sender)
    }
    @objc  func crop_image_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_image.rawValue, sender: sender)
        
    }
    @objc func crop_canvas_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_canvas.rawValue, sender: sender)
        
    }
    @objc  func crop_polygon_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_polygon.rawValue, sender: sender)
        openPolygon_countOperationButtonView()
    }
    @objc func crop_path_c_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Free_C.rawValue, sender: sender)
        
    }
    @objc  func crop_path_s_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Free_S.rawValue, sender: sender)
        
    }
    @objc func crop_square_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Rectangle.rawValue, sender: sender)
        
    }
    @objc func crop_triangle_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Triangle.rawValue, sender: sender)
        
    }
    @objc  func crop_circle_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Cercle.rawValue, sender: sender)
        
    }
    @objc  func crop_oval_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.Oval.rawValue, sender: sender)
        
    }
    @objc func crop_43_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_43.rawValue, sender: sender)
        
        
    }
    @objc func crop_169_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.crop_169.rawValue, sender: sender)
        
    }
    @objc  func fullCanvas_scaleFill_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.fullCanvas_scaleFill.rawValue, sender: sender)
        
    }
    @objc func fullCanvas_scaleFit_Button_Action(_ sender:UIButton) {
        
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.fullCanvas_scaleFit.rawValue, sender: sender)
    }
    @objc func rotate_left_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.rotate_left.rawValue, sender: sender)
    }
    @objc func rotate_right_Button_Action(_ sender:UIButton) {
        delegate?.onClick_SideMenu_SubAction_Events(type: SubActionType.rotate_right.rawValue, sender: sender)
    }
    func openPolygon_countOperationButtonView() {
        self.countControlView.isHidden = false
        let countPolygonSelector:Selector = NSSelectorFromString("add_Count_Polygon_Action:")
        let addCount:UIButton = self.countControlView.subviews.first as! UIButton
        let decreaseCount:UIButton = self.countControlView.subviews.last as! UIButton
        addCount.tag = 345
        decreaseCount.tag = 346
        addCount.addTarget(delegate, action:countPolygonSelector, for: .touchUpInside)
        decreaseCount.addTarget(delegate, action:countPolygonSelector, for: .touchUpInside)
    }
    
    func closePolygonCountView() {
        self.countControlView.isHidden = true
    }
    
    
    
  }

