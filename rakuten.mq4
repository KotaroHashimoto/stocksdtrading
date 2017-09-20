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

input int Magic_Number = 10;
input double Entry_Lot = 0.1;
input double n1 = 0.003;
input double n2 = 0.5;
input double n3 = 0.5;
input double SL_Percentage = 10.0;

input bool Force_Exit = True;
input bool Force_Entry = True;

input int Display_Sec = 30;

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
double slp;

double sellPrices[] = {0, 0, 0, 0, 0};
double buyPrices[] = {0, 0, 0, 0, 0};

bool sellAllows[] = {False, False, False, False, False};
bool buyAllows[] = {False, False, False, False, False};

bool sellTrails[] = {False, False, False, False, False};
bool buyTrails[] = {False, False, False, False, False};

int sellMN[] = {-1, -2, -3, -4, -5};
int buyMN[] = {1, 2, 3, 4, 5};

const string forceID = "force";
datetime lastDisplay;
int fp;

void drawLabel() {

  ObjectCreate(0, forceID, OBJ_LABEL, 0, 0, 0);
  ObjectSetInteger(0, forceID, OBJPROP_CORNER, CORNER_LEFT_UPPER);
  ObjectSet(forceID, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
  ObjectSetInteger(0, forceID, OBJPROP_SELECTABLE, false);

  ObjectSetText(forceID, "Normal", 14, "Arial", clrYellow);
}

bool hasOrderSent(int magicNumber, int type) {

  for(int i = 0; i < OrdersTotal(); i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && magicNumber == OrderMagicNumber()) {
        if(OrderType() == OP_BUY || OrderType() == OP_BUYSTOP) {
          if(type == OP_BUY && !(OrderType() == OP_BUY && Bid <= OrderStopLoss())) {
            return True;
          }
        }
        else if(OrderType() == OP_SELL || OrderType() == OP_SELLSTOP) {
          if(type == OP_SELL && !(OrderType() == OP_SELL && OrderStopLoss() <= Ask)) {
            return True;
          }
        }

        return False;
      }
    }
  }

  return False;
}



void forceClose() {

  for(int i = 0; i < OrdersTotal() && Force_Exit; i++) {
    if(OrderSelect(i, SELECT_BY_POS)) {
      if(!StringCompare(OrderSymbol(), thisSymbol) && MathAbs(OrderMagicNumber() - Magic_Number) <= 5) {
        if(OrderType() == OP_BUY && Bid <= OrderStopLoss()) {
	  bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, 100);
	  
	  ObjectSetText(forceID, TimeToString(TimeLocal()) + " force BUY EXIT at " + DoubleToString(Bid), 14, "Arial", clrYellow);
          FileWrite(fp, TimeToString(TimeLocal()), "force BUY EXIT", DoubleToString(Bid), DoubleToString(Entry_Lot), DoubleToString(OrderOpenPrice()), DoubleToString(OrderProfit()));	  
          lastDisplay = TimeLocal();
	  
	  i = -1;
        }
        else if(OrderType() == OP_SELL && OrderStopLoss() <= Ask) {
	  bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, 100);

          ObjectSetText(forceID, TimeToString(TimeLocal()) + " force SELL EXIT at " + DoubleToString(Ask), 14, "Arial", clrYellow);
          FileWrite(fp, TimeToString(TimeLocal()), "force SELL EXIT", DoubleToString(Ask), DoubleToString(Entry_Lot), DoubleToString(OrderOpenPrice()), DoubleToString(OrderProfit()));	  	  
          lastDisplay = TimeLocal();
	  
	  i = -1;
        }
      }
    }
  }
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

  lastDisplay = 0;
  thisSymbol = Symbol();
  drawLabel();

  fp = FileOpen("ForceEnterExitHistory_" + thisSymbol + ".csv", FILE_CSV|FILE_READ|FILE_WRITE, ',');
  if(fp < 0) {
    Print("File write error. " + string(GetLastError()));
  }

  slp = SL_Percentage / 100.0;
  
  minSL = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
  
  sellPrices[0] = NormalizeDouble(Monitor_Price_Buy_5, Digits);
  sellPrices[1] = NormalizeDouble(Monitor_Price_Sell_2, Digits);
  sellPrices[2] = NormalizeDouble(Monitor_Price_Sell_3, Digits); 
  sellPrices[3] = NormalizeDouble(Monitor_Price_Sell_4, Digits);
  sellPrices[4] = NormalizeDouble(Monitor_Price_Sell_5, Digits);

  buyPrices[0] = NormalizeDouble(Monitor_Price_Buy_1, Digits);
  buyPrices[1] = NormalizeDouble(Monitor_Price_Buy_2, Digits);
  buyPrices[2] = NormalizeDouble(Monitor_Price_Buy_3, Digits);
  buyPrices[3] = NormalizeDouble(Monitor_Price_Buy_4, Digits);
  buyPrices[4] = NormalizeDouble(Monitor_Price_Sell_1, Digits);

  sellTrails[0] = Trail_Buy_5;
  sellTrails[1] = Trail_Sell_2;
  sellTrails[2] = Trail_Sell_3;
  sellTrails[3] = Trail_Sell_4;
  sellTrails[4] = Trail_Sell_5;
  
  buyTrails[0] = Trail_Buy_1;
  buyTrails[1] = Trail_Buy_2;
  buyTrails[2] = Trail_Buy_3;
  buyTrails[3] = Trail_Buy_4;
  buyTrails[4] = Trail_Sell_1;  

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  FileClose(fp);
  }

void iterateMonitorPrice() {

  double spread = MathAbs(Ask - Bid);

  for(int i = 0; i < 5; i++) {

    if(buyAllows[i]) {
      if(!hasOrderSent(Magic_Number + buyMN[i], OP_BUY)) {
        if(Ask /*+ minSL*/ <= buyPrices[i]/* && spread <= n3*/) {
          int ticket = OrderSend(thisSymbol, OP_BUYSTOP, Entry_Lot, buyPrices[i], 3, 
                                 NormalizeDouble(buyPrices[i] - (spread + n1), Digits), 0, NULL, Magic_Number + buyMN[i]);

          if(ticket <= 0 && Force_Entry) {
	         ticket = OrderSend(thisSymbol, OP_BUY, Entry_Lot, NormalizeDouble(Ask, Digits), 100, NormalizeDouble(Ask - (spread + n1), Digits), 0, NULL, Magic_Number + buyMN[i]);
            ObjectSetText(forceID, TimeToString(TimeLocal()) + " force BUY ENTRY at " + DoubleToString(Ask), 14, "Arial", clrYellow);
            FileWrite(fp, TimeToString(TimeLocal()), "force BUY ENTRY", DoubleToString(Ask), DoubleToString(Entry_Lot));
            lastDisplay = TimeLocal();
          }
        }
      }
    }

    if(sellAllows[i]) {
      if(!hasOrderSent(Magic_Number + sellMN[i], OP_SELL)) {
        if(sellPrices[i] <= Bid /*- minSL*//* && spread <= n3*/) {
          int ticket = OrderSend(thisSymbol, OP_SELLSTOP, Entry_Lot, sellPrices[i], 3, 
                                 NormalizeDouble(sellPrices[i] + (spread + n1), Digits), 0, NULL, Magic_Number + sellMN[i]);

          if(ticket <= 0 && Force_Entry) {
            ticket = OrderSend(thisSymbol, OP_SELL, Entry_Lot, NormalizeDouble(Bid, Digits), 100, NormalizeDouble(Bid + (spread + n1), Digits), 0, NULL, Magic_Number + sellMN[i]);
            ObjectSetText(forceID, TimeToString(TimeLocal()) + " force SELL ENTRY at " + DoubleToString(Bid), 14, "Arial", clrYellow);
            FileWrite(fp, TimeToString(TimeLocal()), "force SELL ENTRY", DoubleToString(Bid), DoubleToString(Entry_Lot));	    
            lastDisplay = TimeLocal();
          }
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
      if(!StringCompare(OrderSymbol(), thisSymbol) && MathAbs(OrderMagicNumber() - Magic_Number) <= 5) {

        double op = OrderOpenPrice();
        double sl = OrderStopLoss();
        
        if(OrderType() == OP_BUY) {
          if(sl < op && sl + (spread + n1) < Bid) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Bid - (spread + n1), Digits), 0, 0);
          }
	  else if(isTrailing(op, OP_BUY) && op + n2 < Bid && sl + slp * (Bid - op) < Bid) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Bid - slp * (Bid - op), Digits), 0, 0);	    
	  }
        }

        else if(OrderType() == OP_SELL) {
          if(op < sl && Ask < sl - (spread + n1)) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Ask + (spread + n1), Digits), 0, 0);
          }
	  else if(isTrailing(op, OP_SELL) && Ask < op - n2 && Ask < sl - slp * (op - Ask)) {
            bool mod = OrderModify(OrderTicket(), op, NormalizeDouble(Ask + slp * (op - Ask), Digits), 0, 0);	    
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

  if(TimeLocal() - lastDisplay > Display_Sec) {
    ObjectSetText(forceID, "Normal", 14, "Arial", clrYellow);
  }

  double price = (Ask + Bid) / 2.0;
  int buyNum = 0;
  int sellNum = 0;

  forceClose();
  updateMasks();
  iterateMonitorPrice();
  trail();
}
//+------------------------------------------------------------------+
