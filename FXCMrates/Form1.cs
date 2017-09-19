#define DEBUG
#undef DEBUG

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using fxcore2;
using System.Threading;


namespace TickChart
{
    public partial class Form1 : Form
    {
        static private bool vLineEnabled = true;
        static private int N = 32;
        static private int WIDTH = 245;
        static private int HEIGHT = 245;

        private List<double> bids = null;
        private List<double> asks = null;
        private int index = 0;

        System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();

        Random rand = null;

        ForexConnect fx = null;

        public Form1()
        {
            InitializeComponent();
        }

        private void update(double bid, double ask)
        {
#if DEBUG
            bids[index] = bids[(index + (N - 1)) % N] + rand.NextDouble() - 0.5;
            asks[index] = bids[index] + 0.5 * rand.NextDouble();
#else
            bids[index] = bid;
            asks[index] = ask;
#endif

            index = (index + 1) % N;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            asks = new List<double>(N);
            bids = new List<double>(N);

            for (int i = 0; i < N; i++)
            {
                double p = 100;// update();
                bids.Add(p);
                asks.Add(p + 0.003);
            }

            comboBox1.Items.Add("USD/JPY");
            comboBox1.Items.Add("EUR/USD");
            comboBox1.Items.Add("EUR/JPY");
            comboBox1.Items.Add("GBP/JPY");
            comboBox1.Items.Add("GBP/USD");
            comboBox1.Items.Add("AUD/JPY");
            comboBox1.Items.Add("GBP/AUD");
            comboBox1.Items.Add("AUD/USD");
            comboBox1.Items.Add("EUR/GBP");
            comboBox1.Items.Add("CAD/JPY");
            comboBox1.Items.Add("CHF/JPY");
            comboBox1.Items.Add("AUD/CHF");
            comboBox1.Items.Add("EUR/SEK");
            comboBox1.Items.Add("AUD/CAD");
            comboBox1.Items.Add("USD/ZAR");
            comboBox1.Items.Add("TRY/JPY");
            comboBox1.Items.Add("AUD/NZD");
            comboBox1.Items.Add("GBP/CHF");
            comboBox1.Items.Add("EUR/TRY");
            comboBox1.Items.Add("USD/CNH");
            comboBox1.Items.Add("EUR/NOK");
            comboBox1.Items.Add("NZD/CAD");
            comboBox1.Items.Add("NZD/USD");
            comboBox1.Items.Add("USD/CHF");
            comboBox1.Items.Add("EUR/AUD");
            comboBox1.Items.Add("USD/CAD");
            comboBox1.Items.Add("USD/TRY");
            comboBox1.Items.Add("NZD/JPY");
            comboBox1.Items.Add("CAD/CHF");
            comboBox1.Items.Add("USD/SEK");
            comboBox1.Items.Add("EUR/CAD");
            comboBox1.Items.Add("ZAR/JPY");
            comboBox1.Items.Add("NZD/CHF");
            comboBox1.Items.Add("USD/MXN");
            comboBox1.Items.Add("EUR/CHF");
            comboBox1.Items.Add("GBP/NZD");
            comboBox1.Items.Add("USD/JPY");
            comboBox1.Items.Add("GBP/CAD");
            comboBox1.Items.Add("EUR/NZD");
            comboBox1.Items.Add("USD/NOK");
            comboBox1.Items.Add("USD/HKD");
            comboBox1.Items.Add("XAU/USD");
            comboBox1.Items.Add("XAG/USD");


            comboBox1.Items.Add("JPN225");
            comboBox1.Items.Add("SPX500");
            comboBox1.Items.Add("AUS200");
            comboBox1.Items.Add("Copper");
            comboBox1.Items.Add("GER30");
            comboBox1.Items.Add("ESP35");
            comboBox1.Items.Add("NAS100");
            comboBox1.Items.Add("UKOil");
            comboBox1.Items.Add("US30");
            comboBox1.Items.Add("UK100");
            comboBox1.Items.Add("HKG33");
            comboBox1.Items.Add("Bund");
            comboBox1.Items.Add("NGAS");
            comboBox1.Items.Add("FRA40");
            comboBox1.Items.Add("USOil");
            comboBox1.Items.Add("USDOLLAR");
            comboBox1.Items.Add("EUSTX50");

            comboBox1.SelectedText = "USD/JPY";

            Form1_SizeChanged(sender, e);

#if DEBUG
            rand = new Random();
            timer.Tick += new EventHandler(onTimer);
            timer.Interval = 1000;
            timer.Enabled = true;
#else
            fx = new ForexConnect("D25608381", "9954", this, comboBox1.Text);
#endif
        }

        void onTimer(object sender, EventArgs e)
        {
            onUpdate(1, 1);
        }

        public void onUpdate(double bid, double ask)
        {
            update(bid, ask);
            this.Invalidate();
        }

        int getCoordinate(double p, double min, double max)
        {
            return 50 + HEIGHT - (int)Math.Round((double)HEIGHT * (p - min) / (max - min));
        }

        void drawGrid(double min, double max, PaintEventArgs e)
        {
            int ln = 7;
            List<int> hLines = new List<int>(ln + 1);

            double step = (max - min) / (double)(2 * ln);
            //            Console.WriteLine();
            //            Console.WriteLine(step);

            if (step < 0.00001)
            {
                step = Math.Round(step, 6);
                min = Math.Round(min, 6);
            }
            else if (step < 0.0001)
            {
                step = Math.Round(step, 5);
                min = Math.Round(min, 5);
            }
            else if (step < 0.001)
            {
                step = Math.Round(step, 4);
                min = Math.Round(min, 4);
            }
            else if (step < 0.01)
            {
                step = Math.Round(step, 3);
                min = Math.Round(min, 3);
            }
            else if (step < 0.1)
            {
                step = Math.Round(step, 2);
                min = Math.Round(min, 2);
            }
            else if (step < 1)
            {
                step = Math.Round(step, 1);
                min = Math.Round(min, 1);
            }
            else
            {
                step = Math.Round(step, 0);
                min = Math.Round(min, 0);
            }

            //            Console.WriteLine(step);
            for (int i = 0; i < ln + 1; i++)
            {
                //                Console.WriteLine(min + step * (1 + 2 * i));
                hLines.Add(getCoordinate(min + step * (1 + 2 * i), min, max));
            }

            Pen gridPen = new Pen(Color.Black, 1);
            gridPen.DashStyle = System.Drawing.Drawing2D.DashStyle.Dash;

            Font font = new Font("Consolas", 8);

            int j = 0;
            foreach (int lp in hLines)
            {
                Point[] g = new Point[] { new Point(10, lp), new Point(10 + WIDTH, lp) };
                e.Graphics.DrawLines(gridPen, g);
                e.Graphics.DrawString((min + step * (1 + 2 * (j++))).ToString(), font, Brushes.Black, WIDTH + 15, lp - 5);
            }

            if (vLineEnabled) {
                int tDelta = (int)(WIDTH / N);
                for (int i = 0; i < N; i++)
                {
                    int x = 10 + tDelta * i;
                    Point[] g = new Point[] { new Point(x, 50), new Point(x, 50 + HEIGHT) };
                    e.Graphics.DrawLines(gridPen, g);
                }
            }

            gridPen.Dispose();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            label1.Text = DateTime.Now.ToString();

            base.OnPaint(e);

            Pen askPen = new Pen(Color.Red, 1);
            Pen bidPen = new Pen(Color.Blue, 1);

            Point[] askPoint = new Point[N];
            Point[] bidPoint = new Point[N];

            double min = bids.Min();
            double max = asks.Max();
            int tDelta = (int)(WIDTH / N);

            for (int i = index, t = 10, vi = 0; vi < N; i = (i + 1) % N, t += tDelta, vi++)
            {
                askPoint[vi] = new Point(t, getCoordinate(asks[i], min, max));
                bidPoint[vi] = new Point(t, getCoordinate(bids[i], min, max));
            }

            e.Graphics.DrawLines(askPen, askPoint);
            e.Graphics.DrawLines(bidPen, bidPoint);

            askPen.DashStyle = System.Drawing.Drawing2D.DashStyle.Dot;
            bidPen.DashStyle = System.Drawing.Drawing2D.DashStyle.Dot;

            Font font = new Font("Consolas", 10);

            int pIndex = (index + (N - 1)) % N;
            //            Console.WriteLine(index);
            e.Graphics.DrawLines(askPen, new Point[] { new Point(10, askPoint[N - 1].Y), new Point(10 + WIDTH, askPoint[N - 1].Y) });
            e.Graphics.DrawString(asks[pIndex].ToString(), font, Brushes.Red, WIDTH + 15, askPoint[N - 1].Y - 6);

            e.Graphics.DrawLines(bidPen, new Point[] { new Point(10, bidPoint[N - 1].Y), new Point(10 + WIDTH, bidPoint[N - 1].Y) });
            e.Graphics.DrawString(bids[pIndex].ToString(), font, Brushes.Blue, WIDTH + 15, bidPoint[N - 1].Y - 6);

            askPen.Dispose();
            bidPen.Dispose();

            drawGrid(min, max, e);
        }

        private void comboBox1_SelectedIndexChanged(object sender, EventArgs e)
        {

            ForexConnect.sInstrument = comboBox1.Text;
            Console.WriteLine(ForexConnect.sInstrument);
/*
            for (int i = 0; i < N; i++)
                bids[index] = bids[(index + (N - 1)) % N] + rand.NextDouble() - 0.5;
            asks[index] = bids[index] + 0.5 * rand.NextDouble();

            index = (index + 1) % N;
            */
        }

        private void Form1_SizeChanged(object sender, EventArgs e)
        {
            Control control = (Control)sender;
            HEIGHT = control.Size.Height - 105;
            WIDTH = control.Size.Width - 100;
        }

        private void Form1_DoubleClick(object sender, EventArgs e)
        {
            vLineEnabled = !vLineEnabled;
        }
    }


    class ForexConnect
    {
        static Form1 fm = null;

        static O2GSession mSession;
        private static string sSessionID = "";
        public static string SessionID
        {
            get { return sSessionID; }
        }
        private static string sPin = "";
        public static string Pin
        {
            get { return sPin; }
        }

        public static string sInstrument = "";


        public ForexConnect(string userid, string password, Form1 form, string symbol)
        {
            ForexConnect.sInstrument = symbol;
            Console.WriteLine(ForexConnect.sInstrument);
            fm = form;

            string sUserID = userid;
            string sPassword = password;
            string sURL = "http://www.fxcorporate.com/Hosts.jsp";
            string sConnection = "Demo";

            try
            {
                mSession = O2GTransport.createSession();

                SessionStatusListener statusListener = new SessionStatusListener(mSession);
                mSession.subscribeSessionStatus(statusListener);
                mSession.useTableManager(O2GTableManagerMode.Yes, null);

                mSession.login(sUserID, sPassword, sURL, sConnection);

                while (statusListener.Status != O2GSessionStatusCode.Connected && statusListener.Status != O2GSessionStatusCode.Disconnected)
                    Thread.Sleep(50);
                if (statusListener.Status == O2GSessionStatusCode.Connected)
                {
                    O2GTableManager manager = mSession.getTableManager();
                    while (manager.getStatus() == O2GTableManagerStatus.TablesLoading)
                        Thread.Sleep(50);
                    O2GOffersTable offers = null;
                    if (manager.getStatus() == O2GTableManagerStatus.TablesLoaded)
                    {
                        offers = (O2GOffersTable)manager.getTable(O2GTableType.Offers);
                        printOffers(offers);
                        offers.RowChanged += new EventHandler<RowEventArgs>(offers_RowChanged);
                    }
                    else
                    {
                        Console.WriteLine("Tables loading failed!");
                    }
                    /*
                    Console.WriteLine("Press enter to stop!");
                    Console.ReadLine();

                    if (offers != null)
                    {
                        offers.RowChanged -= new EventHandler<RowEventArgs>(offers_RowChanged);
                    }

                    mSession.logout();
                    */
                }
//                mSession.unsubscribeSessionStatus(statusListener);
//                mSession.Dispose();
            }
            catch (Exception e)
            {
                Console.WriteLine("Exception: {0}", e.ToString());
            }
        }

        static void offers_RowChanged(object sender, RowEventArgs e)
        {
            O2GOfferTableRow row = (O2GOfferTableRow)e.RowData;
            string sCurrentInstrument = row.Instrument;
            if ((sInstrument.Equals("")) || (sInstrument.Equals(sCurrentInstrument))) {
                PrintOffer(row);
            }
        }

        public static void printOffers(O2GOffersTable offers)
        {
            O2GOfferTableRow row = null;
            O2GTableIterator iterator = new O2GTableIterator();
            while (offers.getNextRow(iterator, out row))
            {
                string sCurrentInstrument = row.Instrument;
                if ((sInstrument.Equals("")) || (sInstrument.Equals(sCurrentInstrument)))
                    PrintOffer(row);
            }
        }

        public static void PrintOffer(O2GOfferTableRow row)
        {

            //Console.WriteLine("OfferID: {0}, Instrument: {1}, Bid: {2}, Ask: {3}, PipCost: {4}", row.OfferID, row.Instrument, row.Bid, row.Ask, row.PipCost);
            //            Console.WriteLine(row.Instrument);
            fm.onUpdate(row.Bid, row.Ask);
        }
    }

    class SessionStatusListener : IO2GSessionStatus
    {
        private O2GSessionStatusCode mCode = O2GSessionStatusCode.Unknown;
        private O2GSession mSession = null;

        public O2GSessionStatusCode Status
        {
            get
            {
                return mCode;
            }
        }

        public SessionStatusListener(O2GSession session)
        {
            mSession = session;
        }

        public void onSessionStatusChanged(O2GSessionStatusCode code)
        {
            mCode = code;
            Console.WriteLine(code.ToString());
            if (code == O2GSessionStatusCode.TradingSessionRequested)
            {
                if (ForexConnect.SessionID == "")
                    Console.WriteLine("Argument for trading session ID is missing");
                else
                    mSession.setTradingSession(ForexConnect.SessionID, ForexConnect.Pin);
            }
        }

        public void onLoginFailed(string error)
        {
            Console.WriteLine("Login error " + error);
        }
    }
}
