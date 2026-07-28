// ============================================================================
// Bollinger Bands - Fiyat Volatilitesi Göstergesi
// ============================================================================

#ifndef __BOLLINGER_BANDS_MQH__
#define __BOLLINGER_BANDS_MQH__

// ============================================================================
// BOLLINGER BANDS SINIFI
// ============================================================================

class CBollingerBands
{
private:
   int handle;           // Bollinger Bands handle
   int period;           // BB periyodu
   double deviation;     // Standart sapma
   string symbol;        // İşlem çifti
   ENUM_TIMEFRAMES tf;   // Timeframe
   
public:
   // Constructor
   CBollingerBands(string sym, ENUM_TIMEFRAMES timeframe, 
                   int per, double dev)
   {
      symbol = sym;
      tf = timeframe;
      period = per;
      deviation = dev;
      handle = INVALID_HANDLE;
      CreateIndicator();
   }
   
   // Destructor
   ~CBollingerBands()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
   
   // ========================================================================
   // İNDİKATÖR OLUŞTURMA
   // ========================================================================
   
   bool CreateIndicator()
   {
      handle = iBands(symbol, tf, period, 0, deviation, PRICE_CLOSE);
      
      if(handle == INVALID_HANDLE)
      {
         Print("HATA: Bollinger Bands göstergesi oluşturulamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // GETTER FONKSİYONLAR
   // ========================================================================
   
   // Üst Band (Upper Band)
   double GetUpperBand(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 1, shift, 1, buffer) <= 0)
      {
         Print("HATA: Üst Band değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Orta Band (Middle Band - Simple Moving Average)
   double GetMiddleBand(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
      {
         Print("HATA: Orta Band değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Alt Band (Lower Band)
   double GetLowerBand(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 2, shift, 1, buffer) <= 0)
      {
         Print("HATA: Alt Band değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Tüm band değerlerini bir kez al (daha verimli)
   bool GetAllBands(int shift, double &upper, double &middle, double &lower)
   {
      double buf_upper[], buf_middle[], buf_lower[];
      
      if(CopyBuffer(handle, 1, shift, 1, buf_upper) <= 0)
         return false;
      if(CopyBuffer(handle, 0, shift, 1, buf_middle) <= 0)
         return false;
      if(CopyBuffer(handle, 2, shift, 1, buf_lower) <= 0)
         return false;
      
      upper = buf_upper[0];
      middle = buf_middle[0];
      lower = buf_lower[0];
      
      return true;
   }
   
   // ========================================================================
   // BAND POZİSYONU TESPITI
   // ========================================================================
   
   // Fiyat üst banda yakın mı?
   bool IsNearUpperBand(double price, double percent = 0.95)
   {
      double upper = GetUpperBand(0);
      double middle = GetMiddleBand(0);
      double bandwidth = upper - middle;
      
      return price > (upper - bandwidth * (1 - percent));
   }
   
   // Fiyat alt banda yakın mı?
   bool IsNearLowerBand(double price, double percent = 0.95)
   {
      double lower = GetLowerBand(0);
      double middle = GetMiddleBand(0);
      double bandwidth = middle - lower;
      
      return price < (lower + bandwidth * (1 - percent));
   }
   
   // Fiyat üst banda dokundu mu?
   bool TouchesUpperBand(double price)
   {
      return price >= GetUpperBand(0);
   }
   
   // Fiyat alt banda dokundu mu?
   bool TouchesLowerBand(double price)
   {
      return price <= GetLowerBand(0);
   }
   
   // Fiyat bandın dışında mı?
   bool IsOutsideBands(double price)
   {
      double upper = GetUpperBand(0);
      double lower = GetLowerBand(0);
      
      return (price > upper || price < lower);
   }
   
   // Fiyaz bandın içinde mi?
   bool IsInsideBands(double price)
   {
      double upper = GetUpperBand(0);
      double lower = GetLowerBand(0);
      
      return (price >= lower && price <= upper);
   }
   
   // ========================================================================
   // VOLATILITE TESPITI
   // ========================================================================
   
   // Bandwidth (Band genişliği)
   double GetBandwidth()
   {
      double upper = GetUpperBand(0);
      double lower = GetLowerBand(0);
      
      return upper - lower;
   }
   
   // Bandwidth yüzdesi (%B)
   // 0: Alt banda, 1: Üst banda, 0.5: Ortada
   double GetBandwidthPercent(double price)
   {
      double upper = GetUpperBand(0);
      double lower = GetLowerBand(0);
      double middle = GetMiddleBand(0);
      
      if(upper == lower)
         return 0.5;  // Bölme hatası önlemek için
      
      return (price - lower) / (upper - lower);
   }
   
   // Volatilite yüksek mi?
   bool IsHighVolatility()
   {
      // Geçmiş bandwidth ile karşılaştır
      double current_bw = GetBandwidth();
      double previous_bw = GetBandwidth();  // Önceki şimdiki ile aynı (shift eklenebilir)
      
      return current_bw > previous_bw * 1.2;  // %20 daha yüksek
   }
   
   // Volatilite düşük mü? (Sıkıştırma)
   bool IsLowVolatility()
   {
      double current_bw = GetBandwidth();
      double average_bw = GetBandwidth();  // Ortalama hesaplanabilir
      
      return current_bw < average_bw * 0.8;  // %20 daha düşük
   }
   
   // ============================================================================
   // SQUEEZE TESPITI (Bollinger Bands Squeeze)
   // ============================================================================
   
   // Squeeze durumu (Bandlar çok dar)
   bool IsSqueeze(double squeeze_threshold = 0.0010)
   {
      double bandwidth = GetBandwidth();
      double middle = GetMiddleBand(0);
      
      // Bandwidth'in middle'a oranı
      double bw_ratio = bandwidth / middle;
      
      return bw_ratio < squeeze_threshold;
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Handle geçerli mi?
   bool IsValid()
   {
      return handle != INVALID_HANDLE;
   }
   
   // Periyodu al
   int GetPeriod()
   {
      return period;
   }
   
   // Sapma değerini al
   double GetDeviation()
   {
      return deviation;
   }
};

#endif // __BOLLINGER_BANDS_MQH__