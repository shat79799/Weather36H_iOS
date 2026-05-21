//
//  WeatherService.swift
//  Weather36H-iOS
//
//  Created by Stan Liu on 2026/5/21.
//

import Foundation

class WeatherService {
    static let shared = WeatherService()
    private init() {}
    
    /// 中央氣象署「今明36小時天氣預報」API 的授權碼
    private let apiKey = "CWA-F789313B-CFBB-4B07-A88F-C8EF35EE1711"
    private let domain = "https://opendata.cwa.gov.tw"
    private let path = "/api/v1/rest/datastore"
    
    /// 從中央氣象署 API 獲取所有縣市的 36 小時天氣預報資料
    /// - Returns: 解析後的 WeatherResponse 原始資料
    /// - Throws: WeatherError 類型的錯誤
    func fetch36HourWeather() async throws -> WeatherResponse {
        // 構建 URL (使用今明36小時天氣預報預設預報編號：F-C0032-001)
        let urlString = domain + path + "/F-C0032-001" + "?Authorization=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        // 使用 URLSession 發送非同步請求
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            // 捕捉網路連線失敗（ex: 無網路, 伺服器斷線等...）
            throw WeatherError.networkError(error)
        }
        
        // 驗證 HTTP 回應狀態碼
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }
        
        // 解析 JSON 資料
        do {
            let decoder = JSONDecoder()
            // 氣象署 API 的時間格式通常為 "yyyy-MM-dd HH:mm:ss"
            let weatherResponse = try decoder.decode(WeatherResponse.self, from: data)
            return weatherResponse
        } catch {
            // 捕捉 JSON 欄位對應不上或型別錯誤的狀況
            throw WeatherError.decodingError
        }
    }
}
