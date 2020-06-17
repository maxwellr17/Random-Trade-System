# Random-Trade-System
A simple application using Q and AngularJS to demonstrate a mock equity trade system.

The KDB+ Q backend maintains a trades table with the ticker symbol, date, time, price, and volume of each trade. This table is maintained on the disk as a continuously updated CSV file, and information can be sent to the client using a websocket connection. The client maintains this connection to serve up-to-date information to the user as it changes. 
