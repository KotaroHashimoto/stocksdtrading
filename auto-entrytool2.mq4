//+------------------------------------------------------------------+
//|                                              auto-entrytool2.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict


input int Magic_Number = 1;
input int Entry_Time_H = 14;
input int Entry_Time_M = 0;
input int Exit_Time_H = 20;
input int Exit_Time_M = 0;
input int Calc_Period_H = 7;

input double Lot_Size = 0.1;
extern double SL_Short_Pips = 20;
extern double TP_Short_Pips = 50;
extern double SL_Long_Pips = 20;
extern double TP_Long_Pips = 60;


double minSL;
string thisSymbol;


void closeAll() {

  datetime dt = TimeCurrent();

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
      
        int type = OrderType();
        if(type == OP_BUYSTOP || type == OP_SELLSTOP) {
          bool d = OrderDelete(OrderTicket());
          i = -1;
        }
        else if(type == OP_BUY) {
          bool c = OrderClose(OrderTicket(), OrderLots(), Bid, 3);
          i = -1;
        }
        else if(type == OP_SELL) {
          bool c = OrderClose(OrderTicket(), OrderLots(), Ask, 3);
          i = -1;
        }
      }
    }
  }
}


bool pendingExists() {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        int type = OrderType();
        if(type == OP_BUYSTOP || type == OP_SELLSTOP) {
          return True;
        }
      }
    }
  }
  
  return False;
}



void closeOne() {

  int count = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        int type = OrderType();
        if(type == OP_BUYSTOP || type == OP_SELLSTOP) {
          count ++;
        }
      }
    }
  }
  
  if(count != 1) {
    return;
  }
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        int type = OrderType();
        if(type == OP_BUYSTOP || type == OP_SELLSTOP) {
          bool d = OrderDelete(OrderTicket());
          i = -1;
        }
      }
    }
  }
}



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  thisSymbol = Symbol();
  minSL = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  
  SL_Long_Pips *= 10.0 * Point;
  TP_Long_Pips *= 10.0 * Point;
  SL_Short_Pips *= 10.0 * Point;
  TP_Short_Pips *= 10.0 * Point;
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  datetime dt = TimeLocal();
  int h = TimeHour(dt);
  int m = TimeMinute(dt);
  
  if(h == Exit_Time_H && m == Exit_Time_M) {
    closeAll();
  }
  
  else if(h == Entry_Time_H && m == Entry_Time_M) {
    
    if(!pendingExists()) {
        
      double highPrice = High[iHighest(thisSymbol, PERIOD_CURRENT, MODE_HIGH, Calc_Period_H * (60 / Period()), 1)];
      double lowPrice = Low[iLowest(thisSymbol, PERIOD_CURRENT, MODE_LOW, Calc_Period_H * (60 / Period()), 1)];
      
      if(highPrice - Ask < minSL) {
        int bTicket = OrderSend(thisSymbol, OP_BUY, Lot_Size, NormalizeDouble(Ask, Digits), 3, NormalizeDouble(Ask - SL_Long_Pips, Digits), NormalizeDouble(Ask + TP_Long_Pips, Digits), NULL, Magic_Number);
      }
      else {  
        int bTicket = OrderSend(thisSymbol, OP_BUYSTOP, Lot_Size, NormalizeDouble(highPrice, Digits), 3, NormalizeDouble(highPrice - SL_Long_Pips, Digits), NormalizeDouble(highPrice + TP_Long_Pips, Digits), NULL, Magic_Number);
      }
      
      if(Bid - lowPrice < minSL) {
        int sTicket = OrderSend(thisSymbol, OP_SELL, Lot_Size, NormalizeDouble(Bid, Digits), 3, NormalizeDouble(Bid + SL_Short_Pips, Digits), NormalizeDouble(Bid - TP_Short_Pips, Digits), NULL, Magic_Number);    
      }
      else {
        int sTicket = OrderSend(thisSymbol, OP_SELLSTOP, Lot_Size, NormalizeDouble(lowPrice, Digits), 3, NormalizeDouble(lowPrice + SL_Short_Pips, Digits), NormalizeDouble(lowPrice - TP_Short_Pips, Digits), NULL, Magic_Number);    
      }
    }
  }
  else { 
    closeOne();
  }
}
//+------------------------------------------------------------------+
