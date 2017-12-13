//
//  WPFreePathView.swift
//  imageEditor
//
//  Created by pow on 2017/9/30.
//  Copyright © 2017年 WANG. All rights reserved.

/**
 
 -state-
 
 The current effect is curve and line, cut and finished. Specify shape cutting completion.
 1. Curve cutting, can not be cancelled after completion
 2.The curve is a point-to-point operation
 3.The line is a drag and drop operation
 4.Choose a curve or a straight line. You can't scale
 
 **/

import UIKit

public class WPFreePathView: UIView {
    
    enum PathState {
        case on_control
        case move
        case off_control
        case Refresh
        
    }
    
    /**private property**/
    private var points:NSMutableArray = NSMutableArray() // current all point
    private var paths:NSMutableArray = NSMutableArray() // current Frre_S of Bezier path
    private var recordArray:[CGPoint] = Array() // record start and end point
    var isDone:Bool = false // is done darwing line
    var isOpenControl:Bool = false
    var currentMark:UILabel? // current move change shape of mark label
    var currentStartPoint_1:CGPoint = CGPoint.zero // move point 1
    var currentStartPoint_2:CGPoint = CGPoint.zero // move point 2
    var movePath_1 = UIBezierPath()// current moveed two point . in the 1
    var movePath_2 = UIBezierPath()// current moveed two point . in the 2
    var lineCount:Int = 0 // number record
    var addPoint:CGPoint = CGPoint.zero // move path  add point
    var controlMark:UILabel? // control mark
    var movePaths:[UIBezierPath] = Array()
    var currentEvent:NSString = "" // current evenet in the is began and moveed and enden
    var currentOPerationPaths:NSArray? // cureent operation path
    
    /**
     record  four point
     indexPath
     
     1.control point 1  actually  is move point 1
     2.control point 2  actually  is move point 3
     3.control path 1  first
     4.control path 2  last
     **/
    var indexPath:[Int] = Array()
    var doneTimer:Timer?// done timer
    
    // public property
    public var sideMenu_undoButton:UIButton?
    public var sideMenu_clipButton:UIButton?
    public var baseImage:UIImage? // operation image
    public var path = UIBezierPath() // operation path
    
    // monitor Prperty
    override public var isHidden: Bool{didSet{removeAllEvents()}}//monitor hidden
    public var freePathName:NSString = "" {didSet{removeAllEvents()}}//monitor freePathName
    
    func changeState(newState:PathState,Whihresource:NSArray) {
        
        switch newState {
        case .on_control:
            
            indexPath.removeAll()
            removeControlMark()
            control_Free_C_LinePoint(index:Whihresource[1] as! Int)
            
        case .off_control:
            let operationPath = Whihresource[1]  as! UIBezierPath
            self.paths.replaceObject(at:indexPath[0], with: [PathState.off_control,operationPath])
            indexPath.removeAll()
            removeControlMark()
            
        case .move:
            let operationPath = Whihresource[1] as! UIBezierPath
            // all event  need remove
            self.paths.replaceObject(at:indexPath[0], with: [PathState.move,operationPath])
            removeControlMark()
        case .Refresh:
            // add new then change old
            for index in 0..<self.paths.count {
                
                let hasArray:NSArray  = [PathState.off_control,(self.paths[index] as! NSArray).lastObject as! UIBezierPath]  as NSArray
                
                self.paths.replaceObject(at: index, with: hasArray)
            }
            
            removeControlMark()
            
        }
        
    }
    //MARK:  darwing  function
    override public func draw(_ rect: CGRect) {
        
        if self.recordArray.isEmpty  {return}
        
        path.lineWidth = 2
        UIColor.orange.setStroke()
        UIColor.init(red: 76/255.0, green: 76/255.0, blue: 76/255.0, alpha: 0.8).setFill()
        
        // This is Curve line operation
        if (self.freePathName.isEqual(to: "Free_C")) {
            // MARK: done later can't undo
            self.sideMenu_undoButton?.isSelected = !isDone;
            self.sideMenu_undoButton?.isEnabled = !isDone
            
            //  pathInfo is array ,in the first is current path state ,the second is current line path
            for pathInfo in self.paths {
                
                let state = (pathInfo as! NSArray).firstObject as! PathState
                let line = (pathInfo as! NSArray).lastObject as! UIBezierPath
                
                if state == .off_control {// that  state  is lock . can't control
                    
                    line.lineWidth = 2
                    UIColor.orange.setStroke()
                    line.stroke()
                    
                    continue
                    
                }else if state == .on_control  // that state is unlock .can control
                {
                    
                    /**this is main line */
                    line.removeAllPoints()
                    let movePoint = self.subviews[indexPath[0]].center
                    line.move(to: movePoint)
                    
                    line.lineWidth = 2
                    line.addQuadCurve(to: addPoint, controlPoint: (controlMark?.center)!)
                    UIColor.orange.setStroke()
                    line.stroke()
                    
                    /**this is control point of line*/
                    
                    if !movePaths.isEmpty {
                        
                        self.movePath_1 = movePaths.first!
                        self.movePath_2 = movePaths.last!
                        
                        self.movePath_1 .removeAllPoints()
                        self.movePath_1.lineWidth = 2
                        UIColor.orange.setStroke()
                        self.movePath_1.move(to:addPoint)
                        self.movePath_1.addLine(to:self.currentStartPoint_1)
                        self.movePath_1.stroke()
                        
                        self.movePath_2.removeAllPoints()
                        self.movePath_2.lineWidth = 2
                        UIColor.orange.setStroke()
                        self.movePath_2.move(to:addPoint)
                        self.movePath_2.addLine(to:self.currentStartPoint_2)
                        self.movePath_2.stroke()
                        
                    }
                    
                    continue
                    
                }else if state == .move {
                    
                    
                    /**this is main line */
                    line.removeAllPoints()
                    let movePoint = self.subviews[indexPath[0]].center
                    line.move(to: movePoint)
                    
                    line.lineWidth = 2
                    line.addQuadCurve(to: addPoint, controlPoint: (controlMark?.center)!)
                    UIColor.orange.setStroke()
                    line.stroke()
                    
                    
                    continue
                    
                }
                else // 1.that state is
                {
                    line.lineWidth = 2
                    UIColor.orange.setStroke()
                    line.stroke()
                }
                
            }
            
            // remove event began and move .only need  ended to be action
            if currentEvent.isEqual(to: "Ended") && !isOpenControl {
                
                if self.points.count>1 {
                    
                    // start moveed time
                    if !(self.points[self.paths.count] as! CGPoint).equalTo(self.points.lastObject as! CGPoint) {
                        
                        path.removeAllPoints()
                        path.move(to: self.points[self.paths.count] as! CGPoint)
                        path.addLine(to: self.points.lastObject as! CGPoint)
                        path.stroke()
                        let s_path:UIBezierPath = UIBezierPath.init(cgPath: path.cgPath)
                        self.currentOPerationPaths = [PathState.off_control,s_path]
                        self.paths.add(self.currentOPerationPaths!)
                        
                    }
                }
            }
            
            // that is straight line darw operation
        }else if (self.freePathName.isEqual(to: "Free_S")) {
            
            path.removeAllPoints()
            for s_path in self.paths {
                
                (s_path as! UIBezierPath).lineWidth = 2
                UIColor.orange.setStroke()
                (s_path as! UIBezierPath).stroke()
            }
            
            if isDone {
                
                if  let mark = self.currentMark {
                    
                    self.movePath_1.removeAllPoints()
                    self.movePath_1.move(to: self.currentStartPoint_1)
                    self.movePath_1.addLine(to: (mark.center))
                    
                    self.movePath_2.removeAllPoints()
                    self.movePath_2.move(to: self.currentStartPoint_2)
                    self.movePath_2.addLine(to: (mark.center))
                }
                
            }else{
                
                if self.points.count>0 {
                    path.move(to: self.points[0] as! CGPoint)
                    path.addLine(to: self.points.lastObject as! CGPoint)
                    
                }
                
            }
            path.stroke()
            if !self.recordArray.isEmpty {
                self.sideMenu_undoButton?.isSelected = true;
                self.sideMenu_undoButton?.isEnabled = true
            }
        }
        
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let startPoint  = touches.first?.location(in: self)
        currentEvent = "Began"
        
        if isDone {// done time do it
            
            if freePathName.isEqual(to: "Free_C") {
                
                // do someting
                
                // MARK :No operation at the moment
                
            }else if freePathName.isEqual(to: "Free_S") {
                
                move_Free_S_LinePoint(startPoint: startPoint!)
                
            }
            
        }else{
            
            if freePathName.isEqual(to: "Free_S") {
                
                
                // not done do it
                
                if (self.subviews.isEmpty) {
                    // add start mark to view
                    self.addStartLineMarkview(point: startPoint!)
                    
                }
                // add start point to record array
                self.recordArray.append(startPoint!)
                self.points.add(startPoint!)
                
                
                
            }else if freePathName.isEqual(to: "Free_C"){
                
                
                self.recordArray.append(startPoint!)
                
                if isContains(point: startPoint!).0 {
                    
                    if (self.subviews.first?.isEqual(isContains(point: startPoint!).1 as? UILabel))! {return}
                    controlMark = isContains(point: startPoint!).1 as? UILabel
                    if !(controlMark?.text?.hasPrefix("C"))! {
                        
                        isOpenControl = true
                    }
                }else
                {
                    controlMark = isContains(point: startPoint!).1 as? UILabel
                    controlMark?.text = ""
                    isOpenControl = false
                    
                }
            }
        }
        
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let movePoint  = touches.first?.location(in: self)
        currentEvent = "Moved"
        
        if isDone {
            
            if freePathName.isEqual(to: "Free_C") {
                
                // MARK :No operation at the moment
                
                
            }else if freePathName.isEqual(to: "Free_S"){
                
                self.currentMark?.center = movePoint!
                self.setNeedsDisplay()
                
            }
        }else
        {
            if freePathName.isEqual(to: "Free_C") {
                
                if isContains(point: movePoint!).0 { // pencil Too sensitive
                    
                    if (self.subviews.first?.isEqual(isContains(point: movePoint!).1 as? UILabel))! {return}
                    
                    if (controlMark?.text?.isEqual("C1"))! {
                        
                        self.currentStartPoint_1 = movePoint!
                        controlMark?.center = movePoint!
                        self.setNeedsDisplay()
                        
                    }else if (controlMark?.text?.isEqual("C2"))!{
                        
                        self.currentStartPoint_2 = movePoint!
                        controlMark?.center = movePoint!
                        self.setNeedsDisplay()
                    }else
                    {
                        
                        if let operationPath:NSArray = self.currentOPerationPaths {
                            
                            // only last point ,so can move
                            if indexPath[0] == self.paths.count-1 {
                                
                                self.changeState(newState: .move, Whihresource: operationPath)
                                
                                addPoint = movePoint!
                                controlMark?.center = movePoint!
                                isOpenControl = true
                                self.setNeedsDisplay()
                            }
                            
                        }
                        
                        
                    }
                    
                }
                
                
            }else if freePathName.isEqual(to: "Free_S"){
                
                self.points.add(movePoint!)
                self.setNeedsDisplay()
            }
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        let endPoint = touches.first?.location(in: self)
        
        
        currentEvent = "Ended"
        //MARK: --out side view can't add point
        if !self.frame.contains(endPoint!) {return}
        
        if isDone {
            
            if freePathName.isEqual(to: "Free_C") {
                
                // MARK :No operation at the moment
                
                
            }else if freePathName.isEqual(to: "Free_S"){
                
                
                if !indexPath.isEmpty {
                    
                    let s_path1:UIBezierPath = UIBezierPath.init(cgPath: self.movePath_1.cgPath)
                    let s_path2:UIBezierPath = UIBezierPath.init(cgPath: self.movePath_2.cgPath)
                    
                    
                    self.paths.replaceObject(at: indexPath[2], with: s_path1)
                    self.paths.replaceObject(at: indexPath[3], with: s_path2)
                    
                    indexPath.removeAll()
                    self.currentMark = nil
                    self.setNeedsDisplay()
                    
                }
            }
        }else{
            
            if freePathName.isEqual(to: "Free_C") {
                
                
                if isContains(point: endPoint!).0 { // is point inside
                    
                    currentMark  = (isContains(point: endPoint!).1 as? UILabel)!
                    let mark:UILabel = currentMark!
                    
                    
                    // this is  done later operation
                    if (mark.frame.contains(self.recordArray[0] )) {
                        
                        for index in 0..<self.paths.count {
                            
                            let hasArray:NSArray  = [PathState.off_control,(self.paths[index] as! NSArray).lastObject as! UIBezierPath]  as NSArray
                            
                            self.paths.replaceObject(at: index, with: hasArray)
                        }
                        // becase end clip of time incomplete 。so do it
                        self.addStartLineMarkview(point: mark.center)
                        self.points.add(mark.center)// add point is mark of center
                        indexPath.removeAll()
                        mark.removeFromSuperview()
                        removeControlMark()
                        self.setNeedsDisplay()
                        doneAnimation()
                        return
                        
                        
                    }
                    
                    //click main line point of operation
                    if !(mark.text?.hasPrefix("C"))! {
                        
                        isOpenControl = false
                        
                        mark.isUserInteractionEnabled = true
                        
                        let index = self.subviews.index(of:mark)!
                        
                        if index == 0{return} //MARK:handle-6 drag later add point  index is 0
                        
                        let currentArr = self.paths[index-1] as!NSArray
                        
                        let hasString = currentArr.firstObject as! PathState
                        
                        if hasString == .on_control { // 1.state already is controled
                            
                            changeState(newState: .off_control, Whihresource: currentArr)
                            
                        }else if hasString == .move {
                            
                            changeState(newState: .off_control, Whihresource: currentArr)
                            
                            //MARK: --just main line point move time need add point aigan
                            
                            self.points.removeLastObject()// the first remove last object ，
                            self.points.add(endPoint!)// then add new endpoint
                            
                            
                        }else if hasString == .off_control { // 2.state nomal open control
                            
                            for index in 0..<self.paths.count {
                                
                                let hasArray:NSArray  = [PathState.off_control,(self.paths[index] as! NSArray).lastObject as! UIBezierPath]  as NSArray
                                
                                self.paths.replaceObject(at: index, with: hasArray)
                            }
                            
                            changeState(newState: .on_control, Whihresource: [currentArr,index])
                            
                        }else // 3.state have controled point ,but click other path
                        {
                            
                            changeState(newState: .off_control, Whihresource: self.currentOPerationPaths!)// change last path state is off_control
                            
                            changeState(newState: .on_control, Whihresource: currentArr) // change current path state
                            
                        }
                        
                    }else
                    {
                        // just move sub control point
                        isOpenControl  = true
                        
                    }
                }else // is out side
                {
                    if !isOpenControl { // only main line point .need add new line
                        
                        self.changeState(newState: .Refresh, Whihresource: [PathState.off_control,UIBezierPath()])
                        self.currentOPerationPaths = nil
                        self.addStartLineMarkview(point: endPoint!)
                        self.points.add(endPoint!)
                        
                    }
                }
                // add start point to record array
                self.recordArray.removeLast() //MARK:handle-6 drag later add point  index is 0
                
                self.recordArray.append(endPoint!)
                self.setNeedsDisplay()
                
            }else if freePathName.isEqual(to: "Free_S"){
                
                self.addStartLineMarkview(point: endPoint!)
                if self.paths.count>0 {
                    // Bezier Path move point equal  height + origin.y
                    let firstPoint = CGPoint.init(x: (self.paths[0] as! UIBezierPath).bounds.origin.x, y: (self.paths[0] as! UIBezierPath).bounds.origin.y+(self.paths[0] as! UIBezierPath).bounds.size.height)
                    
                    // 1.state : undo later path
                    if (self.subviews.last?.frame.contains(firstPoint))! {
                        
                        if ((self.subviews.first as! MarkLabel).text?.isEqual("1"))! {
                            
                            self.subviews.first?.removeFromSuperview()
                        }
                        doneAnimation()
                    }
                    
                }
                self.points.removeAllObjects()
                let s_path:UIBezierPath = UIBezierPath.init(cgPath: path.cgPath)
                self.paths.add(s_path)
            }
            
            // add start point to record array
            self.recordArray.append(endPoint!)
        }
    }
    //MARK: ** get current path **/
    public func getCurrentPath()->UIBezierPath {
        
        
        let currentPath = UIBezierPath()
        
        if freePathName.isEqual(to: "Free_C") {
            
            currentPath.move(to:self.subviews[0].center)
            
            for index in 1..<self.subviews.count {
                
                currentPath.addLine(to:self.subviews[index].center)
            }
            
            for value in self.paths {
                
                currentPath.append((value as! NSArray).lastObject as! UIBezierPath)
            }
            
            // becase append path no good .is faulted .can't darw path .so do it
        }else if freePathName.isEqual(to: "Free_S"){
            
            currentPath.move(to:self.subviews[0].center)
            
            for index in 1..<self.subviews.count {
                
                currentPath.addLine(to:self.subviews[index].center)
            }
        }
        
        
        return currentPath
        
    }
    
    func removeControlMark()  {
        
        for mark in self.subviews {
            if  ((mark as! UILabel).text?.hasPrefix("C"))! {
                mark.removeFromSuperview()
            }
        }
        movePaths.removeAll()
        
        isOpenControl = false
        
        
    }
    /**
     straight line move change shape
     - parameter startPoint:
     */
    func move_Free_S_LinePoint(startPoint:CGPoint) {
        
        for mark in self.subviews {
            
            if mark.frame.contains(startPoint) {
                
                self.currentMark = (mark as! UILabel)
                
                let index = self.subviews.index(of: self.currentMark!)
                
                if index == self.subviews.count-1 {
                    indexPath.append(0)//0
                    indexPath.append(index!-1)//1
                    indexPath.append(0)// 2
                    indexPath.append(index!)//3
                }else if index == 0 {
                    indexPath.append(self.subviews.count-1)//0
                    indexPath.append(index!+1)//1
                    indexPath.append(index!)//2
                    indexPath.append(index!+1)//3
                }else{
                    indexPath.append(index!-1)//0
                    indexPath.append(index!+1)//1
                    indexPath.append(index!)//2
                    indexPath.append(index!+1)//3
                    
                }
            }
            
        }
        if !indexPath.isEmpty {
            
            self.currentStartPoint_1 = self.subviews[indexPath[0]].center
            self.currentStartPoint_2 = self.subviews[indexPath[1]].center
            
            self.movePath_1 = self.paths[indexPath[2]] as! UIBezierPath
            self.movePath_2 = self.paths[indexPath[3]] as! UIBezierPath
        }
    }
    //    MARK: add  control point mark
    func control_Free_C_LinePoint(index:Int) {
        
        currentMark = self.subviews[index] as? UILabel
        
        if index == self.subviews.count-1 {
            if isDone {
                
                indexPath.append(0)//first
                indexPath.append(index)//
            }else
            {
                indexPath.append(index-1)//0
                indexPath.append(index)//1
            }
            
            
        }else if index == 0 {
            indexPath.append(self.subviews.count-1)//0
            indexPath.append(index)//1
            
        }else{
            indexPath.append(index-1)//0
            indexPath.append(index)//1
            
        }
        
        
        currentOPerationPaths = self.paths[indexPath[0]] as? NSArray
        var state = currentOPerationPaths?[0] as! PathState
        let line = currentOPerationPaths?[1] as? UIBezierPath
        
        if state == .off_control {
            
            addPoint = self.subviews[indexPath[1]].center
            
            self.currentStartPoint_1 = CGPoint.init(x: (currentMark?.center.x)!, y: (currentMark?.center.y)!+(currentMark?.bounds.height)!*2) // control point 1
            self.currentStartPoint_2 = CGPoint.init(x: (currentMark?.center.x)!, y: (currentMark?.center.y)!-(currentMark?.bounds.height)!*2) // control point 2
            
            self.addControllerMark(point: self.currentStartPoint_1, tag: 1)
            self.addControllerMark(point: self.currentStartPoint_2, tag: 2)
            
            movePaths.append(self.movePath_1)
            movePaths.append(self.movePath_2)
            
            state = .on_control
            line?.removeAllPoints()
            self.paths.replaceObject(at: indexPath[0], with:[state,line!])
        }
    }
    
    // is contains point
    func isContains(point:CGPoint) -> (Bool,UIView){
        
        
        for mark in self.subviews {
            
            if mark.frame.contains(point) {
                
                let index = self.subviews.index(of:mark)!
                
                if index == self.subviews.count-1 {
                    if isDone {
                        
                        indexPath.append(0)//first
                        indexPath.append(index)//
                    }else
                    {
                        indexPath.append(index-1)//0
                        indexPath.append(index)//1
                    }
                    
                    
                }else if index == 0 {
                    indexPath.append(self.subviews.count-1)//0
                    indexPath.append(index)//1
                    
                }else{
                    indexPath.append(index-1)//0
                    indexPath.append(index)//1
                    
                }
                return (true,mark)
                
            }
            
        }
        
        return (false,UILabel())
        
    }
    /**
     remove all views or events
     */
    func removeAllEvents() {
        
        self.points.removeAllObjects()
        self.recordArray.removeAll()
        for mark in self.subviews {
            mark.removeFromSuperview()
        }
        self.path = UIBezierPath()
        self.setNeedsDisplay()
        self.paths.removeAllObjects()
        lineCount = 0
        isDone = false
    }
    
    //    MARK: undo action
    
    /**
     undo operation
     - parameter sender: sidemenu Undo Button
     */
    public func undoPath(sender:UIButton){
        
        self.sideMenu_clipButton?.isSelected  = false
        self.sideMenu_clipButton?.isEnabled = false
        currentEvent = "Undo"
        if (freePathName.isEqual(to: "Free_S")) {
            
            self.paths.removeLastObject()
            
        }else if(freePathName.isEqual(to: "Free_C")){
            self.points.removeLastObject()
            self.path.removeAllPoints()// remove all points then afresh draw path
            self.paths.removeLastObject()// remove last path line
            removeControlMark()
        }
        
        // remove record startPoint last
        self.recordArray.removeLast()
        self.recordArray.removeLast()
        // remove mark label last and first
        self.subviews.last?.removeFromSuperview()
        lineCount -= 1
        isDone = false
        if let time = self.doneTimer {
            
            time.invalidate()
            for mark in self.subviews {
                
                if mark.layer.borderColor == UIColor.orange.cgColor{
                    mark.layer.borderColor = UIColor.white.cgColor
                }
            }
            
        }
        self.layoutSubviews()
        self.setNeedsDisplay()// afresh draw
        // change undo button state
        if self.paths.count == 0 {
            self.recordArray.removeAll()
            self.points.removeAllObjects()
            for marl in self.subviews {
                
                marl.removeFromSuperview()
                
            }
            sender.isEnabled = false;
            sender.isSelected = false;
            lineCount = 0
        }
        
    }
    
    /**
     done anmation
     */
    func doneAnimation() {
        
        isDone = true
        self.sideMenu_clipButton?.isSelected  = true
        self.sideMenu_clipButton?.isEnabled = true
        self.doneTimer = Timer.scheduledTimer(withTimeInterval:0.5, repeats: true) { (mer) in
            for endMark in self.subviews{
                
                if endMark.layer.borderColor == UIColor.white.cgColor{
                    
                    endMark.layer.borderColor = UIColor.orange.cgColor
                    
                }else
                {
                    endMark.layer.borderColor = UIColor.white.cgColor
                }
                
            }
        }
        
    }
    
    /**
     add mark label
     - parameter point: mark center
     */
    func addStartLineMarkview(point:CGPoint) {
        
        indexPath.removeAll()// the first remove data
        
        lineCount += 1
        let markLabel:MarkLabel = MarkLabel.init(frame: CGRect.init(x: 0, y:0, width: 20, height: 20))
        markLabel.center = point
        markLabel.bounds = CGRect.init(x: 0, y: 0, width:20, height: 20)
        markLabel.layer.borderWidth = 3
        markLabel.layer.borderColor = UIColor.white.cgColor
        markLabel.layer.cornerRadius = 10
        markLabel.layer.masksToBounds  = true
        markLabel.currentPathName = self.freePathName
        markLabel.backgroundColor = UIColor.black
        self.addSubview(markLabel)
        markLabel.text = "\(lineCount)"
        markLabel.textColor = UIColor.white
        markLabel.textAlignment = .center
        markLabel.font = UIFont.systemFont(ofSize: 10)
        markLabel.isUserInteractionEnabled = true
        
        if freePathName.isEqual(to: "Free_C") {
            
            //  add every one point 。must to afresh index
            let index = self.subviews.index(of:markLabel)!
            
            if index == self.subviews.count-1 {
                if isDone {
                    
                    indexPath.append(0)//first
                    indexPath.append(index)//
                }else
                {
                    indexPath.append(index-1)//0
                    indexPath.append(index)//1
                }
                
            }else if index == 0 {
                indexPath.append(self.subviews.count-1)//0
                indexPath.append(index)//1
                
            }else{
                indexPath.append(index-1)//0
                indexPath.append(index)//1
                
            }
        }
    }
    
    // add control mark label
    func addControllerMark(point:CGPoint,tag:Int)  {
        
        let markLabel:UILabel = UILabel.init(frame: CGRect.init(x: 0, y:0, width: 20, height: 20))
        markLabel.center = point
        markLabel.bounds = CGRect.init(x: 0, y: 0, width:20, height: 20)
        markLabel.layer.borderWidth = 3
        markLabel.layer.borderColor = UIColor.white.cgColor
        markLabel.layer.cornerRadius = 10
        markLabel.layer.masksToBounds  = true
        markLabel.backgroundColor = UIColor.black
        self.addSubview(markLabel)
        markLabel.text = "C\(tag)"
        markLabel.textColor = UIColor.white
        markLabel.textAlignment = .center
        markLabel.font = UIFont.systemFont(ofSize: 8)
        
    }
    
}

//MARK: ---mark  label class

class MarkLabel: UILabel {
    
    
    
    public var currentPathName:NSString = ""
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentPathName.isEqual(to: "Free_S") {
            superview?.touchesMoved(touches, with: event)
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
        self.isUserInteractionEnabled = false
        
    }
    
    
}

