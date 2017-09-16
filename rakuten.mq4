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
input double n1 = 0.003;
input double n2 = 0.050;
input double n3 = 0.050;

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

input bool Trail_Sell_1 = True;
input bool Trail_Sell_2 = True;
input bool Trail_Sell_3 = True;
input bool Trail_Sell_4 = True;
input bool Trail_Sell_5 = True;

input bool Trail_Buy_1 = True;
input bool Trail_Buy_2 = True;
input bool Trail_Buy_3 = True;
input bool Trail_Buy_4 = True;
input bool Trail_Buy_5 = True;


string thisSymbol;

double minSL;

double sellPrices[] = {0, 0, 0, 0, 0};
double buyPrices[] = {0, 0, 0, 0, 0};

bool sellAllows[] = {False, False, False, False, False};
bool buyAllows[] = {False, False, False, False, False};

bool sellTrails[] = {False, False, False, False, False};
bool buyTrails[] = {False, False, False, False, False};


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

  sellTrails[0] = Trail_Sell_1;
  sellTrails[1] = Trail_Sell_2;
  sellTrails[2] = Trail_Sell_3;
  sellTrails[3] = Trail_Sell_4;
  sellTrails[4] = Trail_Sell_5;
  
  buyTrails[0] = Trail_Buy_1;
  buyTrails[1] = Trail_Buy_2;
  buyTrails[2] = Trail_Buy_3;
  buyTrails[3] = Trail_Buy_4;
  buyTrails[4] = Trail_Buy_5;  

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

  double spread = MathAbs(Ask - Bid);

  for(int i = 0; i < 5; i++) {

    if(buyAllows[i]) {
      if(!hasOrderSent(buyPrices[i], OP_BUY)) {
        if(Ask + minSL < buyPrices[i] && spread < n3) {
          int ticket = OrderSend(thisSymbol, OP_BUYSTOP, Entry_Lot, buyPrices[i], 3, 
                                 NormalizeDouble(buyPrices[i] - (spread + n1), Digits), 0, NULL, Magic_Number);
        }
      }
    }

    if(sellAllows[i]) {
      if(!hasOrderSent(sellPrices[i], OP_SELL)) {
        if(sellPrices[i] < Bid - minSL && spread < n3) {
          int ticket = OrderSend(thisSymbol, OP_SELLSTOP, Entry_Lot, sellPrices[i], 3, 
                                 NormalizeDouble(sellPrices[i] + (spread + n1), Digits), 0, NULL, Magic_Number);
        }
      }
    }
  }
}


bool isTrailing(double openPrice, int direction) {

  for(int i = 0; i < 5; i++) {

    if(direction == OP_BUY) {
      if(buyPrices[i] == openPrice) {
        return buyTrails[i];
      }
    }
    else if(direction == OP_SELL) {
      if(sellPrices[i] == openPrice) {
        return sellTrails[i];
      }
    }
  }

  return False;
}


void trail() {

  double spread = MathAbs(Ask - Bid);
  
  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && OrderMagicNumber() == Magic_Number) {

        double op = OrderOpenPrice();
        double sl = OrderStopLoss();
        
        if(OrderType() == OP_BUY) {
          if(sl < op && sl + (spread + n1) < Bid) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Bid - (spread + n1), Digits), 0, 0);
          }
	  else if(isTrailing(op, OP_BUY) && sl + n2 < Bid) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Bid - n2, Digits), 0, 0);	    
	  }
        }

        else if(OrderType() == OP_SELL) {
          if(op < sl && Ask < sl - (spread + n1)) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Ask + (spread + n1), Digits), 0, 0);
          }
	  else if(isTrailing(op, OP_SELL) && Ask < sl - n2) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Ask + n2, Digits), 0, 0);	    
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
