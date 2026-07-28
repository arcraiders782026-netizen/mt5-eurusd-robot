// ============================================================================
// Risk Manager - Risk Yönetim Sistemi
// ============================================================================

#ifndef __RISK_MANAGER_MQH__
#define __RISK_MANAGER_MQH__

#include "Logger.mqh"

// ============================================================================
// RISK MANAGER SINIFI
// ============================================================================

class CRiskManager
{
private:
   string symbol;             // İşlem çifti
   double account_balance;    // Hesap bakiyesi
   double risk_percent;       // Risk yüzdesi
   double min_lot;            // Minimum lot
   double max_lot;            // Maksimum lot
   double lot_size;           // Hesaplanan lot miktarı
   CLogger *logger;           // Log sistemi
   
public:
   // Constructor
   CRiskManager(string sym, double risk_pct, double min_l, double max_l, CLogger *log_ptr)
   {
      symbol = sym;
      risk_percent = risk_pct;
      min_lot = min_l;
      max_lot = max_l;
      logger = log_ptr;
      account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      lot_size = 0.1;
   }
   
   // Destructor
   ~CRiskManager()
   {
      // Logger harici tarafından yönetilir
   }
   
   // ========================================================================
   // LOT HESAPLAMA
   // ========================================================================
   
   // Lot miktarını hesapla (Risk yüzdesi tabanlı)
   double CalculateLotSize(int stop_loss_pips)
   {
      if(stop_loss_pips <= 0)
      {
         if(logger != NULL)
            logger->Warning("Geçersiz Stop Loss pips");
         return min_lot;
      }
      
      // Hesap bakiyesini güncelle
      account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      
      // Risk tutarı (Hesabın risk_percent'i)
      double risk_amount = account_balance * (risk_percent / 100.0);
      
      // Pip değeri (EURUSD için)
      double pip_value = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10;  // Standart pip
      
      // Lot = Risk Amount / (SL Pips * Pip Value)
      double calculated_lot = risk_amount / (stop_loss_pips * pip_value);
      
      // Min ve Max lot arasında sınırla
      if(calculated_lot < min_lot)
         calculated_lot = min_lot;
      else if(calculated_lot > max_lot)
         calculated_lot = max_lot;
      
      lot_size = calculated_lot;
      
      if(logger != NULL)
         logger->Debug("Lot Hesaplandı: " + DoubleToString(lot_size) + 
                      " (Risk: " + DoubleToString(risk_amount) + " SL: " + IntegerToString(stop_loss_pips) + "pips)");
      
      return lot_size;
   }
   
   // Sabit lot miktarı ayarla
   void SetFixedLotSize(double lots)
   {
      if(lots < min_lot || lots > max_lot)
      {
         if(logger != NULL)
            logger->Warning("Lot miktarı sınırların dışında: " + DoubleToString(lots));
         return;
      }
      
      lot_size = lots;
      
      if(logger != NULL)
         logger->Debug("Sabit Lot Miktarı Ayarlandı: " + DoubleToString(lot_size));
   }
   
   // ========================================================================
   // MAKSIMUM POZİSYON KONTROL
   // ========================================================================
   
   // Maksimum açık pozisyon sayısı kontrol et
   bool CanOpenPosition(int max_positions)
   {
      int current_positions = PositionsTotal();
      
      if(current_positions >= max_positions)
      {
         if(logger != NULL)
            logger->Warning("Maksimum pozisyon limitine ulaşıldı: " + IntegerToString(current_positions));
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // KAR/ZARAR HESAPLAMA
   // ========================================================================
   
   // Açık pozisyon kar/zarar tutarını hesapla
   double GetPositionProfit(ulong ticket)
   {
      if(!PositionSelectByTicket(ticket))
         return 0.0;
      
      return PositionGetDouble(POSITION_PROFIT);
   }
   
   // Tüm açık pozisyonların toplam kar/zarar'ı
   double GetTotalProfit()
   {
      double total_profit = 0.0;
      
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionGetSymbol(i) == symbol)
         {
            total_profit += PositionGetDouble(POSITION_PROFIT);
         }
      }
      
      return total_profit;
   }
   
   // ========================================================================
   // BREAKEVEN KONTROL (SL'yi entry fiyatına çek)
   // ========================================================================
   
   // Kar elde edildikten sonra SL'yi giriş fiyatına ayarla
   bool MoveToBreakeven(ulong ticket, int profit_pips)
   {
      if(!PositionSelectByTicket(ticket))
         return false;
      
      double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
      double current_sl = PositionGetDouble(POSITION_SL);
      
      ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double profit_in_price = profit_pips * point * 10;  // 10 pips = 1 pip value
      
      // BUY pozisyonu
      if(pos_type == POSITION_TYPE_BUY)
      {
         if(current_price >= entry_price + profit_in_price)
         {
            // SL'yi entry price'a koy
            if(logger != NULL)
               logger->Info("Breakeven tarafına hareket etmek - Ticket: " + IntegerToString(ticket));
            return true;  // Burada OrderManager ile SL güncellenebilir
         }
      }
      
      // SELL pozisyonu
      else if(pos_type == POSITION_TYPE_SELL)
      {
         if(current_price <= entry_price - profit_in_price)
         {
            // SL'yi entry price'a koy
            if(logger != NULL)
               logger->Info("Breakeven tarafına hareket etmek - Ticket: " + IntegerToString(ticket));
            return true;  // Burada OrderManager ile SL güncellenebilir
         }
      }
      
      return false;
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Hesap bakiyesini güncelle
   void UpdateBalance()
   {
      account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   }
   
   // Mevcut lot miktarını al
   double GetLotSize()
   {
      return lot_size;
   }
   
   // Risk yüzdesini değiştir
   void SetRiskPercent(double risk_pct)
   {
      if(risk_pct > 0 && risk_pct <= 10)  // %0 - %10 arasında
         risk_percent = risk_pct;
      else if(logger != NULL)
         logger->Warning("Geçersiz risk yüzdesi: " + DoubleToString(risk_pct));
   }
};

#endif // __RISK_MANAGER_MQH__
