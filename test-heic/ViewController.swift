//
//  ViewController.swift
//  test-heic
//
import UIKit
import Foundation

class ViewController: UIViewController {
    var img: UIImage!
    var mask: UIImage!
    var masked: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mask = UIImage(named: "mask")
        img = UIImage(named: "img")
        view.backgroundColor = UIColor.red
        masked = applyMask(mask!, toImage: img!, wideColor: false)
        
        let url = URL(fileURLWithPath: NSString(string:"~/Documents/output.heic").expandingTildeInPath)
        let rslt = exportHEIC(image: masked, url: url)
        print(rslt)
    }
    
    func exportHEIC(image: UIImage, url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.heic" as CFString, 1, nil),
            let cgImage = image.cgImage else {
                return false
        }
        
        CGImageDestinationAddImage(destination, cgImage, nil) // options as CFDictionary
        return CGImageDestinationFinalize(destination)
    }
    
    func applyMask(_ mask: UIImage, toImage: UIImage, wideColor: Bool) -> UIImage {
        let cgInputImage = CIImage(cgImage: toImage.cgImage!)
        let cgMaskImage = CIImage(cgImage: mask.cgImage!)
        
        //scale mask
        let scale = cgInputImage.extent.width/cgMaskImage.extent.width
        
        let filterMaskTransform = CIFilter(name: "CIAffineTransform")
        filterMaskTransform?.setValue(cgMaskImage, forKey: "inputImage")
        
        let transform = CGAffineTransform.init(scaleX: scale, y: scale)
        filterMaskTransform?.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
        
        guard let cgMaskScaled = filterMaskTransform?.outputImage else {
            return toImage
        }
        
        //blend
        let cgBackgroundImage = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.0 )).cropped(to: cgInputImage.extent)
        let blendWithAlphaMask = CIFilter(name: "CIBlendWithAlphaMask", withInputParameters: [
            "inputImage": cgInputImage,
            "inputBackgroundImage": cgBackgroundImage,
            "inputMaskImage": cgMaskScaled,
            ])!
        
        guard let outputImage = blendWithAlphaMask.outputImage else {
            return toImage
        }
        
        let context:CIContext!
        
        
        let colorSpace = wideColor ? CGColorSpace(name: CGColorSpace.displayP3) : CGColorSpace(name: CGColorSpace.extendedSRGB)
        
        if (wideColor) {
            context = CIContext(options:[ kCIContextWorkingFormat : Int(kCIFormatRGBAh)])
        } else {
            context = CIContext(options: nil)
        }
        
        let format = wideColor ? kCIFormatRGBAh : kCIFormatABGR8
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent, format: format, colorSpace: colorSpace) else {
            return toImage
        }
        let image = UIImage(cgImage: cgImage)
//        return UIImage(data: UIImagePNGRepresentation(image)!)!
        return image
    }

}

