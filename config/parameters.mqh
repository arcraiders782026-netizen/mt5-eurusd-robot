// ============================================================================
// MT5 EURUSD Hybrid Trading Robot - Ayarlanabilir Parametreler
// ============================================================================

#ifndef __PARAMETERS_MQH__
#define __PARAMETERS_MQH__

// ============================================================================
// ROBOT AYARLARI
// ============================================================================

// İşlem Çifti
#define SYMBOL              "EURUSD"

// Timeframe'ler (Multi-Timeframe)
#define TIMEFRAME_1         PERIOD_M15     // 15 dakika
#define TIMEFRAME_2         PERIOD_M30     // 30 dakika

// ============================================================================
// RISK YÖNETİMİ
// ============================================================================

// Lot Ayarları
input double LotSize = 0.1;                // Lot miktarı
input double MaxLots = 1.0;                // Maksimum lot
input double MinLots = 0.01;               // Minimum lot

// Stop Loss ve Take Profit (Pip cinsinden)
input int StopLossPips = 50;               // Zarar durdur: 50 pip
input int TakeProfitPips = 100;            // Kar al: 100 pip

// Risk Yönetimi
input double RiskPercent = 2.0;            // Hesabın riski: %2

// ============================================================================
// MOVING AVERAGE (MA) - TREND TESPIT
// ============================================================================

input int MA_Period = 20;                  // MA periyodu
input ENUM_MA_METHOD MA_Method = MODE_SMA; // Basit Moving Average
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE; // Kapanış fiyatı

// ============================================================================
// RSI - AŞIRI İŞLEM TESPIT
// ============================================================================

input int RSI_Period = 14;                 // RSI periyodu
input double RSI_Overbought = 70.0;        // Çok alındı seviyesi
input double RSI_Oversold = 30.0;          // Çok satıldı seviyesi

// ============================================================================
// BOLLINGER BANDS - FİYAT VOLATİLİTESİ
// ============================================================================

input int BB_Period = 20;                  // Bollinger Bands periyodu
input double BB_Deviation = 2.0;           // Standart sapma
input ENUM_APPLIED_PRICE BB_Price = PRICE_CLOSE; // Kapanış fiyatı

// ============================================================================
// MACD - MOMENTUM VE TREND
// ============================================================================

input int MACD_FastEMA = 12;               // Hızlı EMA
input int MACD_SlowEMA = 26;               // Yavaş EMA
input int MACD_SignalEMA = 9;              // Signal EMA

// ============================================================================
// STRATEJI AYARLARI
// ============================================================================

// Trend Following Stratejisi
input bool UseTrendFollowing = true;       // Trend takibini etkinleştir
input double TrendThreshold = 0.0015;      // Trend eşiği

// Range Trading Stratejisi
input bool UseRangeTrading = true;         // Aralık ticaretini etkinleştir
input int RangePeriod = 20;                // Aralık hesaplama periyodu

// Mean Reversion Stratejisi
input bool UseMeanReversion = true;        // Ortalamaya dönüşü etkinleştir
input double MRThreshold = 2.0;            // Ortalamaya dönüş eşiği

// ============================================================================
// TICARET AYARLARI
// ============================================================================

// Maksimum açık pozisyon sayısı
input int MaxOpenPositions = 3;

// İşlem saatleri (Optional)
input bool UseTradingHours = false;        // Belirli saatlerde ticaret
input int StartHour = 8;                   // Başlangıç saati
input int EndHour = 22;                    // Bitiş saati

// ============================================================================
// HATA AYIKLAMA VE LOG
// ============================================================================

// Debug modu
input bool DebugMode = true;               // Debug bilgilerini göster
input bool PrintLog = true;                // Log dosyasına kaydet

// ============================================================================
// PARAMETRELER ÖZET
// ============================================================================
/*
 * 
 * ROBOT ÖZET AYARLARI:
 * ─────────────────────────────────────────
 * İşlem Çifti: EURUSD
 * Timeframe: M15 + M30 (Multi-Timeframe)
 * Strateji: Hybrid (Trend + Range + MR)
 * 
 * RISK YÖNETİMİ:
 * ─────────────────────────────────────────
 * Lot Miktarı: 0.1
 * Stop Loss: 50 pip
 * Take Profit: 100 pip
 * Risk %: 2%
 * 
 * GÖSTERGELER:
 * ─────────────────────────────────────────
 * MA Period: 20
 * RSI Period: 14 (Overbought: 70, Oversold: 30)
 * Bollinger Bands: 20 periyod, 2.0 sapma
 * MACD: 12/26/9
 * 
 */

#endif // __PARAMETERS_MQH__