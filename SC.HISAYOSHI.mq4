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

string thisSymbol;
double lotStep;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

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
  
int hasPosition(int& ticket, double& selfLot) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() == Magic_Number)) {
      
        ticket = OrderTicket();
        selfLot = OrderLots();
        
        return OrderType();
      }
    }
  }

  return -1;
}


int hasPositionMirror() {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() != Magic_Number)) {
        return OrderType();
      }
    }
  }

  return -1;
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  int ticket;
  double selfLot;

  int selfPos = hasPosition(ticket, selfLot);
  int mirrorPos = hasPositionMirror();
  
  if(selfPos < 0 && 0 <= mirrorPos) {  
  
    int pos = (mirrorPos == OP_BUY) ? OP_SELL : OP_BUY;
    double price = (mirrorPos == OP_BUY) ? Bid : Ask;    

    double lot = (AccountEquity() * Lot_Percentage / 100.0) / 100000.0;
    lot = MathRound(lot / lotStep) * lotStep;
    
    int tk = OrderSend(thisSymbol, pos, lot, NormalizeDouble(price, Digits), 3, 0, 0, NULL, Magic_Number);    
  }
  
  else if(mirrorPos < 0 && 0 <= selfPos) {  
  
    double price = (selfPos == OP_BUY) ? Bid : Ask;    
    bool closed = OrderClose(ticket, selfLot, NormalizeDouble(price, Digits), 0);
  }
   
}
//+------------------------------------------------------------------+
