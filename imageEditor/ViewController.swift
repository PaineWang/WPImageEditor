//
//  ViewController.swift
//  WPImageEditor2
//
//  Created by pow on 2017/11/9.
//  Copyright © 2017年 pow. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        addEditorImageView(originalImage: UIImage.init(named: "ape_fwk_all")!)
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func addEditorImageView(originalImage:UIImage) {

        let baseView:WPBaseEditorView =  WPBaseEditorView.loadNibFileToSetup(editorImage:originalImage , InSuperView: self.view)
         baseView.moveableArea = self.view.frame
        baseView.setup()
        baseView.pasteBlock = {(image, bounds) in
            
            self.backImage(image: image, point: bounds)
            
        }
    }
    
    func backImage(image:UIImage,point:CGRect) {
        
        let imgView = UIImageView.init(image: image)
        
        
        
        imgView.frame = point
        
        imgView.backgroundColor = UIColor.black
        self.view.addSubview(imgView)
        
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
           
            picker.dismiss(animated: true, completion: {
                
                
                self.addEditorImageView(originalImage:info[UIImagePickerControllerOriginalImage] as! UIImage)
                          
            })
        }
    }
    
    
    override var shouldAutorotate: Bool {
        return false
    }
    
 
    
    
    
    
}

