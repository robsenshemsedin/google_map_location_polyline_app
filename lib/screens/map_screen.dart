import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentLocation;
  static const LatLng _pMuhajir = LatLng(9.075312794311415, 38.65561812315306);
  static const _pAgertusHome = LatLng(9.072249385458555, 38.657407485157194);
  static const CameraPosition _kGooglePlex =
      CameraPosition(target: _pAgertusHome, zoom: 22);
  Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();
  @override
  void initState() {
    super.initState();
    printPosition();
    leastenToPositionChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) {
                mapController.complete(controller);
              },
              initialCameraPosition: _kGooglePlex,
              markers: {
                const Marker(
                    markerId: MarkerId('googlePosition'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _pMuhajir),
                const Marker(
                    markerId: MarkerId('lakePosition'),
                    position: _pAgertusHome),
                Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: _currentLocation!)
              },
            ),
    );
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
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
        // returned true. According to Android guidelines
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

  void leastenToPositionChange() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position? position) async {
      if (position != null) {
        await changeCameraPosition(
            LatLng(position.latitude, position.longitude));
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  void printPosition() async {
    final position = await _determinePosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> changeCameraPosition(LatLng position) async {
    final GoogleMapController controller = await mapController.future;
    final newCameraPosition = CameraPosition(
      target: position,
      zoom: 22,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }
}
