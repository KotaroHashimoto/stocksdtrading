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
input double Entry_Lot = 0.1;
extern double SL_pips = 30;
extern double Trail_pips = 20;

input double Monitor_Price_Sell_1 = 107.0;
input double Monitor_Price_Sell_2 = 108.0;
input double Monitor_Price_Sell_3 = 109.0;
input double Monitor_Price_Sell_4 = 110.0;
input double Monitor_Price_Sell_5 = 111.0;

input double Monitor_Price_Buy_1 = 107.0;
input double Monitor_Price_Buy_2 = 108.0;
input double Monitor_Price_Buy_3 = 109.0;
input double Monitor_Price_Buy_4 = 110.0;
input double Monitor_Price_Buy_5 = 111.0;

string thisSymbol;

double minSL;

double sellPrices[] = {0, 0, 0, 0, 0};
double buyPrices[] = {0, 0, 0, 0, 0};

bool sellAllows[] = {False, False, False, False, False};
bool buyAllows[] = {False, False, False, False, False};


bool hasOrderSent(double price, int type) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        if(OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) {
          if(type == OP_BUY && price == OrderOpenPrice()) {
            return True;
          }
        }
        else if(OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) {
          if(type == OP_SELL && price == OrderOpenPrice()) {
            return True;
          }
        }
      }
    }
  }

  return False;
}


void updateMasks() {

  for(int i = 0; i < 5; i++) {
    if(Ask + minSL < buyPrices[i]) {
      buyAllows[i] = (buyAllows[i] | True);
    }
  }

  for(int i = 0; i < 5; i++) {
    if(sellPrices[i] < Bid - minSL) {
      sellAllows[i] = (sellAllows[i] | True);
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
  
  SL_pips *= 10.0 * Point;
  Trail_pips *= 10.0 * Point;

  sellPrices[0] = NormalizeDouble(Monitor_Price_Sell_1, Digits);
  sellPrices[1] = NormalizeDouble(Monitor_Price_Sell_2, Digits);
  sellPrices[2] = NormalizeDouble(Monitor_Price_Sell_3, Digits); 
  sellPrices[3] = NormalizeDouble(Monitor_Price_Sell_4, Digits);
  sellPrices[4] = NormalizeDouble(Monitor_Price_Sell_5, Digits);

  buyPrices[0] = NormalizeDouble(Monitor_Price_Buy_1, Digits);
  buyPrices[1] = NormalizeDouble(Monitor_Price_Buy_2, Digits);
  buyPrices[2] = NormalizeDouble(Monitor_Price_Buy_3, Digits);
  buyPrices[3] = NormalizeDouble(Monitor_Price_Buy_4, Digits);
  buyPrices[4] = NormalizeDouble(Monitor_Price_Buy_5, Digits);

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

void iterateMonitorPrice() {

  for(int i = 0; i < 5; i++) {

    if(buyAllows[i]) {
      if(!hasOrderSent(buyPrices[i], OP_BUY)) {
        if(Ask + minSL < buyPrices[i]) {
          int ticket = OrderSend(thisSymbol, OP_BUYSTOP, Entry_Lot, buyPrices[i], 3, 
                                 NormalizeDouble(buyPrices[i] - SL_pips, Digits), 0, NULL, Magic_Number);
        }
      }
    }

    if(sellAllows[i]) {
      if(!hasOrderSent(sellPrices[i], OP_SELL)) {
        if(sellPrices[i] < Bid - minSL) {
          int ticket = OrderSend(thisSymbol, OP_SELLSTOP, Entry_Lot, sellPrices[i], 3, 
                                 NormalizeDouble(sellPrices[i] + SL_pips, Digits), 0, NULL, Magic_Number);
        }
      }
    }
  }
}


void trail() {
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {
        
        if(OrderType() == OP_BUY) {
          if(OrderOpenPrice() + Trail_pips < Bid && OrderStopLoss() + Trail_pips < Bid) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Bid - Trail_pips, Digits), 0, 0);
          }
        }
          
        else if(OrderType() == OP_SELL) {
          if(Ask < OrderOpenPrice() - Trail_pips && Ask < OrderStopLoss() - Trail_pips) {
            bool mod = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(Ask + Trail_pips, Digits), 0, 0);
          }
        }
      }
    }
  }
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

  updateMasks();
  iterateMonitorPrice();
  trail();
}
//+------------------------------------------------------------------+
