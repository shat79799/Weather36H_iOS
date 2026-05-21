//
//  WeatherViewModel.swift
//  Weather36H-iOS
//
//  Created by Stan Liu on 2026/5/21.
//

import Foundation
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    /// 負責儲存當前的頁面狀態，當狀態改變時會自動通知 SwiftUI 更新畫面
    @Published var viewState: WeatherViewState = .idle
    /// 綁定 UI 文字輸入框的字串
    @Published var searchText: String = ""
    
    private let weatherService: WeatherService
    
    init(weatherService: WeatherService = .shared) {
        self.weatherService = weatherService
    }
    
    // MARK: - 業務邏輯 (Business Logic)
    /// 執行天氣查詢
    func performSearch() async {
        // 檢查輸入是否為空值
        let cityName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cityName.isEmpty else {
            viewState = .failure(.emptyInput)
            return
        }
        
        // 進入查詢中狀態
        viewState = .loading
        
        do {
            // 向 Service 請求資料
            let response = try await weatherService.fetch36HourWeather()
            
            // 在本地端過濾出使用者指定的縣市資料
            guard let matchedLocation = response.records.location.first(where: {
                $0.locationName == cityName
            }) else {
                // 若找不到對應縣市，拋出城市未找到錯誤
                viewState = .failure(.cityNotFound)
                return
            }
            
            // 將多層巢狀的 API 資料解析並包裝成 UI 專用的結構
            let weatherResult = parseToWeatherResult(from: matchedLocation)
            
            // 更新狀態為查詢成功
            viewState = .success(weatherResult)
            
        } catch let error as WeatherError {
            // 捕捉已知的自訂錯誤
            viewState = .failure(error)
        } catch {
            // 捕捉非預期的系統錯誤
            viewState = .failure(.networkError(error))
        }
    }
    
    /// 將氣象署巢狀的 LocationData 轉換為 UI 專用的 WeatherResult
    private func parseToWeatherResult(from location: LocationData) -> WeatherResult {
        var forecasts: [ForecastInterval] = []
        
        // 提取需要的五個關鍵天氣要素
        let wxElement = location.weatherElement.first(where: { $0.elementName == "Wx" })
        let popElement = location.weatherElement.first(where: { $0.elementName == "PoP" })
        let minTElement = location.weatherElement.first(where: { $0.elementName == "MinT" })
        let ciElement = location.weatherElement.first(where: { $0.elementName == "CI" })
        let maxTElement = location.weatherElement.first(where: { $0.elementName == "MaxT" })
        
        // 今明 36 小時預報固定會有 3 個時間區段 (每 12 小時一段)
        for index in 0..<3 {
            // 確保該時段的資料在各個要素中都存在，避免陣列越界
            guard let wxTime = wxElement?.time[safe: index],
                  let popTime = popElement?.time[safe: index],
                  let minTTime = minTElement?.time[safe: index],
                  let ciTime = ciElement?.time[safe: index],
                  let maxTTime = maxTElement?.time[safe: index] else {
                continue
            }
            
            // 格式化時間字串，讓 UI 看起來更簡潔 (ex: "2026-05-12 18:00:00" -> "05-12 18:00")
            let displayStartTime = formatTimeStr(wxTime.startTime)
            let displayEndTime = formatTimeStr(wxTime.endTime)
            
            let interval = ForecastInterval(
                startTime: displayStartTime,
                endTime: displayEndTime,
                textWeather: wxTime.parameter.parameterName,
                pop: popTime.parameter.parameterName,
                minTemperature: minTTime.parameter.parameterName,
                comfort: ciTime.parameter.parameterName,
                maxTemperature: maxTTime.parameter.parameterName
            )
            
            forecasts.append(interval)
        }
        
        return WeatherResult(cityName: location.locationName, forecasts: forecasts)
    }
    
    /// 簡化時間字串長度
    private func formatTimeStr(_ rawDate: String) -> String {
        // 原始格式舉例: "2026-05-12 18:00:00" -> 擷取符合月-日 時:分 的範圍
        // 為了維持原生不依賴 DateFormatter 提升效能，採用字串切片
        let startIndex = rawDate.index(rawDate.startIndex, offsetBy: 5)
        let endIndex = rawDate.index(rawDate.startIndex, offsetBy: 16)
        return String(rawDate[startIndex..<endIndex])
    }
}

extension Array {
    /// 防止陣列索引越界的安全取值方法
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
