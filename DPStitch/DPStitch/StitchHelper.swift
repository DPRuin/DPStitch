
import UIKit
import Photos
import CoreGraphics

let StitchWidth = 900
let MaxPhotosPerStitch = 6

let StitchAdjustmentFormatIdentifier = "pippa.stitch.adjustmentFormatID"


class StitchHelper: NSObject {
    
    /// Stitch Creation
    ///
    /// - Parameters:
    ///   - assets: 相片集
    ///   - collection: 相册文件夹
    class func createNewStitchWith(assets: [PHAsset], inCollection collection: PHAssetCollection) {
        // Create a new asset for the new stitch
        let stitchImage = self.createStitchImage(withAssets: assets)
        var stitchPlaceholder: PHObjectPlaceholder!
        PHPhotoLibrary.shared().performChanges({
            
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: stitchImage)
            stitchPlaceholder = assetChangeRequest.placeholderForCreatedAsset
            
            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: collection)
            let enumeration: NSArray = [stitchPlaceholder!]
            assetCollectionChangeRequest!.addAssets(enumeration)
            
        }) { (_, _) in
            // Fetch the asset and add modification data to it
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [stitchPlaceholder.localIdentifier], options: nil)
            let stitchAsset = fetchResult[0]
            self.editStitchContent(withStitch: stitchAsset, image: stitchImage, assets: assets)
            
        }
        
    }
    
    /// Stitch Content
    ///
    /// - Parameters:
    ///   - withStitch: 合并图
    ///   - image: 合并图
    ///   - assets: 相片集
    class func editStitchContent(withStitch stitch: PHAsset, image: UIImage, assets: [PHAsset]) {
        let stitchJPEG = UIImageJPEGRepresentation(image, 0.9)
        let assetIDs = assets.map { asset in
            (asset as PHAsset).localIdentifier
            
        }
        let assetsData = NSKeyedArchiver.archivedData(withRootObject: assetIDs)

        stitch.requestContentEditingInput(with: nil) { (contentEditingInput, _) in
            let adjustmentData = PHAdjustmentData(formatIdentifier: StitchAdjustmentFormatIdentifier, formatVersion: "1.0", data: assetsData)
            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
            do {
                try stitchJPEG!.write(to: contentEditingOutput.renderedContentURL, options: Data.WritingOptions.atomic)
            } catch  {
                print("stitchJPEGwriteError")
            }
            
            contentEditingOutput.adjustmentData = adjustmentData
            

            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest(for: stitch)
                request.contentEditingOutput = contentEditingOutput
                
            }, completionHandler: nil)
        }
    }
    
    /// 获取相册
    ///
    /// - Parameters:
    ///   - stitch: 合并图
    ///   - completion: block 相片集
    class func loadAssets(inStitch stitch: PHAsset, completion: @escaping ([PHAsset]) -> ()) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { adjustmentData in
            (adjustmentData.formatIdentifier == StitchAdjustmentFormatIdentifier) &&
                (adjustmentData.formatVersion == "1.0")
        }
        
        stitch.requestContentEditingInput(with: options) { (contentEditingInput, _) in
            if let adjustmentData = contentEditingInput?.adjustmentData {
                let stitchAssetsId = NSKeyedUnarchiver.unarchiveObject(with: adjustmentData.data) as! [String]
                
                let stitchAssetsFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: stitchAssetsId, options: nil)
                
                var stitchAssets: [PHAsset] = []
                stitchAssetsFetchResult.enumerateObjects({ (obj, _, _) in
                    stitchAssets.append(obj)
                })
                completion(stitchAssets)

            } else {
                completion([])
            }
        }
        
    }
    
    
    /// Stitch Image Creation
    ///
    /// - Parameter assets: 相片集
    /// - Returns: 合并图
    class func createStitchImage(withAssets assets: [PHAsset]) -> UIImage {
        var assetCount = assets.count
        
        // Cap to 6 max photos
        if (assetCount > MaxPhotosPerStitch) {
            assetCount = MaxPhotosPerStitch
        }
        
        // Calculate placement rects
        let placementRects = placementRectsForAssetCount(count: assetCount)
        
        // Create context to draw images
        let deviceScale = UIScreen.main.scale
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: StitchWidth, height: StitchWidth), true, deviceScale)
        
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        
        // Draw each image into their rect
        
        for (i, asset): (Int, PHAsset) in assets.enumerated() {
            if (i >= assetCount) {
                break
            }
            let rect = placementRects[i]
            
            let targetSize = CGSize(width: rect.width * deviceScale, height: rect.height * deviceScale)
            PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { (result, _) in
                if result!.size != targetSize {
                    let cropppedResult = self.cropImageToCenterSquare(image: result!, size: targetSize)
                    cropppedResult.draw(in: rect)
                } else {
                    result!.draw(in: rect)
                }
            })
        }
        
        // Grab results
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result!
    }
    
    private class func placementRectsForAssetCount(count: Int) -> [CGRect] {
        var rects: [CGRect] = []
        
        var evenCount: Int
        var oddCount: Int
        if count % 2 == 0 {
            evenCount = count
            oddCount = 0
        } else {
            oddCount = 1
            evenCount = count - oddCount
        }
        
        let rectHeight = StitchWidth / (evenCount / 2 + oddCount)
        let evenWidth = StitchWidth / 2
        let oddWidth = StitchWidth
        
        for i in 0..<evenCount {
            let rect = CGRect(x: i%2 * evenWidth, y: i/2 * rectHeight, width: evenWidth, height: rectHeight)
            rects.append(rect)
        }
        
        if oddCount > 0 {
            let rect = CGRect(x: 0, y: evenCount/2 * rectHeight, width: oddWidth, height: rectHeight)
            rects.append(rect)
        }
        
        return rects
    }
    
    // Helper to crop Image if it wasn't properly cropped
    private class func cropImageToCenterSquare(image: UIImage, size: CGSize) -> UIImage {
        let ratio = min(image.size.width / size.width, image.size.height / size.height)
        
        let newSize = CGSize(width: image.size.width / ratio, height: image.size.height / ratio)
        let offset = CGPoint(x: 0.5 * (size.width - newSize.width), y: 0.5 * (size.height - newSize.height))
        let rect = CGRect(origin: offset, size: newSize)
        
        UIGraphicsBeginImageContext(size)
        image.draw(in: rect)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return output!
    }
}
