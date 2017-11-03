//
//  ShapeCollectionViewCell.swift
//  layerDraw
//
//  Created by WANG on 2017/9/8.
//  Copyright © 2017年 pow. All rights reserved.
//

import UIKit

public enum ShapeType :String  {
    case Cercle
    case Triangle
    case Rectangle
    case Oval
    case Free_C
    case Free_S
    case Polygon 
}



class ShapeCollectionViewCell: UICollectionViewCell {
    
    
    open var shapeName:String = ""
    
    open var currentPath:UIBezierPath?
    
    open func  setshapeName(_ name:String){
        self.shapeName = name
        self.draw(self.bounds)
        
    }
    var space:CGFloat = 2

    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        var path = UIBezierPath()
        
        switch shapeName {
        case ShapeType.Cercle.rawValue:
            
            path = UIBezierPath.init(roundedRect:CGRect.init(x:space, y:space, width: self.bounds.width-space*2, height: self.bounds.height-space*2), cornerRadius: self.bounds.height/2)
            
        case ShapeType.Triangle.rawValue:
            
            path.move(to: CGPoint.init(x: self.bounds.width-space, y: self.bounds.height-space))
            path.addLine(to: CGPoint.init(x: self.bounds.width/2, y:space))
            path.addLine(to: CGPoint.init(x: space, y:self.bounds.height-space))
            path.addLine(to: CGPoint.init(x:  self.bounds.width-space, y:self.bounds.height-space))
            
        case ShapeType.Rectangle.rawValue:
            
            path = UIBezierPath(rect: CGRect.init(x: space, y: space, width: self.bounds.width-space*2, height: self.bounds.height-space*2))
            
        case ShapeType.Oval.rawValue:
            
            path = UIBezierPath.init(ovalIn: CGRect.init(x: space, y: space, width: self.frame.width-space*2, height: self.frame.height-space*4))
            
            
        case ShapeType.Free_C.rawValue:
            
            path.move(to: CGPoint.init(x:space, y:self.frame.height-space))
            path.addCurve(to:CGPoint.init(x: self.frame.width-space, y:space), controlPoint1: CGPoint.init(x: self.frame.width/3, y: self.frame.height/3), controlPoint2: CGPoint.init(x: self.frame.width - self.frame.width/3, y: self.frame.height - self.frame.height/3))
            
            //            path.setLineDash([2,5,2], count:8, phase:10)
            
        case ShapeType.Free_S.rawValue:
            
            
            path.move(to: CGPoint.init(x:space, y:self.frame.height-space))
            path.addLine(to:  CGPoint.init(x:self.frame.width - space, y:space))
            
            
        case ShapeType.Polygon.rawValue:
            
            path.move(to: CGPoint.init(x: self.frame.width/2, y: space))
            path.addLine(to: CGPoint.init(x: space, y: self.frame.height/2))
            path.addLine(to: CGPoint.init(x:  self.frame.width/2, y: self.frame.height-space*2))
            path.addLine(to: CGPoint.init(x: self.frame.width-space, y: self.frame.height/2))
            path.addLine(to: CGPoint.init(x: self.frame.width/2, y: space))
            
        default:
            
            print("没加载")
            
        }
        path.lineWidth = 2
        UIColor.WP_Color_Conversion("08006D").set()
        path.stroke()
        
        self.currentPath = path
        
        
        
        
    }
    
    
    
    
    
}
