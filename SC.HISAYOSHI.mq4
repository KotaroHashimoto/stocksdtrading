//+------------------------------------------------------------------+
//|                                                 SC.HISAYOSHI.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict


input int Magic_Number = 1;
input double Lot_Percentage = 10;

double minLot;
double maxLot;

string thisSymbol;
double lotStep;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

  minLot = MarketInfo(Symbol(), MODE_MINLOT);
  maxLot = MarketInfo(Symbol(), MODE_MAXLOT);

  thisSymbol = Symbol();
  lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
   
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
  
void positionCount(int& buyPos, int& sellPos) {

  buyPos = 0;
  sellPos = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() == Magic_Number)) {
      
        if(OrderType() == OP_BUY) {
          buyPos ++;
        }
        else if(OrderType() == OP_SELL) {
          sellPos ++;
        }
      }
    }
  }
}


void mirrorPositionCount(int& buyPos, int& sellPos) {

  buyPos = 0;
  sellPos = 0;

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() != Magic_Number)) {
      
        if(OrderType() == OP_BUY) {
          buyPos ++;
        }
        else if(OrderType() == OP_SELL) {
          sellPos ++;
        }
      }
    }
  }
}


void getTicket(int& ticket, double& lot, int direction) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() == Magic_Number)) {

        if(OrderType() == direction) {
          ticket = OrderTicket();
          lot = OrderLots();
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

  int mirrorBuy, mirrorSell;
  mirrorPositionCount(mirrorBuy, mirrorSell);

  int selfBuy, selfSell;
  positionCount(selfBuy, selfSell);
  
  
  if(selfBuy < mirrorSell || selfSell < mirrorBuy) {  
  
    int pos = (selfSell < mirrorBuy) ? OP_SELL : OP_BUY;
    double price = (selfSell < mirrorBuy) ? Bid : Ask;    

    double lot = (AccountEquity() * Lot_Percentage / 100.0) / 100000.0;
    lot = MathRound(lot / lotStep) * lotStep;
    
    if(maxLot < lot) {
      lot = maxLot;
      Print("Lot size(", lot, ") is larger than max(", maxLot, "). Rounded to ", maxLot, ".");
    }
    else if(lot < minLot) {
      lot = minLot;
      Print("Lot size(", lot, ") is smaller than min(", minLot, "). Rounded to ", minLot, ".");
    }    
    
    int tk = OrderSend(thisSymbol, pos, lot, NormalizeDouble(price, Digits), 3, 0, 0, NULL, Magic_Number);    
  }
  
  if(mirrorSell < selfBuy || mirrorBuy < selfSell) {

    int ticket;
    double lotsize;

    getTicket(ticket, lotsize, (mirrorSell < selfBuy) ? OP_BUY : OP_SELL);    
    double price = (mirrorSell < selfBuy) ? Bid : Ask;    
    
    bool closed = OrderClose(ticket, lotsize, NormalizeDouble(price, Digits), 0);
  }
   
}
//+------------------------------------------------------------------+
