// MKMapView.j
// MapKit
//
// Created by Francisco Tolmasky.
// Copyright (c) 2010 280 North, Inc.
//
// Forked: Evadne Wu at Iridia, 2010
//
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










@import <AppKit/CPView.j>

@import "MKGeometry.j"
@import "MKTypes.j"

@class IRProtocol;










@implementation MKMapView : CPView {

	CLLocationCoordinate2D  m_centerCoordinate;
	CLLocationCoordinate2D  m_previousTrackingLocation;
	int m_zoomLevel;
	MKMapType m_mapType;
	BOOL m_scrollWheelZoomEnabled;

//	Google Maps DOM
	
	DOMElement m_DOMMapElement;
	DOMElement m_DOMGuardElement;
	Object m_map;
	Object m_map_overlay;


//	Delegation
	
	id _delegate @accessors(property=delegate);
	
	
//	Annotations

	CPArray _annotations;
	CPArray _visibleAnnotationViews;
	CPArray _dequeuedAnnotationViews;

}





+ (IRProtocol) irDelegateProtocol {

	return [IRProtocol protocolWithSelectorsAndOptionalFlags:

		@selector(mapViewDidFinishLoading:), false

	];

}




















+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLatitude {
	
	return [CPSet setWithObjects:@"centerCoordinate"];
	
}

+ (CPSet)keyPathsForValuesAffectingCenterCoordinateLongitude {
	
	return [CPSet setWithObjects:@"centerCoordinate"];

}

+ (id) _mapTypeObjectForMapType:(MKMapType)aMapType {

	if (google && google.maps && google.maps.MapTypeId)
	return [
	
		google.maps.MapTypeId.ROADMAP,
		google.maps.MapTypeId.HYBRID,
		google.maps.MapTypeId.SATELLITE,
		google.maps.MapTypeId.TERRAIN
		
	][aMapType];
	
	return null;
	
}










- (id) initWithFrame:(CGRect)aFrame {
	
	return [self initWithFrame:aFrame centerCoordinate:nil];
	
}





- (id) initWithFrame:(CGRect)aFrame centerCoordinate:(CLLocationCoordinate2D)aCoordinate {
	
	self = [super initWithFrame:aFrame]; if (!self) return nil;
	
	[self setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"MKMapViewBackdrop_lightGrid.png"]]]];
	
	[self setCenterCoordinate:aCoordinate || new CLLocationCoordinate2D(52, -1)];
	[self setZoomLevel:6];
	[self setMapType:MKMapTypeStandard];
	[self setScrollWheelZoomEnabled:YES];

	[self _buildDOM];

	return self;

}





- (void) _buildDOM {
	
	performWhenGoogleMapsScriptLoaded(function() {
		
		m_DOMMapElement = document.createElement("div");
		m_DOMMapElement.id = "MKMapView" + [self UID];
		
		var	style = m_DOMMapElement.style,
			bounds = [self bounds],
			width = CGRectGetWidth(bounds),
			height = CGRectGetHeight(bounds);
			
			style.overflow = "hidden";
			style.position = "absolute";
			style.visibility = "visible";
			style.zIndex = 0;
			style.left = -width + "px";
			style.top = -height + "px";
			style.width = width + "px";
			style.height = height + "px";
		
		
	//	Build the DOM	
	//	
	//	Google Maps can't figure out the size of the div if it's not in the DOM tree.
	//	We have to temporarily place it somewhere on the screen to appropriately size it.
	
		document.body.appendChild(m_DOMMapElement);
		
		m_map = new google.maps.Map(m_DOMMapElement, {
			
			mapTypeId: [[self class] _mapTypeObjectForMapType:m_mapType],
			backgroundColor: "transparent",
			mapTypeControl: false,
			navigationControl: false,
			scaleControl: false
	
		});
	
		m_map.setCenter(LatLngFromCLLocationCoordinate2D(m_centerCoordinate));
		m_map.setZoom(m_zoomLevel);
	
		m_map_overlay = new google.maps.OverlayView(); 
		m_map_overlay.setMap(m_map);
		m_map_overlay.draw = function () { 
		
			if (this.ready) return;
		
			this.ready = true; 
			google.maps.event.trigger(this, 'ready'); 
	
		}; 
		
		style.left = "0px";
		style.top = "0px";
			
			
		//	Remove element from DOM before appending it somewhere else
		//	or you will get WRONG_DOCUMENT_ERRs (4)
			
		document.body.removeChild(m_DOMMapElement);
		_DOMElement.appendChild(m_DOMMapElement);
		
		m_DOMGuardElement = document.createElement("div");

		var style = m_DOMGuardElement.style;

		style.overflow = "hidden";
		style.position = "absolute";
		style.visibility = "visible";
		style.zIndex = 0;
		style.left = "0px";
		style.top = "0px";
		style.width = "100%";
		style.height = "100%";

		_DOMElement.appendChild(m_DOMGuardElement);
		
		
	//	Wire up event handlers
		
		var updateCenterCoordinate = function () {
			
			var newCenterCoordinate = CLLocationCoordinate2DFromLatLng(m_map.getCenter());
			var centerCoordinate = [self centerCoordinate];

			if (CLLocationCoordinate2DEqualToCLLocationCoordinate2D(
				
				centerCoordinate, 
				newCenterCoordinate
				
			)) return;
			
			[self setCenterCoordinate:newCenterCoordinate];
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
			
		}
		
		google.maps.event.addListener(m_map, "center_changed", updateCenterCoordinate);
		google.maps.event.addListener(m_map, "moveend", updateCenterCoordinate);
		google.maps.event.addListener(m_map, "resize", updateCenterCoordinate);
		
		
		var updateZoomLevel = function() {

			var newZoomLevel = m_map.getZoom();
			var zoomLevel = [self zoomLevel];
			
			if (newZoomLevel == zoomLevel) return;
			
			[self setZoomLevel:newZoomLevel];
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
			
		}
		
		google.maps.event.addListener(m_map, "zoom_changed", updateZoomLevel);
		
		
		if ([[self delegate] respondsToSelector:@selector(mapViewDidFinishLoading:)])
		[[self delegate] mapViewDidFinishLoading:self];
		
	});

}










- (void) _ensureWholeEarth {

//	Ensure that the whole earth, at most, is visible in the viewport by ensuring that the “world” bounding box is at least of the same height of the viewport, and the width of the world is equal to, or wider than, the viewport.
	
	if (!CGRectContainsRect(
		
		[self bounds], 
		CGRectInset(worldBounds, 24, 24)
		
	)) return;
	
	var worldSquareEdgeLength = Math.min(worldBounds.size.height, worldBounds.size.width);
	
	//	Create rect using worldSquareEdgeLength, position it on the current center coordinate, then center it vertically.  After that, convert the rect to LatLngBounds and call method that translates to fitBounds().
	
}










- (void) setFrameSize:(CGSize)aSize {
	
	[super setFrameSize:aSize];

	if (!m_DOMMapElement) return;
	var bounds = [self bounds], style = m_DOMMapElement.style;
	
	style.width = CGRectGetWidth(bounds) + "px";
	style.height = CGRectGetHeight(bounds) + "px";
	
	google.maps.event.trigger(m_map, 'resize');

}

- (Object) namespace {
	
	return m_map;
	
}










//	Region
	
	- (MKCoordinateRegion) region {
	
		if (!m_map || !m_map.getBounds()) return nil;
		return MKCoordinateRegionFromLatLngBounds(m_map.getBounds());

	}

	- (void) setRegion:(MKCoordinateRegion)aRegion {

		m_region = aRegion; if (!m_map) return;
		[self setZoomLevel:m_map.getBoundsZoomLevel(LatLngBoundsFromMKCoordinateRegion(aRegion))];
		[self setCenterCoordinate:aRegion.center];
	
	}










//	Center Coordinate
	
	- (void) setCenterCoordinate:(CLLocationCoordinate2D)aCoordinate {

		if (m_centerCoordinate && CLLocationCoordinate2DEqualToCLLocationCoordinate2D(
			
			m_centerCoordinate, aCoordinate
				
		)) return;

		m_centerCoordinate = new CLLocationCoordinate2D(aCoordinate);

		if (!m_map)
		return;
		
		//	setCenter
		m_map.panTo(LatLngFromCLLocationCoordinate2D(aCoordinate));

		if ([[self delegate] respondsToSelector:@selector(mapView:regionDidChangeAnimated:)])
		[[self delegate] mapView:self regionDidChangeAnimated:NO];

	}
	
	
	- (CLLocationCoordinate2D) centerCoordinate {

		return new CLLocationCoordinate2D(m_centerCoordinate);

	}
	
	
	- (void) setCenterCoordinateLatitude:(float)aLatitude {

		[self setCenterCoordinate:new CLLocationCoordinate2D(aLatitude, [self centerCoordinateLongitude])];

	}
	
	
	- (float) centerCoordinateLatitude {

		return [self centerCoordinate].latitude;

	}
	
	
	- (void) setCenterCoordinateLongitude:(float)aLongitude {

		[self setCenterCoordinate:new CLLocationCoordinate2D([self centerCoordinateLatitude], aLongitude)];

	}
	
	
	- (float) centerCoordinateLongitude {

		return [self centerCoordinate].longitude;

	}










- (void) panByPointsX:(int)deltaX y:(int)deltaY {
	
	if (!m_map) return;
	m_map.panBy(deltaX, deltaY);
	
}








- (void) setZoomLevel:(float)aZoomLevel {

	m_zoomLevel = +aZoomLevel || 0;
	
//	if (m_zoomLevel >= 0) return;
	if (!m_map) return;
	m_map.setZoom(m_zoomLevel);

}

- (int) zoomLevel {
	
	return m_zoomLevel;

}





- (void) setMapType:(MKMapType)aMapType {

	m_mapType = aMapType;
	if (!m_map) return;
	
	m_map.setMapTypeId([[self class] _mapTypeObjectForMapType:m_mapType]);

}

- (MKMapType) mapType {
	
	return m_mapType;
	
}





- (void) setScrollWheelZoomEnabled:(BOOL)shouldBeEnabled {

	m_scrollWheelZoomEnabled = shouldBeEnabled;

	if (!m_map) return;
	m_map.setOptions({
		
		scrollwheel: m_scrollWheelZoomEnabled
	
	});

}

- (BOOL) scrollWheelZoomEnabled {

	return m_scrollWheelZoomEnabled;

}





- (void) takeStringAddressFrom:(id)aSender {

	var geocoder = new google.maps.Geocoder();

	geocoder.getLatLng([aSender stringValue], function(aLatLng) {

		if (!aLatLng) return;

		[self setCenterCoordinate:CLLocationCoordinate2DFromLatLng(aLatLng)];
		[self setZoomLevel:7];

		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

	});

}





- (Number) geographicalDistanceFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint basedOnMapView:(MKMapView)inView {
	
	return MKGeographicalDistanceBetweenCoordinates(
		
		[self convertPoint:fromPoint toCoordinateFromView:inView],
		[self convertPoint:toPoint toCoordinateFromView:inView]
		
	);
	
}










- (CGPoint) convertCoordinate:(CLLocationCoordinate2D)aCoordinate toPointToView:(CPView)aView {

	if (!m_map) return CGPointMakeZero();

	var pointInSelf = m_map_overlay.getProjection().fromLatLngToContainerPixel(
		
		LatLngFromCLLocationCoordinate2D(aCoordinate)
		
	);

	return [self convertPoint:CGPointMake(pointInSelf.x, pointInSelf.y) toView:aView];

}

- (CLLocationCoordinate2D) convertPoint:(CGPoint)aPoint toCoordinateFromView:(CPView)aView {

	if (!m_map) return new CLLocationCoordinate2D();

	var pointInSelf = [self convertPoint:aPoint fromView:aView];
	
	var latlng = m_map_overlay.getProjection().fromContainerPixelToLatLng(
		
		new google.maps.Point(pointInSelf.x, pointInSelf.y)
		
	);

	return CLLocationCoordinate2DFromLatLng(latlng);

}





- (void) mouseDown:(CPEvent)anEvent {

	if ([anEvent clickCount] === 2) {

		CPLog(@"FIXME: zoom");

		return;
		
	}

	[self trackPan:anEvent];
	[super mouseDown:anEvent];
	
}





- (void) trackPan:(CPEvent)anEvent {
	
	CPLog(@"trackPan called");

	var	type = [anEvent type],
		currentLocation = [self convertPoint:[anEvent locationInWindow] fromView:nil];
		
	if (!m_previousTrackingLocation)
	m_previousTrackingLocation = currentLocation;

	if (type === CPLeftMouseUp) {
	
	//	Do nothing

	} else {

		if (type === CPLeftMouseDown) {

		//	Do nothing.
		
		} else if (type === CPLeftMouseDragged) {

			var	centerCoordinate = [self centerCoordinate],
				lastCoordinate = [self convertPoint:m_previousTrackingLocation toCoordinateFromView:self],
				currentCoordinate = [self convertPoint:currentLocation toCoordinateFromView:self],
				
				delta = new CLLocationCoordinate2D(
					currentCoordinate.latitude - lastCoordinate.latitude,
					currentCoordinate.longitude - lastCoordinate.longitude
					
				);

			centerCoordinate.latitude -= delta.latitude;
			centerCoordinate.longitude -= delta.longitude;

			[self setCenterCoordinate:centerCoordinate];

		}

			[CPApp setTarget:self selector:@selector(trackPan:) forNextEventMatchingMask:CPLeftMouseDraggedMask | CPLeftMouseUpMask untilDate:nil inMode:nil dequeue:YES];
		
	}

	m_previousTrackingLocation = currentLocation;

}





- (void) _refreshAnnotationViews {
	
	//	Remove the old ones
	
}


- (void) _removeOrDequeueAnnotationViewIfAppropriate:(CPView)annotationView {
	
	
	
}


- (void) addAnnotation:(id)anAnnotation {
	
	
}


- (void) addAnnotations:(CPArray)annotations {
	
	
	
}


- (void) removeAnnotation:(id)anAnnotation {
	
	
	
}


- (void) removeAnnotations:(CPArray)annotations {
	
	
	
}


- (MKAnnotationView) viewForAnnotation:(id)annotation {
	
	
	
}


- (MKAnnotationView) dequeueReusableAnnotationViewWithIdentifier:(CPString)identifier {
	
	
}





- (void)resizeWithOldSuperviewSize:(CGSize)inSize {
	
	[super resizeWithOldSuperviewSize:inSize];
	
	CPLog(@"resizeWithOldSuperviewSize called on map view");
	
	try {
	
		google.maps.event.trigger(m_map, 'resize');
	
	} catch (e) {}
	
}

@end





//	Google Interfacing

	var GoogleMapsScriptQueue = [];

	var performWhenGoogleMapsScriptLoaded = function(/*Function*/ aFunction) {

		GoogleMapsScriptQueue.push(aFunction);

	//	Swizzle self out
		performWhenGoogleMapsScriptLoaded = function() { GoogleMapsScriptQueue.push(aFunction); }

	//	If Google Maps is loaded, there is no need to load the script again
		if (window.google && google.maps) return _MKMapViewMapsLoaded();

	//	Otherwise, pull the script down from Google and wait
		var DOMScriptElement = document.createElement("script");
		DOMScriptElement.src = "http://www.google.com/jsapi?callback=_MKMapViewGoogleAjaxLoaderLoaded";
		DOMScriptElement.type = "text/javascript";

		document.getElementsByTagName("head")[0].appendChild(DOMScriptElement);

	}

	function _MKMapViewGoogleAjaxLoaderLoaded () {
	
		google.load("maps", "3.2", {
	
			"callback": _MKMapViewMapsLoaded,
			"other_params": "sensor=false"
		
		});

		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

	}

	function _MKMapViewMapsLoaded () {

	//	Swizzle off delayed performing
	
		performWhenGoogleMapsScriptLoaded = function(aFunction) { aFunction(); }
		
		var index = 0, count = GoogleMapsScriptQueue.length;
		for (; index < count; ++index) GoogleMapsScriptQueue[index]();

		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
	
	}
	
	
	
	
	
//	CPCoding
	
	var	MKMapViewCenterCoordinateKey = @"MKMapViewCenterCoordinateKey",
		MKMapViewZoomLevelKey = @"MKMapViewZoomLevelKey",
		MKMapViewMapTypeKey = @"MKMapViewMapTypeKey";

	@implementation MKMapView (CPCoding)

	- (id) initWithCoder:(CPCoder)aCoder {

		self = [super initWithCoder:aCoder];

		if (!self) return nil;

		[self setCenterCoordinate:CLLocationCoordinate2DFromString(
			
			[aCoder decodeObjectForKey:MKMapViewCenterCoordinateKey]
		
		)];
		
		[self setZoomLevel:[aCoder decodeObjectForKey:MKMapViewZoomLevelKey]];
		[self setMapType:[aCoder decodeObjectForKey:MKMapViewMapTypeKey]];

		[self _buildDOM];

		return self;

	}

	- (void) encodeWithCoder:(CPCoder)aCoder {

		[super encodeWithCoder:aCoder];

		[aCoder encodeObject:CPStringFromCLLocationCoordinate2D(
			
			[self centerCoordinate]
			
		) forKey:MKMapViewCenterCoordinateKey];
		
		[aCoder encodeObject:[self zoomLevel] forKey:MKMapViewZoomLevelKey];
		[aCoder encodeObject:[self mapType] forKey:MKMapViewMapTypeKey];

	}

	@end




