//
//  WPAngleRuler.swift
//  WPImageEditor2
//
//  Created by pow on 2017/11/20.
//  Copyright © 2017年 pow. All rights reserved.
//

import UIKit

let markCellIdentifier = "markCellIdentifier"

protocol WPAngleRulerProtocol {
    
    func didScrollAngle(angle:CGFloat)
    func scrollRulerState(panGresture:UIPanGestureRecognizer)
    
}

class WPAngleRuler: UIView ,UICollectionViewDelegate,UICollectionViewDataSource{
    
    
    var rulerSources:[Int] = Array()
    
    var attachView:UIView?
    var lastclockwise_Angle:CGFloat = 0
    
    var delegate:WPAngleRulerProtocol?
    
    // point convet angle
    internal func  AngleBetweenPoints(loacationPoint locapoint:CGPoint, startPoint:CGPoint, centerPonit:CGPoint)->CGFloat {
        return atan2(locapoint.y - centerPonit.y, locapoint.x - centerPonit.x) - atan2(startPoint.y - centerPonit.y, startPoint.x - centerPonit.x);
    }
    
    lazy var angleCollectionView:CricleCollectionView = {
        let layout:RadianLayout = RadianLayout.init()
        let coll = CricleCollectionView.init(frame:CGRect.init(origin: CGPoint.zero, size: self.frame.size), collectionViewLayout: layout)
        coll.backgroundColor = UIColor.clear
        coll.delegate = self
        coll.dataSource = self
        self.addSubview(coll)
        
        return coll
    }()
    
    
    init(rulerDataSource:[Int],rotatedView:UIView) {
        super.init(frame:CGRect.zero)
        self.bounds = CGRect.init(x: 0, y: 0, width: compute_Size().width, height: compute_Size().height)
        self.center = CGPoint.init(x:UIScreen.main.bounds.width/2, y:UIScreen.main.bounds.height+(self.bounds.height/10))
        //        self.center = rotatedView.center
        self.rulerSources = rulerDataSource
        self.backgroundColor = UIColor.clear
        self.angleCollectionView.register(MarkCell.self, forCellWithReuseIdentifier:markCellIdentifier)
        let pan:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panGestureRecognizer(pan:)))
        self.addGestureRecognizer(pan)
        let arr:UIImageView = UIImageView.init(image: UIImage.init(named: "arrow", in: Bundle.init(for: WPAngleRuler.self), compatibleWith: nil))
        arr.frame = CGRect.zero
        arr.center = CGPoint.init(x: self.bounds.width/2, y:50)
        arr.bounds = CGRect.init(x: 0, y: 0, width:15, height:15)
        self.addSubview(arr)
        self.attachView = rotatedView
        NotificationCenter.default.addObserver(self, selector: #selector(willChnagngeStatusBarFrame), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
        
        
    }
    
    @objc func willChnagngeStatusBarFrame() {
        self.center = CGPoint.init(x:UIScreen.main.bounds.width/2, y:UIScreen.main.bounds.height+(self.bounds.height/10))
        
    }
    
    func compute_Size() -> CGSize {
        var width:CGFloat,height:CGFloat
        let min:CGFloat = UIScreen.main.bounds.width > UIScreen.main.bounds.height ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        width = min/2
        height = width
        return CGSize.init(width: width, height: height)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.rulerSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell:MarkCell = collectionView.dequeueReusableCell(withReuseIdentifier: markCellIdentifier, for: indexPath) as! MarkCell
        if self.rulerSources[indexPath.row]%18 == 0 {
            cell.addMarkNumber(angle:self.rulerSources[indexPath.row])
            if self.rulerSources[indexPath.row] == 90 || self.rulerSources[indexPath.row] == 180||self.rulerSources[indexPath.row] == 270||self.rulerSources[indexPath.row] == 0 {
                cell.markNumber.textColor = UIColor.orange
                
            }
        }
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func panGestureRecognizer(pan:UIPanGestureRecognizer){
        
        if pan.location(in: self).x >= self.frame.width || pan.location(in: self).x <= 0 {
            return
        }
        let degree:CGFloat = self.frame.width/90
        let point:CGPoint = pan.translation(in: self)
        let angle = DegreesToRadians(Double(point.x/degree))
        
        if pan.state == .changed {
            self.angleCollectionView.transform = CGAffineTransform.init(rotationAngle: CGFloat(angle)+lastclockwise_Angle)
            delegate?.didScrollAngle(angle:CGFloat(angle)+lastclockwise_Angle)
        }else if pan.state == .ended {
            lastclockwise_Angle = CGFloat(angle)+lastclockwise_Angle
        }
        delegate?.scrollRulerState(panGresture: pan)
    }
    
    
    
}

class MarkCell: UICollectionViewCell {
    
    var markNumber:UILabel = UILabel.init(frame: CGRect.zero)
    func addMarkNumber(angle:Int) {
        self.markNumber.text = "\(angle)"
        self.markNumber.frame = self.bounds
        self.markNumber.backgroundColor = UIColor.clear
        self.markNumber.textColor = UIColor.WP_Color_Conversion("08006D")
        self.markNumber.textAlignment = .center
        self.markNumber.font = UIFont.systemFont(ofSize: 12)
        self.addSubview(markNumber)
        
        
    }
    
}

class RadianLayout: UICollectionViewLayout {
    
    private var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    var center:CGPoint = CGPoint.zero
    var radius: CGFloat = 0.0
    var totalNum:Int = 0
    
    override func prepare() {
        super.prepare()
        totalNum = (collectionView?.numberOfItems(inSection: 0))!
        layoutAttributes = []
        center = CGPoint(x: Double(collectionView!.bounds.width * 0.5), y: Double(collectionView!.bounds.height * 0.5))
        radius = min(collectionView!.bounds.width, collectionView!.bounds.height)/3
        var indexPath: IndexPath
        for index in 0..<totalNum {
            indexPath = IndexPath.init(row: index, section: 0)
            let attributes = layoutAttributesForItem(at: indexPath)
            layoutAttributes.append(attributes!)
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let attributes :UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
        attributes.size = CGSize.init(width: 50, height: 50)
        let angle = 2 * CGFloat(Double.pi) * CGFloat(indexPath.row) / CGFloat(totalNum)+CGFloat(Double.pi/2)
        attributes.center = CGPoint(x: center.x + radius*cos(-angle), y: center.y + radius*sin(-angle))
        attributes.transform = CGAffineTransform.init(rotationAngle:CGFloat(-angle+CGFloat(DegreesToRadians(90))))
        return attributes
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    
    
    
}

class CricleCollectionView: UICollectionView {
    
    override func draw(_ rect: CGRect) {
        
        let circlePath:UIBezierPath =  UIBezierPath.init(arcCenter:CGPoint.init(x: self.bounds.width/2, y: self.bounds.height/2), radius: min(self.bounds.width, self.bounds.height) / 3.0-12, startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
        UIColor.WP_Color_Conversion("08006D").setStroke()
        circlePath.setLineDash([2], count:1, phase: 0)
        circlePath.lineJoinStyle = .round
        circlePath.lineWidth = 10
        circlePath.stroke()
        
    }
    
    
    
    
}


