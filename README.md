# Weather36H_iOS

`Weather36H_iOS`是一個透過中央氣象局的api, 查詢未來36小時的天氣預報  
使用`MVVM`作為架構, 透過`Combine`和`SwiftUI`進行開發

## Usage

1. 在上方文字輸入欄輸入要查詢的城市
2. 按下右上方的「搜尋」
3. 下方會顯示搜尋結果
4. 按下左上方的「清除」可清除搜尋結果和文字輸入欄

## Environment

- iOS 16.0+
- Xcode 26.4

## Structure

`Model` : 數據與資料層  
`Service` : 連線相關功能  
`View` : 頁面的UI設計  
`ViewModel` : 頁面的邏輯處理  