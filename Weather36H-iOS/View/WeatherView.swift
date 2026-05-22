//
//  WeatherView.swift
//  Weather36H-iOS
//
//  Created by Stan Liu on 2026/5/21.
//

import SwiftUI

struct WeatherView: View {
    // 監聽 ViewModel 的狀態變化
    @StateObject private var viewModel = WeatherViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 下方主要內容區域：根據 viewState 切換 UI
                Group {
                    switch viewModel.viewState {
                    case .idle:
                        initialView
                    case .loading:
                        loadingView
                    case .success(let result):
                        // 依據需求，將結果改為以表單 (Form) 樣式呈現
                        forecastFormView(with: result)
                    case .failure(let error):
                        errorView(for: error)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            // 設定導覽列標題模式，inline 才能正確騰出中央空間給輸入框
            .navigationBarTitleDisplayMode(.inline)
            // 使用 toolbar 進行左、中、右的精準配置
            .toolbar {
                // 左上角按鈕：清除搜尋結果與文字
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.searchText = ""
                        viewModel.viewState = .idle
                    }) {
                        Text("清除")
                            .foregroundColor(.red)
                    }
                }
                
                // 正中央：文字輸入框
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.footnote)
                        TextField("輸入縣市 (如: 臺北市)", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                            .onSubmit {
                                Task { await viewModel.performSearch() }
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    // 限制輸入框最大寬度，避免擠壓到兩側按鈕
                    .frame(maxWidth: 220)
                }
                
                // 右上角按鈕：開始進行搜尋
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await viewModel.performSearch() }
                    }) {
                        Text("搜尋")
                            .bold()
                    }
                }
            }
        }
    }
}

private extension WeatherView {
    
    // .idle - 初始狀態畫面
    var initialView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            Text("想了解哪裡的天氣？")
                .font(.headline)
            Text("請在上方輸入台灣縣市名稱並點擊搜尋")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // .loading - 查詢中狀態畫面
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在獲取最新氣象資料...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // .success - 查詢成功畫面 (使用 iOS 原生 Form 呈現)
    func forecastFormView(with result: WeatherResult) -> some View {
        Form {
            // 縣市名稱標頭區段
            Section {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(result.cityName)
                        .font(.headline)
                        .bold()
                }
            }
            
            // 36 小時預報區段 (循環渲染三個時段)
            ForEach(result.forecasts) { forecast in
                Section(header: Text("預報時段：\(forecast.startTime) ~ \(forecast.endTime)")) {
                    // 天氣現象與降雨率
                    HStack {
                        Label("天氣現象", systemImage: "cloud.sun")
                        Spacer()
                        Text(forecast.textWeather)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("降雨機率", systemImage: "drop.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(forecast.pop)%")
                            .bold()
                            .foregroundColor(.blue)
                    }
                    
                    // 溫度區間
                    HStack {
                        Label("氣溫範圍", systemImage: "thermometer.medium")
                        Spacer()
                        Text("\(forecast.minTemperature)°C - \(forecast.maxTemperature)°C")
                            .foregroundColor(.primary)
                    }
                    
                    // 舒適度
                    HStack {
                        Label("舒適度", systemImage: "face.smiling")
                        Spacer()
                        Text(forecast.comfort)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // .failure - 查詢失敗畫面
    func errorView(for error: WeatherError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color.red)
            Text("發生錯誤")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                Task { await viewModel.performSearch() }
            }) {
                Text("重新嘗試")
                    .bold()
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView()
    }
}
