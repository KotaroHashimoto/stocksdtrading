//+------------------------------------------------------------------+
//|                                               2to1.HISAYOSHI.mq4 |
//|                           Copyright 2017, Palawan Software, Ltd. |
//|                             https://coconala.com/services/204383 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Palawan Software, Ltd."
#property link      "https://coconala.com/services/204383"
#property description "Author: Kotaro Hashimoto <hasimoto.kotaro@gmail.com>"
#property version   "1.00"
#property strict

#define NOOP (-1)
#define BUY_ENTRY (0)
#define SELL_ENTRY (1)
#define BUY_EXIT (2)
#define SELL_EXIT (3)

input int Magic_Number = 1;
input double Lot_Percentage = 10;

extern double TP_pips = 20;
extern double SL_pips = 20;

double minLot;
double maxLot;

string thisSymbol;
double lotStep;

const string indName = "#TSFX@AdxS";

int lastEntryTime;

int getSignal() {

  if(MathAbs(iCustom(NULL, PERIOD_CURRENT, indName, 3, 1)) == 0.05) { // 2

    if(iCustom(NULL, PERIOD_CURRENT, indName, 0, 1) == 0.0) { //orange
      return BUY_ENTRY;
    }
    else if(iCustom(NULL, PERIOD_CURRENT, indName, 1, 1) == 0.0) { //blue
      return SELL_ENTRY;
    }
  }
  if(MathAbs(iCustom(NULL, PERIOD_CURRENT, indName, 2, 1)) == 0.05) { // 1
    
    if(iCustom(NULL, PERIOD_CURRENT, indName, 0, 1) == 0.0) { //orange
      return SELL_EXIT;
    }
    else if(iCustom(NULL, PERIOD_CURRENT, indName, 1, 1) == 0.0) { //blue
      return BUY_EXIT;
    }
  }

  return NOOP;
}


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

  SL_pips *= 10.0 * Point;
  TP_pips *= 10.0 * Point;
  
  lastEntryTime = 0;
  
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
  

void close(int direction) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && (OrderMagicNumber() == Magic_Number)) {

        if(OrderType() == direction) {
          double price = (direction == OP_BUY) ? Bid : Ask;

          if(OrderClose(OrderTicket(), OrderLots(), NormalizeDouble(price, Digits), 0)) {
            i = -1;
          }
        }
      }
    }
  }
}


double getLot() {

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

  return lot;
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  int op = getSignal();
  int tk = -1;
  
  int currentTM = (int)MathFloor(TimeLocal() / PeriodSeconds());
    
  if(op == BUY_ENTRY && lastEntryTime < currentTM) {
    tk = OrderSend(thisSymbol, OP_BUY, getLot(), NormalizeDouble(Ask, Digits), 3,
                   SL_pips == 0 ? 0 : NormalizeDouble(Ask - SL_pips, Digits),
                   TP_pips == 0 ? 0 : NormalizeDouble(Ask + TP_pips, Digits),
                   NULL, Magic_Number);    
  }
  else if(op == SELL_ENTRY && lastEntryTime < currentTM) {
    tk = OrderSend(thisSymbol, OP_SELL, getLot(), NormalizeDouble(Bid, Digits), 3,
                   SL_pips == 0 ? 0 : NormalizeDouble(Bid + SL_pips, Digits),
                   TP_pips == 0 ? 0 : NormalizeDouble(Bid - TP_pips, Digits),
                   NULL, Magic_Number);
  }
  else if(op == BUY_EXIT) {
    close(OP_BUY);
  }
  else if(op == SELL_EXIT) {
    close(OP_SELL);
  }
  else { //NOOP
    ;
  }
  
  if(0 < tk) {
    lastEntryTime = (int)MathFloor(TimeLocal() / PeriodSeconds());
  }  
}
//+------------------------------------------------------------------+
