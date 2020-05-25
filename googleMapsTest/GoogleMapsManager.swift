//
//  GoogleMapsManager.swift
//  googleMapsTest
//
//  Created by maxkitmac on 2020/3/17.
//  Copyright © 2020年 fredshao. All rights reserved.
//

import Foundation
import GoogleMaps

// MARK: - Class Data
// 有關地圖繪製所需要的所有資訊

fileprivate class GoogleMapsData {
    
    // 幾邊形
    static var NUM_OF_POLYGON = Int() // should be set once
    
    // 計算多邊形已經建立幾個頂點了, 預設值為-1, 表示還沒開始建立
    static var count = -1
    
    // 多邊形所有頂點座標
    static var polygonPoints = [CLLocationCoordinate2D]()
    
    // 存放多邊形所有頂點標誌
    static var polygonMarkers = [GMSMarker]()
    
    // 存放每次更新過(移動過)的多邊形所有頂點標誌
    static var updatedPolygonMarkers = [GMSMarker]()
    
    // 軌跡所有頂點標誌
    static var trackMarkers = [GMSMarker]()
    
    // 用來描述多邊形的物件, 把要畫線的路徑存起來
    static var polygonPath = GMSMutablePath()
    
    // 用來描述軌跡的物件, 把要畫多邊形的路徑線條存起來
    static var trackPath = GMSMutablePath()
    
    // 測試點有沒有在多邊形內
    static let testMarker = GMSMarker()
    
    // 繪製軌跡
    static var trackLine = GMSPolyline.init()
    
    // 繪製多邊形的線條
    static var polygonLines = [GMSPolyline]()
    
    // 填充多邊形區塊顏色
    static var polygonObject = GMSPolygon.init()
    
    // 目前所自訂的圍籬顏色
    static var currentColor: UInt?
}

// MARK: - Class

class GoogleMapsManager {
    
    // MAEK: - Properties
    
    static let shareInstance = GoogleMapsManager()
    
    // 多邊形各頂點是否已繪製完成
    static var isFinishDrawing = false
}

// MARK:- Public functions

extension GoogleMapsManager {
    
    // 取得目前多邊形所有頂點座標(包含最後一個同原點座標的頂點)
    func getPoints() -> [CLLocationCoordinate2D] {
        
        var newLocations = [CLLocationCoordinate2D]()
        
        for newPolygonPoint in GoogleMapsData.polygonPoints {
            newLocations.append(
                CLLocationCoordinate2D(latitude: newPolygonPoint.latitude, longitude: newPolygonPoint.longitude)
            )
        }
        
        // 最後一個點設為原點座標
        newLocations.append(CLLocationCoordinate2D(latitude: GoogleMapsData.polygonPoints[0].latitude, longitude: GoogleMapsData.polygonPoints[0].longitude))
        
        return newLocations
    }
    
    // 建立測試點
    func newTestPoint(coordinate: CLLocationCoordinate2D, mapView: GMSMapView) {
        GoogleMapsData.testMarker.position = coordinate
        GoogleMapsData.testMarker.isDraggable = false
        GoogleMapsData.testMarker.title = "Test Point"
        GoogleMapsData.testMarker.snippet = ""
        GoogleMapsData.testMarker.map = mapView
    }
    
    // 建立多邊形的每一個頂點
    func newPoint(coordinate: CLLocationCoordinate2D, forPolygon mapView: GMSMapView) {
        
        let marker = GMSMarker()
        
        marker.position = coordinate
        marker.isDraggable = true
        marker.title = "Point" + "\(GoogleMapsData.count)" // 以 Point0/ Point1/ ... 為鍵值
        marker.snippet = (GoogleMapsData.count == 0) ? "Original Point" : nil
        marker.icon = (GoogleMapsData.currentColor != nil) ?
            getMarkImage(withColor: UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 1.0)) :
            getMarkImage(withColor: UIColorFromRGB(rgbValue: 0xFF0000, alpha: 1.0))
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5) // 讓每一個頂點之間的連線是以marker的中心點為連接點
        marker.map = mapView
        
        GoogleMapsData.polygonPoints.append(coordinate) // 存頂點
        GoogleMapsData.polygonMarkers.append(marker)    // 存標誌
        GoogleMapsData.polygonPath.add(coordinate)      // 存要畫線的路徑
        
        // 每次畫完一個頂點GoogleMapsData.count就加一
        GoogleMapsData.count += 1
        
        if !checkFinishDrawing() {
            drawPolygon(mapView: mapView)
        }
        
    }
    
    func dragPoint(_ isEnable: Bool) {
        for marker in GoogleMapsData.polygonMarkers {
            marker.isDraggable = (isEnable == true) ? true : false
        }
    }
    
    func setColor(_ color: UInt) {
        
        GoogleMapsData.currentColor = color
        
        // 頂點標誌
        for marker in GoogleMapsData.polygonMarkers {
            marker.icon = getMarkImage(withColor: UIColorFromRGB(rgbValue: color, alpha: 1.0))
        }
        
        // 移動過的標誌(未畫完之前)
        for marker in GoogleMapsData.updatedPolygonMarkers {
            marker.icon = getMarkImage(withColor: UIColorFromRGB(rgbValue: color, alpha: 1.0))
        }
        
        // 線條顏色
        for polygonLine in GoogleMapsData.polygonLines {
           polygonLine.strokeColor = UIColorFromRGB(rgbValue: color, alpha: 1.0)
        }
        
        // 區塊顏色
        GoogleMapsData.polygonObject.fillColor = UIColorFromRGB(rgbValue: color, alpha: 0.2)
    }
    
    // 編輯已存在的電子圍籬
    func editPoints(coordinates: [CLLocationCoordinate2D], forTrack mapView: GMSMapView) {
        
        // 設定此電子圍籬為幾邊形.
        // EX: 實際上三邊(角)形會有四個頂點, 第四個點(座標同第一個點)是為了要把最後一條連接原點的線畫出來, 所以必須再減一才是我們一般認知的三邊形
        GoogleMapsData.NUM_OF_POLYGON = coordinates.count - 1
        
        startAddingVertex()
        
        for (index, coordinate) in coordinates.enumerated() {
            
            // 是否為最後一個頂點
            if index == coordinates.count - 1 {
                // 把路徑的最後一個點的座標設為原點座標, 因為要把最後一條連接原點的線畫出來, 所以現在的GoogleMapsData.count為4
                GoogleMapsData.polygonPath.add(GoogleMapsData.polygonPoints[0])
                
                // 設定已繪製完成, 讓多邊形填充內部顏色
                GoogleMapsManager.isFinishDrawing = true
            } else {
                let marker = GMSMarker()
                
                marker.position = coordinate
                //marker.isDraggable = true // 由dragPoint()來控制是否被拖曳
                marker.title = "Point" + "\(index)"
                marker.snippet = (GoogleMapsData.count == 0) ? "Original Point" : nil
                marker.icon = (GoogleMapsData.currentColor != nil) ?
                    getMarkImage(withColor: UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 1.0)) :
                    getMarkImage(withColor: UIColorFromRGB(rgbValue: 0xFF0000, alpha: 1.0))
                marker.groundAnchor = CGPoint(x: 0.5, y: 0.5) // 讓每一個頂點之間的連線是以marker的中心點為連接點
                marker.map = mapView
                
                GoogleMapsData.polygonPoints.append(coordinate) // 存頂點
                GoogleMapsData.polygonMarkers.append(marker)    // 存標誌
                GoogleMapsData.polygonPath.add(coordinate)      // 存要畫線的路徑
                
                // 每次畫完一個頂點GoogleMapsData.count就加一
                GoogleMapsData.count += 1
            }
            
            drawPolygon(mapView: mapView)
        }
    }
    
    // 建立軌跡的每一個頂點, 單純顯示軌跡
    func newPoints(coordinates: [CLLocationCoordinate2D], forTrack mapView: GMSMapView) {
        for (index, coordinate) in coordinates.enumerated() {
            let marker = GMSMarker()
            
            marker.position = coordinate
            marker.isDraggable = false
            marker.title = "Point" + "\(index)"
            marker.snippet = nil
            marker.icon = (GoogleMapsData.currentColor != nil) ?
                getMarkImage(withColor: UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 1.0)) :
                getMarkImage(withColor: UIColorFromRGB(rgbValue: 0xFF0000, alpha: 1.0))
                
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5) // 讓每一個頂點之間的連線是以marker的中心點為連接點
            marker.map = mapView
            
            GoogleMapsData.trackMarkers.append(marker)
            GoogleMapsData.trackPath.add(coordinate)
        }
        drawTrack(mapView: mapView)
    }
    
    // 退回上一步
    func deletePreviousPonint(mapView: GMSMapView) {
        
        if GoogleMapsData.count >= 1 {
            
            // 將地圖上顯示的最後一個標誌清掉
            GoogleMapsData.polygonMarkers[GoogleMapsData.count - 1].map = nil
            
            // 移除最後一個標誌
            GoogleMapsData.polygonMarkers.removeLast()
            
            // 移除最後一個頂點
            GoogleMapsData.polygonPoints.removeLast()
            
            // 移除最後一條線的路徑
            
            GoogleMapsData.polygonPath.removeLastCoordinate()
            
            if !checkFinishDrawing() {
                reDrawing(mapView: mapView)
            }
            GoogleMapsData.count -= 1
        }
    }
    
    // 檢查某座標是否在多邊形內
    func checkIsInPolygon(coordinate: CLLocationCoordinate2D) -> Bool {
        let testPoint = CGPoint(x: coordinate.latitude, y: coordinate.longitude)
        
        // 不取最後一點原點, 幾邊形則取幾個頂點. EX: 五邊形取五個頂點
        let polygon = GoogleMapsData.polygonPoints.map {
            (coor: CLLocationCoordinate2D) -> CGPoint in
            return CGPoint(x: coor.latitude, y: coor.longitude)
        }
        return contains(polygon: polygon, test: testPoint)
    }
    
    // 開始繪製多邊形頂點
    func startAddingVertex() {
        GoogleMapsData.count = 0
    }
    
    // 完成繪製多邊形
    func finishAddingVertex(mapView: GMSMapView) -> Bool{
        
        // 目前已建立的多邊形頂點數目
        if GoogleMapsData.count >= 3 {
            // 設定目前為幾邊形
            GoogleMapsData.NUM_OF_POLYGON = GoogleMapsData.count
            
            // 設定已繪製完成
            GoogleMapsManager.isFinishDrawing = true
            
            // 檢查是否已經繪製完成
            if checkFinishDrawing() {
                // 把路徑的最後一個點的座標設為原點座標, 因為要把最後一條連接原點的線畫出來, 所以現在的GoogleMapsData.count為4
                GoogleMapsData.polygonPath.add(GoogleMapsData.polygonPoints[0])
            }
            
            drawPolygon(mapView: mapView)
            
            return true
        } else {
            print("至少繪製三個點")
            return false
        }
    }
    
    // 檢查多邊形是否已繪製完成
    func checkFinishDrawing() -> Bool {
        return (GoogleMapsManager.isFinishDrawing == true) ? true : false
    }
    
    // 移除測試點的標誌
    func removeTestPointMark() {
        GoogleMapsData.testMarker.map = nil
    }
    
    // 移除軌跡的所有標誌
    func removeTrackMarks() {
        for marker in GoogleMapsData.trackMarkers {
            marker.map = nil
        }
    }

    // 移除軌跡
    func removeTrack() {
        GoogleMapsData.trackLine.map = nil
    }
    
    // 移除多邊形的所有標誌
    func removePolygonMarks() {
        for marker in GoogleMapsData.polygonMarkers {
            marker.map = nil
        }
        for marker in GoogleMapsData.updatedPolygonMarkers {
            marker.map = nil
        }

    }
    
    // 移除多邊形
    func removePolygon() {
        
        for polygonLine in GoogleMapsData.polygonLines {
            polygonLine.map = nil
        }
    }
    
    func removePolygonColor() {
        GoogleMapsData.polygonObject.map = nil
    }
    
    func resetMap(mapView: GMSMapView) {
        mapView.clear()
        resetDrawingPolygon()
        resetDrawingTrack()
        GoogleMapsData.count = -1
        GoogleMapsManager.isFinishDrawing = false
        
    }
    
    func resetDrawingPolygon() {
        GoogleMapsData.polygonPoints.removeAll()
        GoogleMapsData.polygonMarkers.removeAll()
        GoogleMapsData.updatedPolygonMarkers.removeAll()
        GoogleMapsData.polygonLines.removeAll()
        GoogleMapsData.polygonPath.removeAllCoordinates()
    }
    
    func resetDrawingTrack() {
        GoogleMapsData.trackPath.removeAllCoordinates()
    }

    // 移動多邊形某頂點時, 更新其位置
    func modifyPoint(newMarker: GMSMarker, mapView: GMSMapView) {
        for (index, marker) in GoogleMapsData.polygonMarkers.enumerated() {
            // 找到現在要拖曳的點, 目前是以title為鍵值
            if marker.title == newMarker.title {
                GoogleMapsData.polygonMarkers[index].position = newMarker.position
                GoogleMapsData.polygonPoints[index] = newMarker.position
                GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(index), with: newMarker.position)
            }
        }
        
        // 多邊形已畫完
        if checkFinishDrawing() {
            // 原點(第一個點)鍵值
            let originalPoint = "Point0"
            
            // 如果現在移動的是原點, 也一併把路徑的最後一個點重設為原點, 因為要把最後一個頂點連接原點的線畫出來
            if newMarker.title == originalPoint {
                GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(GoogleMapsData.NUM_OF_POLYGON), with: GoogleMapsData.polygonPoints[0])
            }
        }
        reDrawing(mapView: mapView)
    }
}

// MARK:- Private functions

extension GoogleMapsManager {
    
    // 取得標誌的圖
    private func getMarkImage(withColor color: UIColor) -> UIImage{
        // 外圈
        let markView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        markView.backgroundColor = color
        markView.layer.cornerRadius = markView.frame.size.width / 2
        markView.clipsToBounds = true
        
        // 內圈
        let markSubView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        markSubView.center = CGPoint(x: markView.bounds.size.width / 2, y: markView.bounds.size.height / 2)
        markSubView.backgroundColor = .white
        markSubView.layer.cornerRadius = markSubView.frame.size.width / 2
        markSubView.clipsToBounds = true
        

        markView.addSubview(markSubView)
        
        return markView.asImage()
    }
    
    // 算出該點有沒有在多邊形內
    private func contains(polygon: [CGPoint], test: CGPoint) -> Bool {
        if polygon.count <= 1 {
            return false //or if first point = test -> return true
        }
        
        let p = UIBezierPath()
        let firstPoint = polygon[0] as CGPoint
        
        p.move(to: firstPoint)
        
        for index in 1...polygon.count-1 {
            p.addLine(to: polygon[index] as CGPoint)
        }
        
        p.close()
        
        return p.contains(test)
    }
    
    // 繪製軌跡
    private func drawTrack(mapView: GMSMapView) {
        GoogleMapsData.trackLine = GMSPolyline(path: GoogleMapsData.trackPath)
        GoogleMapsData.trackLine.map = mapView
        GoogleMapsData.trackLine.strokeColor = (GoogleMapsData.currentColor != nil) ?
            UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 1.0) :
            UIColorFromRGB(rgbValue: 0xFF0000, alpha: 1.0)
        GoogleMapsData.trackLine.strokeWidth = 5
    }
    
    // 繪製多邊形
    private func drawPolygon(mapView: GMSMapView) {
        let polygonLine = GMSPolyline(path: GoogleMapsData.polygonPath)
        
        polygonLine.map = mapView
        
        // 線條顏色
        polygonLine.strokeColor = (GoogleMapsData.currentColor != nil) ?
            UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 1.0) : UIColorFromRGB(rgbValue: 0xFF0000, alpha: 1.0)
        
        // 線條粗細
        polygonLine.strokeWidth = 5
        
        GoogleMapsData.polygonLines.append(polygonLine)
        
        if checkFinishDrawing() {
            fillPolygonColor(mapView: mapView)
        }
    }
    
    // 將多邊形內部填滿顏色
    private func fillPolygonColor(mapView: GMSMapView) {
        GoogleMapsData.polygonObject = GMSPolygon()
        
        GoogleMapsData.polygonObject.path = GoogleMapsData.polygonPath
        
        // 多邊形區塊顏色
        GoogleMapsData.polygonObject.fillColor = (GoogleMapsData.currentColor != nil) ?
            UIColorFromRGB(rgbValue: GoogleMapsData.currentColor!, alpha: 0.2) : UIColorFromRGB(rgbValue: 0xFF0000, alpha: 0.2)
        
        GoogleMapsData.polygonObject.map = mapView
    }
    
    private func UIColorFromRGB(rgbValue: UInt, alpha: Float) -> UIColor {
        return UIColor(
            red:   CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat(rgbValue  & 0x0000FF)        / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
    private func reDrawing(mapView: GMSMapView) {

        // 每次在重畫地圖時, 都要先移除前一個畫面所用到的畫面資訊:
        // 1. 清除目前地圖上的圖示
        removePolygonMarks() // 多邊形的標誌
        removePolygon()      // 多邊形
        removePolygonColor() // 多邊形裡面的顏色
        
        // 2.清空在繪製地圖時用到的陣列
        GoogleMapsData.updatedPolygonMarkers.removeAll()
        GoogleMapsData.polygonLines.removeAll()
        
        
        // 重新繪製多邊形標誌
        for marker in GoogleMapsData.polygonMarkers {
            
            let m = GMSMarker.init()
            m.position     = marker.position
            m.isDraggable  = marker.isDraggable
            m.title        = marker.title
            m.snippet      = marker.snippet
            m.icon         = marker.icon
            m.groundAnchor = marker.groundAnchor
            m.map          = mapView

            GoogleMapsData.updatedPolygonMarkers.append(m)

        }
        drawPolygon(mapView: mapView)
    }
}

// MARK:- UIView: New Method

extension UIView {
    
    // UIView convert to UIImage
    func asImage() -> UIImage {
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContext(self.frame.size)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
}
