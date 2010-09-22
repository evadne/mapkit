//	MKAnnotation.j
//	Evadne Wu at Iridia, 2010





//	We only reserve 1 << 0 to 1 << 7

var	kMKAnnotationTypeOrdinary = 1 << 1,
	kMKAnnotationTypeCoalesced = 1 << 2;
	
var	kMKAnnotationRepresentedAnnotationsKey = @"MKAnnotationRepresentedAnnotations";








@implementation MKAnnotation : CPObject {

	CPString title @accessors;
	CPString subtitle @accessors;
	
	CLLocationCoordinate2D _coordinate;
//	MKAnnotationView annotationView;
	
	MKMapView mapView @accessors;
	
	BOOL _representsCoalescedAnnotations;
	CPArray _representedAnnotations;
	CPArray _representedAnnotationTypes; 
	
	int annotationType;
	id contextInfo;
	
}





- (MKAnnotation) initWithCoordinate:(CLLocationCoordinate2D)coords title:(CPString)title subtitle:(CPString)subtitle contextInfo:(id) contextInfo {
	
	self = [[[super class] alloc] init]; if (self == nil) return nil;
	
	[self setTitle:title];
	[self setSubtitle:subtitle];
	
	[self setCoordinate:coords];
	[self setContextInfo:contextInfo];
	
	return self;
	
}





- (MKAnnotation) initWithCoalescedAnnotations:(CPArray)annotations forMapView:(MKMapView)mapView {
	
	var annotationsToEnqueue = [CPMutableDictionary dictionary];

//	Iterate thru arguments, fill annotationsToEnqueue
	
//	Grab annotations here	
	
	self = [self initWithCoordinate:NULL title:nil subtitle:nil contextInfo:[CPDictionary dictionaryWithObject:annotationsToEneueue forKey:kMKAnnotationRepresentedAnnotationsKey]];
	
	[self setMapView:mapView];
	
	if (self == nil) return nil;
	
		//	For each annotation get its location in map.  balance by point, and return coords.
		//	Calculate!
	
	return self;
	
}





- (BOOL) representsCoalescedAnnotations {
	
	return _representsCoalescedAnnotations;
	
}





//	Here





@end




