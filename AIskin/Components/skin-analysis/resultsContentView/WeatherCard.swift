//
//  WeatherCard.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct WeatherCard: View {
    @State private var weatherData: WeatherData = WeatherData()
    @State private var isLoading = false
    @State private var lastUpdateTime = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Weather Header
            HStack {
                Image(systemName: getWeatherIcon())
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 1.0, green: 0.843, blue: 0.0))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(weatherData.city ?? "定位中...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(weatherData.weather ?? "获取中...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            // Weather Details
            HStack(spacing: 0) {
                WeatherDetailItem(label: "温度", value: weatherData.temperature ?? "--")
                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 40)
                WeatherDetailItem(label: "湿度", value: weatherData.humidity ?? "--")
                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 40)
                WeatherDetailItem(label: "风力", value: weatherData.wind ?? "--")
            }
            
            // Footer
            HStack {
                Text("最后更新: \(formatUpdateTime())")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Button(action: refreshWeather) {
                    HStack(spacing: 6) {
                        Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                            .font(.system(size: 12))
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                        
                        Text(isLoading ? "更新中..." : "刷新")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                }
                .disabled(isLoading)
            }
            .padding(.top, 16)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.2))
                    .offset(y: -8),
                alignment: .top
            )
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.400, green: 0.494, blue: 0.918),
                    Color(red: 0.463, green: 0.298, blue: 0.635)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 32, x: 0, y: 8)
        .padding(.horizontal, 8)
        .onAppear {
            refreshWeather()
        }
    }
    
    private func getWeatherIcon() -> String {
        let weather = weatherData.weather ?? ""
        if weather.contains("晴") { return "sun.max.fill" }
        if weather.contains("阴") { return "cloud.fill" }
        if weather.contains("雨") { return "cloud.rain.fill" }
        if weather.contains("雪") { return "snowflake" }
        if weather.contains("雾") { return "cloud.fog.fill" }
        return "cloud.sun.fill"
    }
    
    private func formatUpdateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: lastUpdateTime)
    }
    
    private func refreshWeather() {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Mock weather data
            self.weatherData = WeatherData(
                city: "北京",
                weather: "晴天",
                temperature: "25°C",
                humidity: "60%",
                wind: "3级"
            )
            self.lastUpdateTime = Date()
            self.isLoading = false
        }
    }
}

struct WeatherDetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeatherData {
    var city: String?
    var weather: String?
    var temperature: String?
    var humidity: String?
    var wind: String?
}


