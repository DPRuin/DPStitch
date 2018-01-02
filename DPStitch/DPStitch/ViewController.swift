//
//  ViewController.swift
//  DPStitch
//
//  Created by 土老帽 on 2018/1/2.
//  Copyright © 2018年 DPRuin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func stitchBtn(_ sender: UIButton) {

        // 判断照片是否可用
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            
            self.present(imagePicker, animated: true, completion: {
                print("model")
            })
        } else {
            print("not")
        }
        
    }
    
    @IBAction func saveToPhotoLibrary(_ sender: UIButton) {
        
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info["UIImagePickerControllerEditedImage"] as! UIImage
        self.addImage(image)
        
        //  关闭相片选择器
        self.dismiss(animated: true) {
            
        }
        
        
        
    }
    
    func addImage(_ image: UIImage) {
        let imageView 
    }



}

