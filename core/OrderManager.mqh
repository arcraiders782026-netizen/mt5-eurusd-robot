// ============================================================================
// Order Manager - Siparişi Yönetim Sistemi
// ============================================================================

#ifndef __ORDER_MANAGER_MQH__
#define __ORDER_MANAGER_MQH__

#include <Trade\Trade.mqh>
#include "Logger.mqh"

// ============================================================================
// ORDER MANAGER SINIFI
// ============================================================================

class COrderManager
{
private:
   CTrade trade;              // Trade nesnesi
   string symbol;             // İşlem çifti
   CLogger *logger;           // Log sistemi
   
public:
   // Constructor
   COrderManager(string sym, CLogger *log_ptr)
   {
      symbol = sym;
      logger = log_ptr;
      
      // Trade ayarları
      trade.SetExpertMagicNumber(123456);  // Magic number
      trade.SetDeviationInPoints(10);      // Slippage toleransı
   }
   
   // Destructor
   ~COrderManager()
   {
      // Logger harici tarafından yönetilir
   }
   
   // ========================================================================
   // ORDER AÇMA FONKSİYONLARI
   // ========================================================================
   
   // BUY Order aç
   bool OpenBuyOrder(double lots, int stop_loss_pips, int take_profit_pips)
   {
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      // Stop Loss ve Take Profit hesapla
      double sl = ask - (stop_loss_pips * SymbolInfoDouble(symbol, SYMBOL_POINT));
      double tp = ask + (take_profit_pips * SymbolInfoDouble(symbol, SYMBOL_POINT));
      
      // Order aç
      if(!trade.Buy(lots, symbol, ask, sl, tp))
      {
         if(logger != NULL)
            logger->Error("BUY order açılamadı: " + IntegerToString(trade.ResultRetcode()));
         return false;
      }
      
      if(logger != NULL)
         logger->Info("BUY Order Açıldı - Lot: " + DoubleToString(lots) + 
                     " SL: " + DoubleToString(sl) + " TP: " + DoubleToString(tp));
      
      return true;
   }
   
   // SELL Order aç
   bool OpenSellOrder(double lots, int stop_loss_pips, int take_profit_pips)
   {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      
      // Stop Loss ve Take Profit hesapla
      double sl = bid + (stop_loss_pips * SymbolInfoDouble(symbol, SYMBOL_POINT));
      double tp = bid - (take_profit_pips * SymbolInfoDouble(symbol, SYMBOL_POINT));
      
      // Order aç
      if(!trade.Sell(lots, symbol, bid, sl, tp))
      {
         if(logger != NULL)
            logger->Error("SELL order açılamadı: " + IntegerToString(trade.ResultRetcode()));
         return false;
      }
      
      if(logger != NULL)
         logger->Info("SELL Order Açıldı - Lot: " + DoubleToString(lots) + 
                     " SL: " + DoubleToString(sl) + " TP: " + DoubleToString(tp));
      
      return true;
   }
   
   // ========================================================================
   // ORDER KAPATMA FONKSİYONLARI
   // ========================================================================
   
   // Order'ı ticket numarasıyla kapat
   bool CloseOrderByTicket(ulong ticket)
   {
      if(!trade.PositionClose(ticket))
      {
         if(logger != NULL)
            logger->Error("Order kapatılamadı - Ticket: " + IntegerToString(ticket));
         return false;
      }
      
      if(logger != NULL)
         logger->Info("Order Kapatıldı - Ticket: " + IntegerToString(ticket));
      
      return true;
   }
   
   // Tüm açık orderları kapat
   int CloseAllOrders()
   {
      int closed_count = 0;
      int total_positions = PositionsTotal();
      
      for(int i = total_positions - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         
         if(ticket > 0)
         {
            if(CloseOrderByTicket(ticket))
               closed_count++;
         }
      }
      
      if(logger != NULL)
         logger->Info("Toplam " + IntegerToString(closed_count) + " order kapatıldı");
      
      return closed_count;
   }
   
   // ========================================================================
   // POZİSYON KONTROL
   // ========================================================================
   
   // Açık pozisyon sayısını al
   int GetTotalOpenPositions()
   {
      return PositionsTotal();
   }
   
   // Belirli sembol için açık pozisyon sayısı
   int GetOpenPositionsBySymbol()
   {
      int count = 0;
      
      for(int i = 0; i < PositionsTotal(); i++)
      {
         if(PositionGetSymbol(i) == symbol)
            count++;
      }
      
      return count;
   }
   
   // Son açılan order'ı al
   ulong GetLastOrderTicket()
   {
      ulong last_ticket = 0;
      
      for(int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         
         if(ticket > last_ticket)
            last_ticket = ticket;
      }
      
      return last_ticket;
   }
   
   // ========================================================================
   // STOP LOSS VE TAKE PROFIT GÜNCELLEME
   // ========================================================================
   
   // Order'ın Stop Loss'unu güncelle
   bool UpdateStopLoss(ulong ticket, double new_sl)
   {
      if(!trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP)))
      {
         if(logger != NULL)
            logger->Error("Stop Loss güncellenemedi - Ticket: " + IntegerToString(ticket));
         return false;
      }
      
      if(logger != NULL)
         logger->Info("Stop Loss Güncellendi - Ticket: " + IntegerToString(ticket) + 
                     " Yeni SL: " + DoubleToString(new_sl));
      
      return true;
   }
   
   // Order'ın Take Profit'ini güncelle
   bool UpdateTakeProfit(ulong ticket, double new_tp)
   {
      if(!trade.PositionModify(ticket, PositionGetDouble(POSITION_SL), new_tp))
      {
         if(logger != NULL)
            logger->Error("Take Profit güncellenemedi - Ticket: " + IntegerToString(ticket));
         return false;
      }
      
      if(logger != NULL)
         logger->Info("Take Profit Güncellendi - Ticket: " + IntegerToString(ticket) + 
                     " Yeni TP: " + DoubleToString(new_tp));
      
      return true;
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Magic number'ı ayarla
   void SetMagicNumber(long magic)
   {
      trade.SetExpertMagicNumber(magic);
   }
};

#endif // __ORDER_MANAGER_MQH__
