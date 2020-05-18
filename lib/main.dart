import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:geocoder/geocoder.dart';
import 'package:travelown/widgets/divider_with_text_widget.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import 'credentials.dart';
import 'models/Place.dart';
import 'models/Trip.dart';


void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NewTripLocationView(trip: Trip(null,null,null,null,null)),
    );
  }
}


class NewTripLocationView extends StatefulWidget {
  final Trip trip;

  NewTripLocationView({Key key, @required this.trip}) : super(key: key);

  @override
  _NewTripLocationViewState createState() => _NewTripLocationViewState();
}

class _NewTripLocationViewState extends State<NewTripLocationView> {
  TextEditingController _searchController = new TextEditingController();
  Timer _throttle;
  int _calls = 0;
  var uuid = new Uuid();
  String _sessionToken;

  final TextEditingController _controller = new TextEditingController();

  List<Address> results = [];

  bool isLoading = false;


  String _heading;
  List<Place> _placesList;
  final List<Place> _suggestedList = [
    Place("New York", 320.00),
    Place("Austin", 250.00),
    Place("Boston", 290.00),
    Place("Florence", 300.00),
    Place("Washington D.C.", 190.00),
  ];

  @override
  void initState() {
    super.initState();
    _heading = "Suggestions";
    _placesList = _suggestedList;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  _onSearchChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }

    if (_throttle?.isActive ?? false) _throttle.cancel();
    _throttle = Timer(const Duration(milliseconds: 2000), () {
      getLocationResults(_searchController.text);
    });
  }

  void getLocationResults(String input) async {
    if (input.isEmpty) {
      setState(() {
        _heading = "Suggestions";
      });
      return;
    }


    String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String type = '(regions)';
    // TODO Add session token

    String request = '$baseURL?input=$input&key=$PLACES_API_KEY&type=$type&sessiontoken=$_sessionToken';
    Response response = await Dio().get(request);
    print(response);

    final predictions = response.data['predictions'];
    print('The prediction is ');
    print(predictions);

    List<Place> _displayResults = [];

    for (var i = 0; i < predictions.length; i++) {
      String name = predictions[i]['description'];
      // TODO figure out the budget
      double averageBudget = 200.0;
      _displayResults.add(Place(name, averageBudget));
    }

    setState(() {
      _heading = "Results";
      _placesList = _displayResults;
      _calls++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom AutoSearch'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 10.0),
              child: new DividerWithText(
                dividerText: _heading,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _placesList.length,
                itemBuilder: (BuildContext context, int index) =>
                    buildPlaceCard(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlaceCard(BuildContext context, int index) {
    return Hero(
      tag: "SelectedTrip-${_placesList[index].name}",
      transitionOnUserGestures: true,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Card(
            child: InkWell(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: AutoSizeText(_placesList[index].name,
                                    maxLines: 3,
                                    style: TextStyle(fontSize: 15.0)),
                              ),
                            ],
                          ),
//                          Row(
//                            children: <Widget>[
//                              Text(
//                                  "Average Budget \$${_placesList[index].averageBudget.toStringAsFixed(2)}"),
//                            ],
//                          ),
                        ],
                      ),
                    ),
                  ),
//                  Column(
//                    children: <Widget>[
//                      Placeholder(
//                        fallbackHeight: 80,
//                        fallbackWidth: 80,
//                      ),
//                    ],
//                  )
                ],
              ),
              onTap: () {
                setState(() {
                  _sessionToken = null;
                });
                widget.trip.title = _placesList[index].name;
                String addressChosen = _placesList[index].name;
                search(addressChosen);
                print("Clicked: $addressChosen");
//                // TODO maybe pass the trip average budget through here too...
//                // that would need to be added to the Trip object
//                Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                      builder: (context) => NewTripDateView(trip: widget.trip)),
//                );
              },
            ),
          ),
        ),
      ),
    );
  }


//RaisedButton(
//child: Text("Continue"),
//onPressed: () {
//trip.title = _titleController.text;
//Navigator.push(
//context,
//MaterialPageRoute(builder: (context) => NewTripDateView(trip: trip)),
//);
//},
//),

  Future search(String addressChosen) async {
    this.setState(() {
      this.isLoading = true;
    });
    List<Address> results = [];
    try {
//      var geocoding = AppState
//          .of(context)
//          .mode;
      var results = await Geocoder.local.findAddressesFromQuery(
          search_query);

      print(results[0].coordinates);
      this.setState(() {
        this.results = results;

      });
    }
    catch (e) {
      print("Error occured: $e");
    }
    finally {
      this.setState(() {
        this.isLoading = false;
      });
    }
  }
}


