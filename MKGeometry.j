// MKGeometry.j
// MapKit
//
// Created by Francisco Tolmasky.
// Copyright (c) 2010 280 North, Inc.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

function MKCoordinateSpan(/*CLLocationDegrees*/ aLatitudeDelta, /*CLLocationDegrees*/ aLongitudeDelta)
{
    this.latitudeDelta = aLatitudeDelta;
    this.longitudeDelta = aLongitudeDelta;

    return this;
}

MKCoordinateSpan.prototype.toString = function()
{
    return "{" + this.latitudeDelta + ", " + this.longitudeDelta + "}";
}

function MKCoordinateSpanMake(/*CLLocationDegrees*/ aLatitudeDelta, /*CLLocationDegrees*/ aLongitudeDelta)
{
    return new MKCoordinateSpan(aLatitudeDelta, aLongitudeDelta);
}

function MKCoordinateSpanFromLatLng(/*LatLng*/ aLatLng)
{
    return new MKCoordinateSpan(aLatLng.lat(), aLatLng.lng());
}

function CLLocationCoordinate2D(/*CLLocationDegrees*/ aLatitude, /*CLLocationDegrees*/ aLongitude)
{
    if (arguments.length === 1)
    {
        var coordinate = arguments[0];

        this.latitude = coordinate.latitude;
        this.longitude = coordinate.longitude;
    }
    else
    {
        this.latitude = +aLatitude || 0;
        this.longitude = +aLongitude || 0;
    }

    return this;
}

function CPStringFromCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ aCoordinate)
{
    return "{" + aCoordinate.latitude + ", " + aCoordinate.longitude + "}";
}

function CLLocationCoordinate2DFromString(/*String*/ aString)
{
    var comma = aString.indexOf(',');

    return new CLLocationCoordinate2D(
        parseFloat(aString.substr(1, comma - 1)), 
        parseFloat(aString.substring(comma + 1, aString.length)));
}

CLLocationCoordinate2D.prototype.toString = function()
{
    return CPStringFromCLLocationCoordinate2D(this);
}

function CLLocationCoordinate2DEqualToCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ lhs, /*CLLocationCoordinate2D*/ rhs)
{
    return lhs === rhs || lhs.latitude === rhs.latitude && lhs.longitude === rhs.longitude;
}

function CLLocationCoordinate2DMake(/*CLLocationDegrees*/ aLatitude, /*CLLocationDegrees*/ aLongitude)
{
    return new CLLocationCoordinate2D(aLatitude, aLongitude);
}

function CLLocationCoordinate2DFromLatLng(/*LatLng*/ aLatLng)
{
    return new CLLocationCoordinate2D(aLatLng.lat(), aLatLng.lng());
}

function LatLngFromCLLocationCoordinate2D(/*CLLocationCoordinate2D*/ aLocation)
{
    return new google.maps.LatLng(aLocation.latitude, aLocation.longitude);
}

function MKCoordinateRegion(/*CLLocationCoordinate2D*/ aCenter, /*MKCoordinateSpan*/ aSpan)
{
    this.center = aCenter;
    this.span = aSpan;

    return this;
}

MKCoordinateRegion.prototype.toString = function()
{
    return "{" + 
            this.center.latitude + ", " + 
            this.center.longitude + ", " + 
            this.span.latitudeDelta + ", " + 
            this.span.longitudeDelta + "}";
}

function MKCoordinateRegionMake(/*CLLocationCoordinate2D*/ aCenter, /*MKCoordinateSpan*/ aSpan)
{
    return new MKCoordinateRegion(aCenter, aSpan);
}

function MKCoordinateRegionFromLatLngBounds(/*LatLngBounds*/ bounds)
{
    return new MKCoordinateRegion(
        CLLocationCoordinate2DFromLatLng(bounds.getCenter()), 
        MKCoordinateSpanFromLatLng(bounds.toSpan()));
}

function LatLngBoundsFromMKCoordinateRegion(/*MKCoordinateRegion*/ aRegion)
{
    var latitude = aRegion.center.latitude,
        longitude = aRegion.center.longitude,
        latitudeDelta = aRegion.span.latitudeDelta,
        longitudeDelta = aRegion.span.longitudeDelta,
        LatLng = google.maps.LatLng,
        LatLngBounds = google.maps.LatLngBounds;

    return new LatLngBounds(
        new LatLng(latitude - latitudeDelta / 2, longitude - longitudeDelta / 2), // SW
        new LatLng(latitude + latitudeDelta / 2, longitude + longitudeDelta / 2) // NE
        );
}










if (Number.prototype.toRad === undefined)
Number.prototype.toRad = /* (Number) */ function  () { return this * Math.PI / 180; }

function MKGeographicalDistanceBetweenCoordinates (fromCoords, toCoords) {
	
	if (CLLocationCoordinate2DEqualToCLLocationCoordinate2D(fromCoords, toCoords))
	return 0;
	
	//	Vincenty Inverse Solution.
	//	Google Maps API v3 does not provide distance calculation, so we have to roll our own.
	//	Original: Chris Veness http://www.movable-type.co.uk/scripts/latlong-vincenty.html

	//	Formatting.  Sanitization.
	var	fromLatitude = fromCoords.latitude, fromLongitude = fromCoords.longitude,
		toLatitude = toCoords.latitude, toLongitude = toCoords.longitude;
	var	fromLatitudeRadians = Number(fromLatitude).toRad(), fromLongitudeRadians = Number(fromLongitude).toRad(),
		toLatitudeRadians = Number(toLatitude).toRad(), toLongitudeRadians = Number(toLongitude).toRad();

	//	Ellipsoid Parameters. Using WGS 1984 Data.
	var 	ellipsoidEquatorialAxis = 6378137,
		ellipsoidPolarAxis = 6356752.314245,
		ellipsoidInverseFlattening = 1/298.257223563;		
	var	ellipsoidEquatorialAxisSq = Math.pow(ellipsoidEquatorialAxis, 2),
		ellipsoidPolarAxisSq = Math.pow(ellipsoidPolarAxis, 2);

	//	Difference in Longitude
	var	longitudeDifferenceInRadians = toLongitudeRadians - fromLongitudeRadians;

	//	Reduced Latitude
	var	U1 = Math.atan( (1 - ellipsoidInverseFlattening) * Math.tan(fromLatitudeRadians) ),
		U2 = Math.atan( (1 - ellipsoidInverseFlattening) * Math.tan(toLatitudeRadians) );
		
	var	sinU1 = Math.sin(U1), cosU1 = Math.cos(U1), sinU2 = Math.sin(U2), cosU2 = Math.cos(U2);
	var	lambda = longitudeDifferenceInRadians, lambdaP = null, iterationLimit = 100;
	
	
	do {
		
	//	Iterate till lambdaP reached accuracy of 10^-12, approximately 0.06mm

		var sinLambda = Math.sin(lambda), cosLambda = Math.cos(lambda);
		var sinSigma = Math.sqrt(
			
			Math.pow( cosU2 * sinLambda , 2 ) + 
			Math.pow( cosU1 * sinU2 - sinU1 * cosU2 * cosLambda , 2 )

		);
						
		if (sinSigma == 0) return 0;
	//	Distance between co-incident points is zero

		var cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
		var sigma = Math.atan2( sinSigma, cosSigma );
		var sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
		var cosSqAlpha = 1 - Math.pow(sinAlpha, 2);
		var cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;

	//	Equatorial line: cosSqAlpha = 0 (§6)
		if ( isNaN(cos2SigmaM) ) cos2SigmaM = 0;

		var C = ( ellipsoidInverseFlattening / 16 ) * cosSqAlpha * 
			( 4 + ellipsoidInverseFlattening * ( 4 - 3 * cosSqAlpha ) );
		
		lambdaP = lambda;
		
		lambda = longitudeDifferenceInRadians + ( 1 - C ) * ellipsoidInverseFlattening * sinAlpha * 
			( sigma + C * sinSigma * ( cos2SigmaM + C * cosSigma * ( -1 + 2 * cos2SigmaM * cos2SigmaM ) ) );
				
	} while ( (Math.abs(lambda - lambdaP) > (1e-12)) && ( --iterationLimit > 0 ));
	
	
//	If formula failed to converge, return NaN
	if (iterationLimit == 0) return NaN;

	var uSq = cosSqAlpha * ( ellipsoidEquatorialAxisSq - ellipsoidPolarAxisSq ) / ellipsoidPolarAxisSq;

	var A = 1 + uSq / 16384 * ( 4096 + uSq * ( -768 + uSq * ( 320 - 175 * uSq ) ) );
	var B = uSq / 1024 * ( 256 + uSq *( -128 + uSq * ( 74 - 47 * uSq ) ) );

	var deltaSigma = B * sinSigma * ( cos2SigmaM + B / 4 * ( 

		cosSigma * ( -1 + 2 * Math.pow(cos2SigmaM, 2) ) -
		B / 6 * cos2SigmaM * ( -3 + 4 * Math.pow(sinSigma, 2) ) * ( -3 + 4 * Math.pow(cos2SigmaM, 2) )

	) );

	var distanceInMeters = ellipsoidPolarAxis * A * ( sigma - deltaSigma );  
	
//	Round to 1mm precision
	return distanceInMeters.toFixed(3); 

}





function MKRegionContainsCLLocationCoordinate2D (inRegion, inCoordinate) {

//	TODO: Test MKMapView (Cocoa Touch) conformity, and see if we need to use >= instead of >
	
	if (ABS(inCoordinate.longitude - inRegion.center.longitude) > inRegion.span.longitudeDelta) return NO;
	
	if (ABS(inCoordinate.latitude - inRegion.center.latitude) > inRegion.span.latitudeDelta) return NO;
	
	return YES;
	
}









