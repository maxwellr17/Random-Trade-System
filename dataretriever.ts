var app = angular.module("mktdata", ['chart.js']);

app.controller("ctrl", function($scope) {
    $scope.testing = "testing testing 123";
    $scope.last_trades = [];
    $scope.all_data_retrieved = true;
    $scope.prices = [[],[],[],[]];
    $scope.volumes = [[],[],[],[]];
    $scope.series = ["aapl", 'amd', 'msft', 'zm'];
    $scope.labels = ['-9', '-8', '-7', '-6', '-5', '-4', '-3', '-2', '-1', '0']; //Array.from(Array(10), (_, index) => index + 1);

    // Unit test to ensure that data sent to website is the same as the data stored on disk (and in memory) of KDB process.
    $scope.test = function() {
        // get csv file of in memory trades table from HTTP request: http://localhost:5420/.csv?trades
        // get csv file of CSV file saved to disk from HTTP request: http://localhost:5420/.csv?deserialize[filename]
        const Http = new XMLHttpRequest();
        const url='http://localhost:5420/.csv?trades';
        Http.open("GET", url);
        Http.send();

        Http.onreadystatechange = (e) => {
        console.log(Http.responseText)
        };
    }

    $scope.onConnectionOpen = function() {console.log("websocket connection open")};
    $scope.recievedData = function(e) {
        console.log("recieved data!");
        console.log(e);
        $scope.retrieved = JSON.parse(e.data);

        switch($scope.retrieved.func[0]){
            case "make_new_trades":
                $scope.last_trades = $scope.retrieved.data;
                
                // $scope.test();

                break;
            case "get_last_n_trade_prices_by_symbol":
                if ($scope.retrieved.func[2] === 'aapl') {
                    console.log("aapl recieved");
                    $scope.aapl_prices = $scope.retrieved.data;
                    $scope.prices[0] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'amd') {
                    console.log("amd recieved");
                    $scope.amd_prices = $scope.retrieved.data;
                    $scope.prices[1] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'msft') {
                    console.log("msft recieved");
                    $scope.msft_prices = $scope.retrieved.data;
                    $scope.prices[2] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'zm') {
                    console.log("zm recieved");
                    $scope.zm_prices = $scope.retrieved.data;
                    $scope.prices[3] = $scope.retrieved.data;
                }
                break;

            case "get_last_n_trade_volumes_by_symbol":
                if ($scope.retrieved.func[2] === 'aapl') {
                    console.log("aapl recieved");
                    $scope.aapl_volumes = $scope.retrieved.data;
                    $scope.volumes[0] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'amd') {
                    console.log("amd recieved");
                    $scope.amd_volumes = $scope.retrieved.data;
                    $scope.volumes[1] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'msft') {
                    console.log("msft recieved");
                    $scope.msft_volumes = $scope.retrieved.data;
                    $scope.volumes[2] = $scope.retrieved.data;
                } else if ($scope.retrieved.func[2] === 'zm') {
                    console.log("zm recieved");
                    $scope.zm_volumes = $scope.retrieved.data;
                    $scope.volumes[3] = $scope.retrieved.data;
                }
                break;
        }


        if($scope.aapl_volumes && $scope.amd_volumes
            && $scope.msft_volumes && $scope.zm_volumes
            && $scope.aapl_prices && $scope.amd_prices
            && $scope.msft_prices && $scope.zm_prices) {
            $scope.all_data_retrieved = true;
        }
        
        console.log($scope.retrieved);
        $scope.$digest();
    };

    $scope.onConnectionClose = function() {console.log("websocket connection closed")};

    $scope.sendData = function(data) {
        if($scope.socket) {
            console.log("sending data: " + data);
            $scope.socket.send(data);
        }
    }

    $scope.startSocket = function () {
        if ("WebSocket" in window) {
            console.log('starting websocket...');
            $scope.socket = new WebSocket("ws://localhost:5420");
            $scope.socket.binaryType = 'arraybuffer';
            $scope.socket.onopen = $scope.onConnectionOpen;
            $scope.socket.onmessage = $scope.recievedData;
            $scope.socket.onclose = $scope.onConnectionClose;
        } else {
            alert("WebSockets are not supported by your browser.");
        }
    };

    // start connection
    $scope.startSocket();

});