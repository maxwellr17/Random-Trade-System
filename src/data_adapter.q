/ data_adapter.q
/ created by Max Roling
/ Implements functionality to create a fake trades dataset, load it, save it, add new random trades, and update client application with new trades using a websocket connection.
/ This script saves all trades to /data in a binary format, while also saving the most recent trades to /data in a CSV format, which is used for testing

/ some misc. functions
repeat: {y#enlist x};
file_exists: {x~key x};

output_dict:()!(); / global variable with output to send to client

/ inspired by https://code.kx.com/q4m3/1_Q_Shock_and_Awe/#115-dictionaries-and-tables-101 
/ create and return a table of randomized trades
create_trades_table: {
    [num; names; max_volume; min_price; max_price]
    symbols: num?names;
    times: num?24:00:00.000;
    dates: .z.d - 1 - num?365;
    volumes: num?max_volume;
    prices: min_price+(num?max_price)%100;
    trades: `date`time xasc ([] symbol:symbols; date:dates; time:times; price:prices; volume:volumes)
    };

/ create new trades and append to trades table
make_new_trades: {
    [tablename; filename; filename_csv; num; names; max_volume; min_price; max_price]
    symbols: num?names;
    times: repeat[.z.t; num];
    dates: repeat[.z.d; num];
    volumes: num?max_volume;
    prices: min_price+(num?max_price)%100;
    newtrades: `date`time xasc ([] symbol:symbols; date:dates; time:times; price:prices; volume:volumes);

    // save newest trades to seperate csv file, then add these new trades to trades table, before updating the trades table saved to disk (not CSV, in binary format)
    save_to_csv [filename_csv; newtrades];
    tablename insert (symbols;dates;times;prices;volumes);
    filename insert (symbols;dates;times;prices;volumes); / persist changes into saved file as well

    output_dict[`func]:: enlist `make_new_trades;
    output_dict[`data]:: newtrades;
    };


/ get the last specified number of trades
get_last_n_trades: {[num; t] output_dict[`func]:: enlist [`get_last_n_trades;num]; num: neg num; output_dict[`data]:: num#t; num#t};

/ find the last number of trades, and their prices and volumes, given a ticker symbol
/ NOTE: Results of these functions are saved to output_dict, so they can be sent to clients
get_last_n_trades_by_symbol: {
    [num; s; t]
    output_dict[`func]:: enlist[`get_last_n_trades_by_symbol;num;s];
    num: neg num;
    t: select from t where symbol=s;
    output_dict[`data]:: num#t;
    num#t};

get_last_n_trade_prices_by_symbol: {
    [num; s; t]
    output_dict[`func]::enlist[`get_last_n_trade_prices_by_symbol;num;s];
    num: neg num;
    t: select price from t where symbol=s;
    t_list: t[;`price];
    output_dict[`data]::num#t_list;
    num#t_list};

get_last_n_trade_volumes_by_symbol: {
    [num; s; t]
    output_dict[`func]::enlist[`get_last_n_trade_volumes_by_symbol;num;s];
    num: neg num; 
    t: select volume from t where symbol=s;
    t_list: t[;`volume];
    output_dict[`data]::num#t_list;
    num#t_list};

/ IO Functions
// save_to_csv: {[tablename] save tablename}; / save file to csv in current directory
save_to_csv: {[filename; table] filename 0: "," 0: table}; / save file to csv in current directory



serialize: {[tablename; table] tablename set table;} / save table to file
deserialize: {[tablename] get tablename} / read table from file


/----------- Once functions are defined, this code runs on program start -----------/

/ define filename to save data to locally
filename: `$":/Users/max/Desktop/MS_preternship/Random-Trade-System/data/trades";
filename_csv: `$":/Users/max/Desktop/MS_preternship/Random-Trade-System/data/newtrades.csv";

/ if filename exists, load it into memory, otherwise create new file
$[file_exists filename;
    [
        show trades: deserialize [filename];
    ];
    [ /create and save a new trades table if it cannot be loaded from disk.
        show trades: create_trades_table [100000;`aapl`amd`zm`msft; 1000; 50; 5000];
        serialize [filename; trades];
    ]];

/ create websocket connection
\p 5420

/ Now, define functions to support WebSocket functionality
activeWSConnections: ([] handle:(); connectTime:())

/ Setup WebSocket Open and Close methods, and keep track of active connections:
/ x argument supplied to .z.wc & .z.wo is the connection handle
.z.wo:{`activeWSConnections upsert (x;.z.t); ontimer[.z.t]}; / call ontimer on connection start, so new client gets data immediately
.z.wc:{ delete from `activeWSConnections where handle =x; }
.z.ws:{z: value x; neg[.z.w] .j.j output_dict}
send:{[h]neg[h].j.j output_dict}


/ create recurring timer function
i: 0;

ontimer: {
    [timestamp]
    show timestamp;
    show activeWSConnections;

    / generate a random number of new trades (from 1 to 25), and send new trade data to all connected clients
    rnd: 1+rand 25;
    make_new_trades [`trades; filename; filename_csv; rnd; `aapl`amd`zm`msft; 1000; 50; 5000];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];

    / send last 10 prices for all assets
    / NOTE: this code checks that clients are available every time it is about to send information asynchronously. 
    / The intention is to avoid sending information if no clients are connected. 

    ret_num:10;
    get_last_n_trade_prices_by_symbol [ret_num;`aapl;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_prices_by_symbol [ret_num;`msft;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_prices_by_symbol [ret_num;`zm;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_prices_by_symbol [ret_num;`amd;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];

    / send last 10 volumes for all assets
    ret_num:10;
    get_last_n_trade_volumes_by_symbol [ret_num;`aapl;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_volumes_by_symbol [ret_num;`msft;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_volumes_by_symbol [ret_num;`zm;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];
    get_last_n_trade_volumes_by_symbol [ret_num;`amd;trades];
    if [count activeWSConnections>0; send each activeWSConnections[`handle]];


    show rnd;
    show get_last_n_trades [rnd; trades];



    // run test every other call... system call doesn't work :(
    //if[0=i mod 2; show system "npx cypress run --spec ../test/data_spec.js"];
    //i+:1;

    };


\t 10000
.z.ts:{ontimer[x]};