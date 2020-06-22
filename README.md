# Random-Trade-System
A simple application using Q and AngularJS to demonstrate a mock equity trade system.

The KDB+ Q backend maintains a randomized trades table with the ticker symbol, date, time, price, and volume of each trade. This table is maintained on the disk as a continuously updated binary file, and information can be sent to the client using a websocket connection. The client maintains this connection to serve up-to-date information to the user as it changes, while also presenting the latest trades and graphs showing the prices and volumes of each trade.

### To run the program, do the following:
1. cd into the appropriate directory
2. Run "npm install" to install dependencies
3. Run "q src/data_adapter.q" to start the Q backend
4. In a seperate terminal window, run ./compile.sh to compile and run the program. This will initiate a local http server and open the client on http://localhost:8080

The Q backend also maintains a newtrades.csv file containing the most recent trades. In order to test whether the client is recieving the correct information from the q process, I've set up a testing framework using Cypress (https://www.cypress.io). Cypress is an end-to-end testing framework which is significantly faster than other solutions like Protractor or Selenium, as it runs in the same run loop as the tested application. I've written a simple test which reads the newtrades.csv file and compares it to the client, ensuring that the information was sent appropriately over the WebSocket connection.

To run the test, first ensure that the client is running on port 8080, then open a new terminal window and run "npx cypress open". A web-browser window will appear and allow you to run the data_spec.js file, containing the necessary test. Note that the test only runs once, however I am working on getting it to continuously rerun and ensure that all future data retrieved is also correct. Alternatively, you can run 'npx cypress run --spec "test/data_spec.js" ' to run the headless test in the console. 