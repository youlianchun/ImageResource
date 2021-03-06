//#!/usr/bin/env swift

//查找注视位置： DarkModeSuffix ，与lib保持一致
import Cocoa
import CoreImage

//scriptMian()

//https://developers.google.com/speed/webp/docs/cwebp
//var count = CommandLine.argc
//CommandLine.arguments[0]

// MARK: - func ==================

func scriptMian()->Bool {
    print("1. imageset 转WebP (cwebp)")
    print("   注: 产出增大时候会采用 [-lossless -q 100] 再次转换")
    print("2. imageset 文件名矫正")
    print("   注: imagesetName@2x.png、imagesetName_darkmode@2x.png")
    print("3. imageset 文件名矫正 + 转WebP")
    print("4. image 转WebP")
    print("5. image 倍图保留")
    print("X. 退出")

    let input = waitInput("X")
    if input != "1", input != "2", input != "3", input != "4", input != "5" {
        return false
    }

    let pathEcho = input == "4" || input == "5" ? "请输入imsge文件目录:" : "请输入*.imageset文件路径:"

    let spath = scriptPath()
    print(pathEcho)
    var path = waitInput()
    path = path.trimmingCharacters(in: .whitespaces)
    
    if path.count == 0 {
        path = spath
        print("采用脚本执行路径 y/n: \(spath)")
        let input = waitInput("y").uppercased()
        if input != "Y", input != "YES" {
            return true
        }
    }
    else {
        if !FileManager.default.fileExists(atPath: path)  {
            print("路径错误: \(path)")
            return true
        }
    }

    var lossless = true
    var quality = "\(100)"
    var outDir:String?
    if input == "1" || input == "3" || input == "4" {
        print("WebP质量 [0-100] (默认 -lossless 100): ")
        quality = waitInput("lossless")
        lossless = quality == "lossless"
        if !lossless {
            let qi = Int(quality) ?? 100
            quality = String(min(qi, 100))
        }
        
        print("WebP输出目录 (默认 原图片位置): ")
        var p = waitInput()
        p = p.trimmingCharacters(in: .whitespaces)
        
        if p.count > 0 {
            if FileManager.default.fileExists(atPath: p) {
                outDir = p
            }else {
                print("采用默认输出目录， 目录不存在: \(p)")
            }
        }
    }
    var scale:Int32 = 0
    if input == "5" {
        print("image 倍图保留 [1 2 3]: ")
        let input = waitInput()
        if input.count == 0 {
            return true
        }
        guard let s = Int32(input)  else {
            return true
        }
        scale = s
    }
    

    switch input {
        case "1":
            imageset2WebP(path:path, outDir:outDir, lossless:lossless, quality:quality)
        case "2":
            imagesetAdjust(path:path)
        case "3":
            imagesetAdjust(path:path)
            imageset2WebP(path:path, outDir:outDir, lossless:lossless, quality:quality)
        case "4":
            image2WebP(inDir:path, outDir:outDir, lossless:lossless, quality:quality)
        case "5":
            cleanOtherScaleImage(dir: path, scale: scale)
        default :
            break
    }
    return true
}

func imagesetAdjust(path:String) -> Void {
    print("矫正开始: \(path)")
    try? Traverse().traverseFile(path: path, callback: { (content, path) in
        if content == "Contents.json" {
            let dir = (path as NSString).deletingLastPathComponent
            let dirName = (dir as NSString).lastPathComponent
            if !dirName.hasSuffix(".imageset") {
               return
            }
            
            let url = URL(fileURLWithPath: path)
            guard let data = try? Data(contentsOf: url) else { return }
            guard var dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
            
            let fileName = dirName.prefix(dirName.count - 9)
            let images = dict["images"] as! [[String: Any]]
            var newImages = [[String: Any]]()
            
            for image in images {
                var newImage = image;
                if let name = image["filename"] as? String {
                    let exten =  (name as NSString).pathExtension
                    let scale = image["scale"] as! String
                    var suffix = ".\(exten)"
                    if scale != "1x" {
                        suffix = "@\(scale)\(suffix)"
                    }
                    if let appearances = image["appearances"] as? [[String: Any]] {
                        for appearance in appearances {
                            if appearance["appearance"] as! String == "luminosity" {
                                let model = appearance["value"] as! String
                                suffix = "_\(model)\(suffix)"
                            }
                        }
                    }
                    let newName = "\(fileName)\(suffix)"
                    
                    if newName != name {
                        do {
                            try FileManager.default.moveItem(atPath: "\(dir)/\(name)", toPath: "\(dir)/\(newName)")
                            newImage["filename"] = newName
                            print("\t\(dirName)\n\t\t\(name)\n\t\t\(newName)")
                        } catch {
                            print("\t失败: \(name)")
                        }
                    }
                    
                }
                newImages.append(newImage)
            }
            dict["images"] = newImages
            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else {
                return
            }
            try? jsonData.write(to: url)
        } else {
            
        }
    })
    print("矫正结束.")

}

func image2WebP(inDir:String, outDir:String? = nil, lossless:Bool, quality:String) -> Void {
    print("转换开始: \(inDir)")
    var total:(file:Int32, webp:Int32, reduce:UInt64, increase:UInt64) = (0, 0, 0, 0)
    var increaseArr = [(in:String, out:String, dif:DiffSize)]()
    var failureArr = [String]()
    try? Traverse().traverseFile(path: inDir, callback: { (content, filePath) in
        let exten = (content as NSString).pathExtension
        let extenCheckArr = ["PNG", "JPG", "GIF"];
        if !extenCheckArr.contains(exten.uppercased()) {
            return
        }
        total.file += 1
        var newName = (content as NSString).deletingPathExtension
        newName = "\(newName).webp"
        var dir = outDir ?? (filePath as NSString).deletingLastPathComponent
        if let oDir = outDir {
            if let newDir = cloneDir(dir: dir, fromDir: inDir, toDir: oDir) {
                dir = newDir
            }
        }
        var ofile = "\(dir)/\(newName)"
        
        let success = imageCompressToWebP(inFile: filePath, outFile: ofile, lossless: lossless, quality: quality)
        
        if success != nil {
            total.webp += 1
            if success!.reduced {
                total.reduce += success!.diffSize.value
            }else {
                total.increase += success!.diffSize.value
                increaseArr.append((filePath, ofile, success!))
            }
        }
        else {
            ofile = "\(dir)/\(content)"
            failureArr.append(filePath)
            if filePath != ofile {
                do {
                    try FileManager.default.copyItem(atPath: filePath, toPath: ofile)
                } catch  {
                    print("")
                }
            }
        }
    }, condition: { (dirPath) -> Bool in
        return dirPath.hasSuffix(".imageset") == false
    })
    print("\n转换结束.\n\t文件总数：\(total.file) 转换文件总数：\(total.webp) (-\(unitFormat1024(total.reduce))) (+\(unitFormat1024(total.increase)))")
    if increaseArr.count > 0 {
        print("产出增大:")
        for log in increaseArr {
            print("\t\(log.in)\n\t\t\(log.out)\n\t\t\(log.dif.kbStr)")
        }
    }
    if failureArr.count > 0 {
        print("转换失败:")
        for log in failureArr {
            print("\t\(log)")
        }
    }
}

func imageset2WebP(path:String, outDir:String? = nil, lossless:Bool, quality:String) -> Void {
    print("转换开始: \(path)")
    var increaseArr = [(in:String, out:String, dif:DiffSize)]()
    var failureArr = [String]()
    var total:(image:Int32, file:Int32, webp:Int32, reduce:UInt64, increase:UInt64) = (0, 0, 0, 0, 0)
    try? Traverse().traverseFile(path: path, callback: { (content, filePath) in
        if content == "Contents.json" {
            let dir = (filePath as NSString).deletingLastPathComponent
            let dirName = (dir as NSString).lastPathComponent
            if !dirName.hasSuffix(".imageset") {
               return
            }
            total.image += 1
            let url = URL(fileURLWithPath: filePath)
            guard let data = try? Data(contentsOf: url) else { return }
            guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
            
            let fileName = dirName.prefix(dirName.count - 9)
            
            let images = dict["images"] as! [[String: Any]]
            var hasDarkMode = false
            
            for image in images {
                if let name = image["filename"] as? String {
                    total.file += 1
                    let scale = image["scale"] as! String
                    var suffix = ".webp"
                    if scale != "1x" {
                        suffix = "@\(scale)\(suffix)"
                    }
                    if let appearances = image["appearances"] as? [[String: Any]] {
                        for appearance in appearances {
                            if appearance["appearance"] as! String == "luminosity" {
                                let model = appearance["value"] as! String
                                suffix = "_\(model)mode\(suffix)"   //DarkModeSuffix，与lib保持一致，此处采用小写
                                hasDarkMode = true
                            }
                        }
                    }
                    let ifile = "\(dir)/\(name)"
                    
                    let newName = "\(fileName)\(suffix)"

                    var imagesetDir = (dir as NSString).deletingLastPathComponent
                    if let oDir = outDir {
                        if let newDir = cloneDir(dir: imagesetDir, fromDir: path, toDir: oDir) {
                            imagesetDir = newDir
                        }
                    }
                    var ofile = "\(imagesetDir)/\(newName)"
                    
                    let success = imageCompressToWebP(inFile: ifile, outFile: ofile, lossless: lossless, quality: quality)
                    if success != nil {
                        total.webp += 1
                        if success!.reduced {
                            total.reduce += success!.diffSize.value
                        }else {
                            total.increase += success!.diffSize.value
                            increaseArr.append((filePath, ofile, success!))
                        }
                    }
                    else {
                        ofile = "\(imagesetDir)/\(name)"
                        failureArr.append(ifile)
                        if ifile != ofile {
                            do {
                                try FileManager.default.copyItem(atPath: ifile, toPath: ofile)
                            } catch  {
                                print("")
                            }
                        }
                    }
                }
            }
            if hasDarkMode {
                total.image += 1
            }
        } else {
            
        }
    })
    print("\n转换结束.\n\t图片总数：\(total.image) 文件总数：\(total.file) 转换文件总数：\(total.webp) (-\(unitFormat1024(total.reduce))) (+\(unitFormat1024(total.increase)))")
    if increaseArr.count > 0 {
        print("产出增大:")
        for log in increaseArr {
            print("\t\(log.in)\n\t\t\(log.out)\n\t\t\(log.dif.kbStr)")
        }
    }
    if failureArr.count > 0 {
        print("转换失败:")
        for log in failureArr {
            print("\t\(log)")
        }
    }
}

func cloneDir(dir:String, fromDir:String, toDir:String)->String? {
    if fromDir == dir {
        return toDir
    }
    var fDir = fromDir
    
    if !fDir.hasSuffix("/") {
        fDir = "\(fDir)/"
    }
    
    if !dir.hasPrefix(fDir) {
        return nil
    }
    
    let relativeDir = (dir as NSString).substring(from: fDir.count);
    let newDir = (toDir as NSString).appendingPathComponent(relativeDir);
    var isDir:ObjCBool = false
    let isExists = FileManager.default.fileExists(atPath: newDir, isDirectory: &isDir);
    if !isExists || !isDir.boolValue {
        do {
            let url = URL(fileURLWithPath: newDir)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            return newDir
        } catch {
            return nil
        }
    }
    return newDir
}

func cleanOtherScaleImage(dir:String, scale:Int32) {
    print("清理开始: \(dir)")
    var total:(image:Int32, file:Int32, save:Int32, size:UInt64, csize:UInt64) = (0, 0, 0, 0, 0)
    let assetDict = loadAsset(dir: dir)
    var logArr = [String]()
    for (_, typeDict) in assetDict {
        for (_, nameDict) in typeDict as! [String: Any] {
            for (_, styleDict) in nameDict as! [String: Any] {
                total.image += 1
                let dict = styleDict as! [String: [String]]
                var scaleKey = ""
                if let _ = dict["\(scale)"] {
                    scaleKey = "\(scale)"
                }
                else {
                    let scales = scale == 1 ? [2,3,1] : [3,2,1]
                    for i in scales {
                        if i == scale {
                            continue
                        }
                        if let _ = dict["\(i)"] {
                            scaleKey = "\(i)"
                        }
                    }
                }
                
                for (scale, paths) in dict {
                    for path in paths {
                        total.file += 1
                        let size = fileSize(path: path)
                        total.size += size
                        if scale != scaleKey {
                            do {
                                let url = URL(fileURLWithPath: path)
                                try FileManager.default.removeItem(at: url)
                                total.csize += size
                                print("\t\(path)")
                            } catch  {
                                logArr.append(path)
                            }
                        }
                        else {
                            total.save += 1
                        }
                    }
                }
            }
        }
    }
    print("\n清理结束.\n\t图片总数：\(total.image) 文件总数：\(total.file) 保留文件总数：\(total.save) (\(unitFormat1024(total.size)) - \(unitFormat1024(total.csize)) = \(unitFormat1024(total.size - total.csize)))")
    if logArr.count > 0 {
        print("清理失败:")
        for log in logArr {
            print("\t\(log)")
        }
    }
}

func defDictValue<T:NSObject>(_ dict:NSMutableDictionary, _ key:String) -> T {
    if let value = dict[key] as? T {
        return value
    }
    else {
        let value = T()
        dict[key] = value
        return value
    }
}

func loadAsset(dir:String)->[String: Any] {
    let assetDict = NSMutableDictionary()
    try? Traverse().traverseFile(path: dir, callback: { (content, path) in
        decodeName(fullName: content) { (name:String,  exten:String, scale:String, isDark: Bool) in
            
            let extenDict:NSMutableDictionary = defDictValue(assetDict, exten)
            let fileDict:NSMutableDictionary = defDictValue(extenDict, name)
            let styleDict:NSMutableDictionary = defDictValue(fileDict, styleKey(isDark: isDark))
            let scaleArr:NSMutableArray = defDictValue(styleDict, scale)
            scaleArr.add(path)
//            styleDict[scale] = path
        }
    })
    return assetDict as! [String:Any]
}

func styleKey(isDark:Bool)->String {
    if isDark {
        return "dark"
    }else {
        return "light"
    }
}

func decodeName(fullName:String, callback:((_ name:String, _ exten:String, _ scale:String, _ isDark: Bool)->Void))->Void {
    let exten = (fullName as NSString).pathExtension.uppercased()
    if exten.count == 0 {
        return
    }
    let extenCheckArr = ["PNG", "WEBP", "JPG", "GIF"];
    if !extenCheckArr.contains(exten) {
        return
    }
    var nameRegex:String!
    var scale = matcheRegex(string: fullName, regex: "(?<=@)(\\d.\\d)|(\\d)(?=x\\..*)").first ?? ""
    if scale.count == 0 {
        scale = "1"
        nameRegex = "^.*(?=\\..*)"
    }else {
        nameRegex = "^.*(?=(@((\\d)|(\\d.\\d))x)\\..*)"
    }
    
    guard var name = matcheRegex(string: fullName, regex: nameRegex).first else {
        return
    }
    let darkSuffix = "_DARKMODE"    //DarkModeSuffix，与lib保持一致，此处采用大写
    let isDark = name.uppercased().hasSuffix(darkSuffix)
    if isDark {
        name = (name as NSString).substring(to: name.count - darkSuffix.count)
    }

    callback(name, exten, scale, isDark)
}

func matcheRegex(string:String, regex:String)->[String] {
    var arr = [String]()
    if let regularExpression = try? NSRegularExpression(pattern: regex, options: .caseInsensitive) {
        let matches = regularExpression.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        for matche in matches {
            let str = (string as NSString).substring(with: matche.range)
            arr.append(str)
        }
    }
    return arr
}

func imageCompressToWebP(inFile:String, outFile:String, lossless:Bool, quality:String, checkSize:UInt64? = nil)->DiffSize? {
    //https://developers.google.com/speed/webp/docs/cwebp
    //cwebp 可执行文件路径
    let exten = (inFile as NSString).pathExtension.uppercased()
    let isGIF = exten == "GIF"
    
    #if DEBUG
    var executePath = isGIF ? "/Volumes/Macintosh_HD/works/BundleImage/ImageScript/bin/gif2webp" : "/Volumes/Macintosh_HD/works/BundleImage/ImageScript/bin/cwebp"
    #else
    var executePath = isGIF ? "./bin/gif2webp" : "./bin/cwebp"
    #endif
    
    let sPath = scriptPath()
    if !executePath.hasPrefix("/") {
        executePath = (sPath as NSString).appendingPathComponent(executePath)
        executePath = executePath.replacingOccurrences(of: "/./", with: "/")
    }
    
//    if isGIF {
//        executePath = "/Volumes/Macintosh_HD/works/BundleImage/Example/Script/ImageScript/bin/gif2webp"
//    }
//    else {
//        executePath = "/Volumes/Macintosh_HD/works/BundleImage/Example/Script/ImageScript/bin/cwebp"
//    }
    
    let inSize = fileSize(path:inFile)
    var ret = 0;
    if lossless {
        if isGIF {
            ret = Execution.execute(path: executePath, arguments:["-quiet", "-q", "100", inFile, "-o", outFile])
        }else {
            ret = Execution.execute(path: executePath, arguments:["-quiet", "-q", "100", inFile, "-o", outFile])
        }
        if ret == 0 {
            let outSize = fileSize(path:outFile)
            let dif = DiffSize(iSize: checkSize ?? inSize, oSize: outSize)
            print(successLog(difference: dif.kbStr, outFile: outFile))
            return dif
        }
    }
    else {
        if isGIF {
            ret = Execution.execute(path: executePath, arguments:["-quiet", "-lossy", "-q", quality, inFile, "-o", outFile])
        }else {
            var arguments:[String]
            if inSize < 80000 || checkSize != nil {
                arguments = ["-quiet", "-jpeg_like", "-q", quality, inFile, "-o", outFile]
            }else {
                arguments = ["-quiet", "-q", quality, inFile, "-o", outFile]
            }
            ret = Execution.execute(path: executePath, arguments:arguments)
        }
        if ret == 0 {
            let outSize = fileSize(path:outFile)
            if outSize > inSize {
                let oFile = (outFile as NSString).appendingPathExtension("tmp")!
                if isGIF {
                    ret = Execution.execute(path: executePath, arguments:["-quiet", "-q", "100", inFile, "-o", oFile])
                }else {
                    ret = Execution.execute(path: executePath, arguments:["-quiet", "-lossless", "-q", "100", inFile, "-o", oFile])
                }
                if ret == 0 {
                    let oSize = fileSize(path:oFile)
                    var size : UInt64
                    if oSize < outSize {
                        size = oSize
                        try? FileManager.default.removeItem(atPath: outFile)
                        try? FileManager.default.moveItem(atPath: oFile, toPath: outFile)
                    }
                    else {
                        size = outSize
                        try? FileManager.default.removeItem(atPath: oFile)
                    }
                    let dif = DiffSize(iSize: checkSize ?? inSize, oSize: size)
                    print(successLog(difference: dif.kbStr, outFile: outFile))
                    return dif
                }
            }else {
                let dif = DiffSize(iSize: checkSize ?? inSize, oSize: outSize)
                print(successLog(difference: dif.kbStr, outFile: outFile))
                return dif
            }
        }
    }
    
    let tmpTagFile = "xxxxxx_recodeImage_xxxxxx_tmp"
    if !inFile.contains(tmpTagFile) {
        let tmpFile = "\(sPath)/\(tmpTagFile).\(exten)"
        if recodeImage(inFile: inFile, outFile: tmpFile) {
            print("⚠️  ♻️  Recoded input file (\(formatString(Double(fileSize(path:tmpFile)) / 1024.0)) KB) '\(inFile)'")
            let ret = imageCompressToWebP(inFile: tmpFile, outFile: outFile, lossless: lossless, quality: quality, checkSize: inSize)
            try? FileManager.default.removeItem(atPath: tmpFile);
            return ret
        }
    }
    print("❌  ❌  Could not process input file '\(inFile)'")
    return nil

}

func successLog(difference:String, outFile:String)->String {
    return "🎉 \(difference.hasPrefix("-") ? "🎉" : "⚠️ ") Saved output file (\(difference)) '\(outFile)'"
}

func formatString(_ value:Double)->String {
    return String(format:"%.4f",value)
}

func recodeImage(inFile:String, outFile:String) -> Bool {
    if let data = try? Data(contentsOf: URL(fileURLWithPath: inFile)) as CFData {
        if let source = CGImageSourceCreateWithData(data, nil) {
            let count = CGImageSourceGetCount(source)
            let url = URL(fileURLWithPath: outFile)
            
            if let destination = CGImageDestinationCreateWithURL(url as CFURL,  count > 1 ? kUTTypeGIF : kUTTypePNG, count, nil) {
                for idx in 0 ..< count {
                    let properties = CGImageSourceCopyPropertiesAtIndex(source, idx, nil)
                    if let cgImage = CGImageSourceCreateImageAtIndex(source, idx, nil) {
                        CGImageDestinationAddImage(destination, cgImage, properties);
                    }
                }
                return CGImageDestinationFinalize(destination)
            }
        }
    }
    return false
}

func fileSize(path:String) -> UInt64 {
    var fileSize : UInt64 = 0
    if FileManager.default.fileExists(atPath: path) {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            fileSize = attr[FileAttributeKey.size] as! UInt64
        } catch {
            print("Error: \(error)")
        }
    }
    return fileSize
}


func waitInput(_ def:String = "")->String {
    if let input = readLine(), input.count > 0 {
        return input;
    } else {
        return def;
    }
}

func scriptPath()->String {
    let execPath = FileManager.default.currentDirectoryPath
    var script = CommandLine.arguments[0];
    if !script.hasPrefix("/") {
        script = (execPath as NSString).appendingPathComponent(script)
    }
    let path = (script as NSString).deletingLastPathComponent
    return path.replacingOccurrences(of: "/./", with: "/")
}

// MARK: - class ==================

class Execution {
    class func execute(path:String, arguments:[String]? = nil) -> Int {
        let task = Process();
        task.launchPath = path
        if let args = arguments {
           task.arguments = args
        }
//        let pip = Pipe()
//        task.standardOutput = pip
        task.launch()
        task.waitUntilExit()
        return Int(task.terminationStatus)
    }
}


class Traverse {
    private func traverse(path:String, callback: (_ content:String, _ isDir:Bool, _ path:String) throws ->Void) throws -> Void  {
        let contents = try FileManager.default.contentsOfDirectory(atPath: path)
        for content in contents {
            let p = "\(path)/\(content)"
            var isDir:ObjCBool = false
            if FileManager.default.fileExists(atPath: p, isDirectory: &isDir) {
                try callback(content, isDir.boolValue, p)
            }
        }
    }
    
    func traverseFile(path:String, callback: (_ content:String, _ path:String)->Void, condition:(_ path:String)->Bool = {_ in true}) throws -> Void  {
        if !condition(path) {return}
        try traverse(path: path) { (content, isDir, path) in
            if (isDir) {
                try traverseFile(path: path, callback: callback, condition: condition)
            }else {
                callback(content, path)
            }
        }
    }
    func traverseDir(path:String, callback: (_ content:String, _ path:String, _ excavate:inout Bool)->Void) throws -> Void  {
        try traverse(path: path) { (content, isDir, path) in
            if (isDir) {
                var excavate = true
                callback(content, path, &excavate)
                if excavate {
                    try traverseDir(path: path, callback: callback)
                }
            }
        }
    }
}

struct DiffSize {
    let iSize:UInt64
    let oSize:UInt64
    
    init(iSize:UInt64, oSize:UInt64) {
        self.iSize = iSize
        self.oSize = oSize
    }
    
    var reduced:Bool {
        return oSize <= iSize
    }
    
    var diffSize:(dif:String, value:UInt64) {
        let b = oSize <= iSize
        if b {
            return ("-", iSize - oSize)
        }else {
            return ("+", oSize - iSize)
        }
    }
    
    func diffStr(_ unit:(value:UInt64, name:String))->String {
        let size = self.diffSize
        return "\(size.dif)\(unitFormat(size.value, unit, 4))"
    }
    
    
    var kbStr:String {
        return diffStr((1024, "KB"))
    }
    
}

func unitFormat(_ value:UInt64, _ unit:(value:UInt64, name:String), _ dDigits: UInt = 2) -> String {
    let value = Double(value) / Double(unit.value)
    return String(format:"%.\(dDigits)f\(unit.name)", value)
}

func unitFormat(_ value:UInt64, _ unit:(value:UInt64, names:[String]), _ dDigits: UInt = 2) -> String {
    var dValue = Double(value)
    let dUnit = Double(unit.value)
    if dValue < dUnit {
        return String(format:"%.\(dDigits)f\(unit.names[0])", dValue)
    }
    var idx = 0
    for i in 1 ..< unit.names.count {
        dValue = dValue / dUnit
        if dValue < dUnit || i == unit.names.count - 1  {
            break
        }
        idx = i
    }
    
    return String(format:"%.\(dDigits)f\(unit.names[idx])", dValue)
}

func unitFormat1024(_ value:UInt64, _ dDigits: UInt = 2) -> String {
    return unitFormat(value, (1024, ["K", "M", "G", "T", "P"]), dDigits)
}

