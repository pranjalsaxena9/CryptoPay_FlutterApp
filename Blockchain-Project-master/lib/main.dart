import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/material.dart';
import 'slider_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'PKCOIN'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Client httpClient;
  Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  final myAddress = "0x4A458AF58e801BbF4F9d1dD81373d0c1E27cc8B9";
  String txHash;
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client("https://rinkeby.infura.io/v3/ff9a7fa746c84ad99be80b46b7cd4844",
        httpClient);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0xa808e9df15683720292ff6507418A4d6becfF5C6";

    final contract = DeployedContract(ContractAbi.fromJson(abi,"PKCoin"),EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    setState(() {});

  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "5436150aaaab58ac2770dc43e3389031d36fe2227114fa36c73858c90495fd8d");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),fetchChainIdFromNetworkId: false,chainId: 1);
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance",[bigAmount]);

    print("Deposited");
    txHash=response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance",[bigAmount]);

    print("Withdrawn");
    txHash=response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight*30)
            .make(),

        VStack([
          (context.percentHeight*10).heightBox,
          "\₹PKCOIN".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight*10).heightBox,
          VxBox(child: VStack([
            "Balance".text.gray700.xl2.semiBold.makeCentered(),
            data?"\₹$myData".text.bold.xl6.makeCentered().shimmer()
                :CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight*18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,

          SliderWidget(
            min: 0,
            max: 100,
            finalVal: (value) {
              myAmount = (value*100).round();
              print(myAmount);
            }
          ).centered(),

          HStack([
            FlatButton.icon(
                onPressed: ()=> getBalance(myAddress),
                color: Colors.blue,
                shape: Vx.roundedSm,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                label: "Refresh".text.white.make(),
            ).h(50),
            FlatButton.icon(
              onPressed: ()=> sendCoin(),
              color: Colors.green,
              shape: Vx.roundedSm,
              icon: Icon(
                Icons.call_made_outlined,
                color: Colors.white,
              ),
              label: "Deposit".text.white.make(),
            ).h(50),
            FlatButton.icon(
              onPressed: ()=> withdrawCoin(),
              color: Colors.red,
              shape: Vx.roundedSm,
              icon: Icon(
                Icons.call_received_outlined,
                color: Colors.white,
              ),
              label: "Withdraw".text.white.make(),
            ).h(50),
          ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16(),
          if(txHash!=null) txHash.text.black.makeCentered()
        ])
      ]),


    );
  }
}
