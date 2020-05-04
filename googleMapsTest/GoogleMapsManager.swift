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

class GoogleMapsData {
    // 幾邊形
    static var NUM_OF_POLYGON = Int() // should be set once
    
    // 計算多邊形已經建立幾個頂點了
    static var count = -1
    
    // 多邊形所有頂點座標
    static var polygonPoints = [CLLocationCoordinate2D]()
    
    // 存放多邊形所有頂點標誌
    static var polygonMarkers = [GMSMarker]()
    
    // 軌跡所有頂點標誌
    static var trackMarkers = [GMSMarker]()
    
    // 用來描述多邊形的物件, 把要畫線的路徑存起來
    static var polygonPath = GMSMutablePath()
    
    // 用來描述軌跡的物件, 把要畫多邊形的路徑線條存起來
    static var trackPath = GMSMutablePath()
    
    // 測試點
    static let testMarker = GMSMarker()
    
    // 繪製軌跡
    static var trackLine = GMSPolyline.init()
    
    // 繪製多邊形的線條
    static var polygonLines = [GMSPolyline]()
    
    // 繪製多邊形裡面的顏色
    static var polygonObject = GMSPolygon.init()
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
        marker.snippet = (GoogleMapsData.count == 0) ? "Original Point" : ""
        marker.icon = UIImage(named: "warning-icon")
        marker.map = mapView
        
        GoogleMapsData.polygonPoints.append(coordinate) // 存頂點
        GoogleMapsData.polygonMarkers.append(marker) // 存標誌
        
        GoogleMapsData.polygonPath.add(coordinate) // 存要畫線的路徑
        
        // 每次畫完一個頂點GoogleMapsData.count就加一
        GoogleMapsData.count += 1
        
        if !checkFinishDrawing() {
            drawPolygon(mapView: mapView)
        }
        
    }
    
    // 建立軌跡的每一個頂點
    func newPoints(coordinates: [CLLocationCoordinate2D], forTrack mapView: GMSMapView) {
        for (index, coordinate) in coordinates.enumerated() {
            let marker = GMSMarker()
            
            marker.position = coordinate
            marker.isDraggable = false
            marker.title = "Point" + "\(index)"
            marker.snippet = ""
            marker.icon = UIImage(named: "walk-icon")
            marker.map = mapView
            
            GoogleMapsData.trackMarkers.append(marker)
            GoogleMapsData.trackPath.add(coordinate)
        }
        drawTrack(mapView: mapView)
    }
    
    func deletePreviousPonint(mapView: GMSMapView) {
        if GoogleMapsData.count >= 1 {
            
            
            GoogleMapsData.polygonPoints.removeLast()
            GoogleMapsData.polygonMarkers.removeLast()
            GoogleMapsData.polygonPath.removeLastCoordinate()
            
            if !checkFinishDrawing() {
                mapView.clear()
                reDrawing(mapView: mapView)
            }
            GoogleMapsData.count -= 1
        }
    }
    
    func checkIsInPolygon(coordinate: CLLocationCoordinate2D) -> Bool {
        let testPoint = CGPoint(x: coordinate.latitude, y: coordinate.longitude)
        let polygon = GoogleMapsData.polygonPoints.map {
            (coor: CLLocationCoordinate2D) -> CGPoint in
            return CGPoint(x: coor.latitude, y: coor.longitude)
        }
        return contains(polygon: polygon, test: testPoint)
    }
    
    // 選擇為幾邊形
    func setNumOfPolygon(num: Int) {
        GoogleMapsData.count = num
        GoogleMapsData.NUM_OF_POLYGON = num
    }
    
    func startAddingVertex() {
        GoogleMapsData.count = 0
    }
    
    func finishAddingVertex(mapView: GMSMapView) {
        if GoogleMapsData.count >= 3 {
            GoogleMapsData.NUM_OF_POLYGON = GoogleMapsData.count
            GoogleMapsManager.isFinishDrawing = true
            
            if checkFinishDrawing() {
                GoogleMapsData.polygonPath.add(GoogleMapsData.polygonPoints[0])
            }
            drawPolygon(mapView: mapView)
            
        } else {
            print("至少繪製三個點")
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
//        setNumOfPolygon(num: 0)
        GoogleMapsData.count = -1
        GoogleMapsManager.isFinishDrawing = false
        
    }
    
    func resetDrawingPolygon() {
        GoogleMapsData.polygonPoints.removeAll()
        GoogleMapsData.polygonMarkers.removeAll()
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
            
            // 多邊形已畫完
            if checkFinishDrawing() {
                // 原點(第一個點)鍵值
                let originalPoint = "Point0"
                
                // 如果現在移動的是原點, 也一併把路徑的最後一個點重設為原點, 因為要把最後一個頂點連接原點的線畫出來
                if newMarker.title == originalPoint {
                    GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(GoogleMapsData.NUM_OF_POLYGON), with: GoogleMapsData.polygonPoints[0])
                }
            }
        }
        mapView.clear()
        reDrawing(mapView: mapView)
    }
}

// MARK:- Private functions

extension GoogleMapsManager {
    
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
        GoogleMapsData.trackLine.strokeColor = .blue
        GoogleMapsData.trackLine.strokeWidth = 5
    }
    
    // 繪製多邊形
    private func drawPolygon(mapView: GMSMapView) {
        let polygonLine = GMSPolyline(path: GoogleMapsData.polygonPath)
        polygonLine.map = mapView
        polygonLine.strokeColor = .orange // 線條顏色
        polygonLine.strokeWidth = 5 // 線條粗細
        
        GoogleMapsData.polygonLines.append(polygonLine)
        
        if checkFinishDrawing() {
            fillPolygonColor(mapView: mapView)
        }
    }
    
    // 將多邊形內部填滿顏色
    private func fillPolygonColor(mapView: GMSMapView) {
        GoogleMapsData.polygonObject = GMSPolygon()
        GoogleMapsData.polygonObject.path = GoogleMapsData.polygonPath
        GoogleMapsData.polygonObject.fillColor = UIColor(displayP3Red: 1, green: 1, blue: 0, alpha: 0.2) // 多邊形區塊顏色
        GoogleMapsData.polygonObject.map = mapView
    }
    
    private func reDrawing(mapView: GMSMapView) {

        // 每次在重畫地圖時, 都要先移除前一個畫面所用到的畫面資訊:
        // 1. 清除目前地圖上的圖示
        removePolygonMarks() // 多邊形的標誌
        removePolygon()      // 多邊形
        removePolygonColor() // 多邊形裡面的顏色
        
        // 2.清空在繪製地圖時用到的陣列
        GoogleMapsData.polygonLines.removeAll()
        
        
        // 重新繪製多邊形標誌
        for marker in GoogleMapsData.polygonMarkers {
            
            let m = GMSMarker.init()
            m.position    = marker.position
            m.isDraggable = marker.isDraggable
            m.title       = marker.title
            m.snippet     = marker.snippet
            m.icon        = marker.icon
            m.map         = mapView

        }
        drawPolygon(mapView: mapView)
    }
}
