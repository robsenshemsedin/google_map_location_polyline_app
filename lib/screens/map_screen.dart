import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:google_map_location_polyline_app/const.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// A screen that displays a map with the current and destination locations.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  static const LatLng _destinationLocation =
      LatLng(9.075312794311415, 38.65561812315306);

  late CameraPosition _initialCameraPosition;
  Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _setCurrentLocationAndInitialCameraPosition();
    _leastenToPositonChange();
  }

  Set<Polyline> polyLines = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                mapController.complete(controller);
              },
              initialCameraPosition: _initialCameraPosition,
              markers: {
                const Marker(
                    markerId: MarkerId('destinationLocation'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _destinationLocation),
                Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: _currentLocation!)
              },
              polylines: polyLines,
            ),
    );
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied, the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true). According to Android guidelines,
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  /// Listens to the position change and updates the map accordingly.
  void _leastenToPositonChange() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) async {
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        await _updateCameraPosition(newLocation);
        setState(() {
          _currentLocation = newLocation;
        });
        //     _getPolyLineCordinates();
      }
    });
  }

  /// Sets the current location and initial camera position based on the device's position.
  void _setCurrentLocationAndInitialCameraPosition() async {
    final position = await _determinePosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition = CameraPosition(
        target: _currentLocation!,
        zoom: 17,
      );
    });
  }

  /// Updates the camera position on the map.
  Future<void> _updateCameraPosition(LatLng position) async {
    final GoogleMapController controller = await mapController.future;
    final newCameraPosition = CameraPosition(
      target: position,
      zoom: 17,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  /// Retrieves and draws the polyline between the current and destination locations.
  void _getPolyLineCordinates() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
            googleMapApi,
            PointLatLng(
                _currentLocation!.latitude, _currentLocation!.longitude),
            PointLatLng(
                _destinationLocation.latitude, _destinationLocation.longitude));
    final List<LatLng> cordinates = [];
    for (PointLatLng point in polylineResult.points) {
      cordinates.add(LatLng(point.latitude, point.longitude));
    }
    setState(() {
      polyLines = {
        Polyline(polylineId: const PolylineId('polylineId'), points: cordinates)
      };
    });
  }
}
