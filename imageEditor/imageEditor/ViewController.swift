//
//  ViewController.swift
//  drawCenterView
//
//  Created by WANG on 2017/9/12.
//  Copyright © 2017年 WANG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    var shapeBackGroudImageView:WPBaseView?
    
    var edtingImage:UIImage?
    
    var path:UIBezierPath = UIBezierPath()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

       
    
    func addEditorImageView(originalImage:UIImage) {
        
        self.shapeBackGroudImageView = WPBaseView.loadSizeViewWithNibFile(originalImage, inSuperView: self.view)
        self.view.addSubview(self.shapeBackGroudImageView!)
        self.shapeBackGroudImageView?.pasteOrClipblockCallBackValue(Actionblock: { (image,point) in
            self.backImage(image: image,point:point)
            
            
            
        })
        
        
        
    }
    
   
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func backImage(image:UIImage,point:CGRect) {
        
        
        let imgView = UIImageView.init(image: image)
        
        
        
        imgView.frame = point
        
        imgView.backgroundColor = UIColor.black
        self.view.addSubview(imgView)
        self.shapeBackGroudImageView?.removeFromSuperview()
            
    }


   
}





//MARK:Import images from Photos Library
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    
   @IBAction  func performImport2(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if (info[UIImagePickerControllerOriginalImage] as? UIImage) != nil {
            //            PaintingUtil.importImage(image, controller: self)
//            DispatchQueue.main.async {
////                self.isDirty = true
//            }
            picker.dismiss(animated: true, completion: {
                
                
                self.addEditorImageView(originalImage:info[UIImagePickerControllerOriginalImage] as! UIImage)
                
//            self.view.addSubview(WPBaseView.loadSizeViewWithNibFile(info[UIImagePickerControllerOriginalImage] as! UIImage, inSuperView: self.view))
                
                
                        
            })
        }
    }
    
    
    
}

