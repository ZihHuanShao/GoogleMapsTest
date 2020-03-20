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
    static var NUM_OF_POLYGON = Int()
    
    // 計算多邊形已經建立幾個頂點了
    static var count = 0
    
    // 多邊形所有頂點座標
    static var polygonPoints = [CLLocationCoordinate2D]()
    
    // 多邊形所有頂點標誌的資訊
    static var polygonMarkers = [GMSMarker]()
    
    // 軌跡所有頂點標誌的資訊
    static var trackMarkers = [GMSMarker]()
    
    // 用來繪製多邊形的物件
    static var polygonPath = GMSMutablePath()
    
    // 用來繪製軌跡的物件
    static var trackPath = GMSMutablePath()
    
    // 測試點
    static let testMarker = GMSMarker()
    
    static var trackLine = GMSPolyline.init()
}

// MARK: - Class

class GoogleMapsManager {
    
    // MAEK: - Properties
    
    static let shareInstance = GoogleMapsManager()
}

// MARK:- Public functions

extension GoogleMapsManager {
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
        marker.title = "Point" + "\(GoogleMapsData.count)" // 以 Point1/ Point2/ ... 為鍵值
        marker.snippet = (GoogleMapsData.count == GoogleMapsData.NUM_OF_POLYGON) ? "Original Point" : ""
        marker.icon = UIImage(named: "warning-icon")
        marker.map = mapView
        
        GoogleMapsData.polygonPoints.append(coordinate)
        GoogleMapsData.polygonMarkers.append(marker)
        
        GoogleMapsData.polygonPath.add(coordinate)
        
        GoogleMapsData.count -= 1
        
        if GoogleMapsData.count == 0 {
            GoogleMapsData.polygonPath.add(GoogleMapsData.polygonPoints[0])
            
        }
        drawPolygon(mapView: mapView)
    }
    
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
    
    // 檢查多邊形是否已繪製完成
    func checkFinishDrawing() -> Bool {
        return (GoogleMapsData.count == 0) ? true : false
    }
    
    func removeTestPointMark() {
        GoogleMapsData.testMarker.map = nil
    }
    
    func removeTrackMarks() {
        for marker in GoogleMapsData.trackMarkers {
            marker.map = nil
        }
    }

    func removeTrack() {
        GoogleMapsData.trackLine.map = nil
    }
    
    func resetMap(mapView: GMSMapView) {
        mapView.clear()
        resetDrawingPolygon()
        resetDrawingTrack()
        setNumOfPolygon(num: 0)
    }
    
    // 清除多邊形
    func resetDrawingPolygon() {
        GoogleMapsData.polygonPoints.removeAll()
        GoogleMapsData.polygonMarkers.removeAll()
        
        GoogleMapsData.polygonPath.removeAllCoordinates()
    }
    
    func resetDrawingTrack() {
        GoogleMapsData.trackPath.removeAllCoordinates()
    }
    
    
    // 當移動多邊形某頂點時, 更新其位置
    func modifyPoint(newMarker: GMSMarker, mapView: GMSMapView) {
        
        for (index, marker) in GoogleMapsData.polygonMarkers.enumerated() {
            if marker.title == newMarker.title {
                GoogleMapsData.polygonMarkers[index].position = newMarker.position
                GoogleMapsData.polygonPoints[index] = newMarker.position
                GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(index), with: newMarker.position)
                
                // 原點(第一個點)鍵值
                let originalPoint = "Point" + "\(GoogleMapsData.NUM_OF_POLYGON)"
                
                // 如果現在移動的是原點, 把路徑的最後一個點重設為原點
                if newMarker.title == originalPoint {
                    GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(GoogleMapsData.NUM_OF_POLYGON), with: GoogleMapsData.polygonPoints[0])
                }
            }
        }
        reDrawing(mapView: mapView)
    }
    
    // 當移動多邊形某頂點時, 更新其位置
    func modifyPoint(newMarker: GMSMarker, whenNotFinishDrawingYet mapView: GMSMapView) {
        
        for (index, marker) in GoogleMapsData.polygonMarkers.enumerated() {
            if marker.title == newMarker.title {
                GoogleMapsData.polygonMarkers[index].position = newMarker.position
                GoogleMapsData.polygonPoints[index] = newMarker.position
                GoogleMapsData.polygonPath.replaceCoordinate(at: UInt(index), with: newMarker.position)
                
                
            }
        }
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
    
    private func drawTrack(mapView: GMSMapView) {
        GoogleMapsData.trackLine = GMSPolyline(path: GoogleMapsData.trackPath)
        GoogleMapsData.trackLine.map = mapView
        GoogleMapsData.trackLine.strokeColor = .blue
        GoogleMapsData.trackLine.strokeWidth = 5
    }
    
    private func drawPolygon(mapView: GMSMapView) {
        let line = GMSPolyline(path: GoogleMapsData.polygonPath)
        line.map = mapView
        line.strokeColor = .orange
        line.strokeWidth = 5
    }
    
    private func reDrawing(mapView: GMSMapView) {
        mapView.clear()
        
        // 重新繪製
        for marker in GoogleMapsData.polygonMarkers {
            let m = GMSMarker()
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
