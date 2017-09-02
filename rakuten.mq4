//+------------------------------------------------------------------+
//|                                                      rakuten.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

input int Magic_Number = 1;
input double Monitor_Price = 110;
input color Line_Color = clrYellow;
input double Entry_Lot = 0.1;
extern double TP_pips = 0;
extern double SL_pips = 30;
extern double Trail_pips = 20;

string thisSymbol;

double minSL;
double prePrice;

const string mline = "mline";


void countPositions(int& buy, int& sell) {

  buy = 0;
  sell = 0;
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        if(OrderType() == OP_BUY) {
          buy ++;
        }
        else if(OrderType() == OP_SELL) {
          sell ++;
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
  prePrice = (Ask + Bid) / 2.0;
  
  TP_pips *= 10.0 * Point;
  SL_pips *= 10.0 * Point;
  Trail_pips *= 10.0 * Point;
   
  ObjectCreate(mline, OBJ_HLINE, 0, 0, Monitor_Price);
  ObjectSet(mline, OBJPROP_COLOR, Line_Color);
  ObjectSet(mline, OBJPROP_WIDTH, 1);
  ObjectSet(mline, OBJPROP_STYLE, STYLE_DASH);
  ObjectSet(mline, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
   ObjectDelete(0, mline);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  double price = (Ask + Bid) / 2.0;
  int buyNum = 0;
  int sellNum = 0;
  countPositions(buyNum, sellNum);

  if(prePrice < Monitor_Price && Monitor_Price < price) {
    if(buyNum == 0) {
      int ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 3, 
                             NormalizeDouble(Bid - SL_pips, Digits), 
                             0 < TP_pips ? NormalizeDouble(Bid + TP_pips, Digits) : 0, NULL, Magic_Number);
    }
  }
  else if(price < Monitor_Price && Monitor_Price < prePrice){
    if(sellNum == 0) {
      int ticket = OrderSend(Symbol(), OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 3, 
                             NormalizeDouble(Ask + SL_pips, Digits), 
                             0 < TP_pips ? NormalizeDouble(Ask - TP_pips, Digits) : 0, NULL, Magic_Number);
    }
  }
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        if(OrderType() == OP_BUY) {
          if(OrderOpenPrice() + Trail_pips < Bid && OrderStopLoss() + Trail_pips < Bid) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Trail_pips, OrderTakeProfit(), 0);
          }
        }
          
        else if(OrderType() == OP_SELL) {
          if(Ask < OrderOpenPrice() - Trail_pips && Ask < OrderStopLoss() - Trail_pips) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Trail_pips, OrderTakeProfit(), 0);
          }
        }
      }
    }
  }
  
  prePrice = price;  
}
//+------------------------------------------------------------------+
