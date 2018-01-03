//
//  ViewController.swift
//  DPStitch
//
//  Created by 土老帽 on 2018/1/2.
//  Copyright © 2018年 DPRuin. All rights reserved.
//

import UIKit
import Photos

let StitchesAlbumTitle = "Stitches"

class ViewController: UIViewController, DXPhotoPickerControllerDelegate {
    
    var images: [PHAsset] = []
    private var stitchesCollection: PHAssetCollection!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch stitches album
        // 1
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", StitchesAlbumTitle)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        
        //2
        if collections.count > 0 {
            //Album exists
            self.stitchesCollection = collections[0]
        } else {
            // Create the album
            // 1
            var assetPlaceholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: StitchesAlbumTitle)
                assetPlaceholder = changeRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { (isSuccess, error) in
                if !isSuccess {
                    print("Failed to create album")
                    print(error!)
                    return
                }
                let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetPlaceholder!.localIdentifier], options: nil)
                if collections.count > 0 {
                    self.stitchesCollection = collections[0]
                }
                
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func stitchBtn(_ sender: UIButton) {

        let picker = DXPhotoPickerController()
        picker.photoPickerDelegate = self
        self.present(picker, animated: true, completion: nil)
        
    }
    
    @IBAction func saveToPhotoLibrary(_ sender: UIButton) {
        print("saveToPhotoLibrary")

        
        StitchHelper.createNewStitchWith(assets: self.images, inCollection: self.stitchesCollection)
        
        
    }
    
    func photoPickerDidCancel(photoPicker: DXPhotoPickerController) {
        photoPicker.dismiss(animated: true, completion: nil)
    }
    
    func photoPickerController(photoPicker: DXPhotoPickerController?, sendImages: [PHAsset]?, isFullImage: Bool) {
        photoPicker?.dismiss(animated: true, completion: nil)
        
        print("hhhhh\(String(describing: sendImages?.count))")
        self.images = sendImages!

        
        
    }




}

