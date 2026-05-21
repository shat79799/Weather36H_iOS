//
//  WeatherModel.swift
//  Weather36H-iOS
//
//  Created by Stan Liu on 2026/5/21.
//

import Foundation

// MARK: - 頁面狀態定義
enum WeatherViewState {
    case idle                     // 初始狀態
    case loading                  // 查詢中
    case success(WeatherResult)   // 查詢成功（帶入過濾好的乾淨資料）
    case failure(WeatherError)    // 查詢失敗（帶入錯誤原因）
}

// MARK: - 自訂錯誤型別
enum WeatherError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError
    case cityNotFound
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無效的 API 網址，請聯絡開發者。"
        case .networkError(let error):
            return "網路連線失敗：\(error.localizedDescription)"
        case .invalidResponse:
            return "伺服器回應異常，請稍後再試。"
        case .decodingError:
            return "資料解析失敗，請確認 API 格式。"
        case .cityNotFound:
            return "找不到該城市的氣象資料，請輸入正確的台灣縣市名稱（例如：臺北市、桃園市）。"
        case .emptyInput:
            return "請輸入要查詢的城市名稱。"
        }
    }
}

// MARK: - UI 專用數據模型
struct WeatherResult {
    let cityName: String
    let forecasts: [ForecastInterval]
}

/// 每一段時間（共三段，每 12 小時，總計 36 小時）的天氣預報資料
struct ForecastInterval: Identifiable {
    let id = UUID()
    let startTime: String       // 開始時間 (例如: "06-12 18:00")
    let endTime: String         // 結束時間 (例如: "06-13 06:00")
    let textWeather: String     // 天氣現象 (Wx)
    let pop: String             // 降雨機率 (PoP)
    let minTemperature: String  // 最低溫度 (MinT)
    let comfort: String         // 舒適度 (CI)
    let maxTemperature: String  // 最高溫度 (MaxT)
}

// MARK: - API 原始資料結構 (對應氣象署 JSON 格式)
struct WeatherResponse: Decodable {
    let success: String
    let records: WeatherRecords
}

struct WeatherRecords: Decodable {
    let location: [LocationData]
}

struct LocationData: Decodable {
    let locationName: String
    let weatherElement: [WeatherElement]
}

struct WeatherElement: Decodable {
    let elementName: String
    let time: [TimeIntervalData]
}

struct TimeIntervalData: Decodable {
    let startTime: String
    let endTime: String
    let parameter: ParameterData
}

struct ParameterData: Decodable {
    let parameterName: String
    let parameterValue: String?
    let parameterUnit: String?
}
